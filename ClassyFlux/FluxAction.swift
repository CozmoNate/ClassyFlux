//
//  FluxAction.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 31/07/2019.
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

import Foundation

// MARK: - FluxAction

/// A protocol describing an abstract action
public protocol FluxAction {}

public extension FluxAction {
    
    /// Dispatches the action with the dispatcher on specified queue.
    /// Action will be dispatched synchronously when called from the same queue and dispatcher isn't dispatching previous action.
    /// Otherwise will dispatch the action asynchronously to run on specified queue inside barrier block.
    func dispatch(with dispatcher: FluxDispatching = FluxDispatcher.default, queue: DispatchQueue = .main) {
        if DispatchQueue.isRunning(on: queue) && !dispatcher.isDispatching {
            dispatcher.dispatch(action: self)
        } else {
            queue.async(flags: .barrier) {
                dispatcher.dispatch(action: self)
            }
        }
    }
}

// MARK: - FluxActionEmitter

/// A protocol that defines how the concrete action can be emitted.
public protocol FluxActionEmitter: AnyObject {

    /// Emits the action.
    func emit<Action: FluxAction>(action: Action)
}

// MARK: - FluxPassthroughAction

/// A struct that stores the functor that can pass concrete action to FluxActionEmitter or stop action propagation.
public struct FluxPassthroughAction {

    // MARK: Static
    
    /// Passes the action to subsequent workers.
    public static func next<T: FluxAction>(_ action: T) -> FluxPassthroughAction {
        return FluxPassthroughAction { $0.emit(action: action) }
    }

    /// Stops any action propagation.
    public static func stop() -> FluxPassthroughAction {
        return FluxPassthroughAction()
    }
    
    // MARK: Instance
    
    private var emit: ((FluxActionEmitter) -> Void)?

    /// Passes the results to the emitter.
    public func pass(to emitter: FluxActionEmitter) {
        emit?(emitter)
    }
}

// MARK: - Utility

internal let FluxQueueIdentifierKey = DispatchSpecificKey<UUID>()

internal extension DispatchQueue {
    
    static func isRunning(on queue: DispatchQueue) -> Bool {
        var identifier: UUID! = queue.getSpecific(key: FluxQueueIdentifierKey)
        if identifier == nil {
            identifier = UUID()
            queue.setSpecific(key: FluxQueueIdentifierKey, value: identifier)
        }
        return DispatchQueue.getSpecific(key: FluxQueueIdentifierKey) == identifier
    }
    
}
