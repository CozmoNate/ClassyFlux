//
//  FluxDispatcher.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 17/12/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2019 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

/// An object that dispatches actions to registered workers.
/// Actions will be dispatched on the same thread there the dispatcher is called.
open class FluxDispatcher: FluxActionDispatching {

    internal var tokens: Set<UUID>
    internal var workers: [FluxWorker]

    /// Initialises a dispatcher.
    public init() {
        tokens = Set()
        workers = []
    }

    /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
    /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as they were registered.
    public func register(workers workersToInsert: [FluxWorker]) {
        workersToInsert.forEach { worker in
            if tokens.insert(worker.token).inserted {
                let sortedIndex = workers.sortedIndex(of: worker)
                workers.insert(worker, at: sortedIndex)
            }
        }
    }

    /// Unregisters workers from the dispatcher.
    /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered.
    public func unregister(tokens tokensToRemove: [UUID]) {
        tokens.subtract(Set(tokensToRemove))
        workers.removeAll { tokensToRemove.contains($0.token) }
    }

    /// Dispatches an action to workers.
    /// - Parameter action: The action to dispatch to workers.
    public func dispatch<Action: FluxAction>(action: Action) {
        FluxStackingComposer(workers: workers).next(action: action)
    }

}

// MARK: - Main Tthread Dispatcher

public extension FluxDispatcher {
    
    /// An object that dispatches actions to registered workers on main thread.
    class Interactive: FluxDispatcher {
        
        /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
        /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as they were registered.
        override public func register(workers workersToInsert: [FluxWorker]) {
            scheduleOnMain { super.register(workers: workersToInsert) }
        }
        
        /// Unregisters workers from the dispatcher.
        /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered.
        override public func unregister(tokens tokensToRemove: [UUID]) {
            scheduleOnMain { super.unregister(tokens: tokensToRemove) }
        }
        
        /// Dispatches an action to workers.
        /// - Parameter action: The action to dispatch to workers.
        override public func dispatch<Action: FluxAction>(action: Action) {
            scheduleOnMain { super.dispatch(action: action) }
        }
        
        func scheduleOnMain(execute action: @escaping () -> Void) {
            if Thread.isMainThread {
                action()
            } else {
                DispatchQueue.main.async(execute: action)
            }
        }
    }

}

// MARK: - Background Dispatcher

public extension FluxDispatcher {
    
    /// An object that dispatches actions to registered workers on background thread.
    class Background: FluxDispatcher {

        internal let queue: DispatchQueue

        /// Initialises a dispatcher.
        /// - Parameter queue: The queue that will run the actions. Actions will be dispatched and run serially regardless of type of the queue.
        public init(queue scheduler: DispatchQueue = DispatchQueue(label: "FluxDispatcher.Queue", qos: .default)) {
            queue = scheduler
            super.init()
        }

        /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
        /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as they were registered.
        override public func register(workers workersToRegister: [FluxWorker]) {
            queue.async(flags: .barrier) { super.register(workers: workersToRegister) }
        }

        /// Unregisters workers from the dispatcher.
        /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered.
        override public func unregister(tokens tokensToUnregister: [UUID]) {
            queue.async(flags: .barrier) { super.unregister(tokens: tokensToUnregister) }
        }

        /// Dispatches an action to workers.
        /// - Parameter action: The action to dispatch to workers.
        override public func dispatch<Action: FluxAction>(action: Action) {
            queue.async(flags: .barrier) { super.dispatch(action: action) }
        }
    }
    
}

// MARK: - Utility Methods

extension RandomAccessCollection where Element == FluxWorker {

    /// Index where the worker should be inserted to keep the collection sorted
    func sortedIndex(of target: Element) -> Index {

        var sequence = self[...]

        while !sequence.isEmpty {

            let middleIndex = sequence.index(sequence.startIndex, offsetBy: sequence.count / 2)

            if target.priority < sequence[middleIndex].priority {
                sequence = sequence[..<middleIndex]
            } else {
                sequence = sequence[sequence.index(after: middleIndex)...]
            }
        }

        return sequence.startIndex
    }

}
