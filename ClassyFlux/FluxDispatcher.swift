//
//  FluxDispatcher.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 19/08/2019.
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
#if canImport(Combine)
import Combine
#endif

// MARK: - FluxDispatching

/// A protocol that defines how the action can be dispatched
public protocol FluxDispatching {

    /// A flag indicating if dispatcher dispatches an action at the moment.
    var isDispatching: Bool { get }

    /// Passes the action to workers.
    /// - Parameter action: The action to pass.
    func dispatch<Action: FluxAction>(action: Action)

}

// MARK: - FluxDispatcher

/// An object that dispatches actions to registered workers synchronously on the same thread.
open class FluxDispatcher: FluxDispatching {

    /// The default dispatcher instance
    public static let `default` = FluxDispatcher()

    #if canImport(Combine)
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var willDispatchAction = PassthroughSubject<FluxAction, Never>()

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var didDispatchAction = PassthroughSubject<FluxAction, Never>()
    #endif

    /// A list of all registered workers.
    public private(set) var workers: [FluxWorker]
    
    /// A flag indicating if dispatcher dispatches an action to workers at the moment.
    public var isDispatching: Bool { !pipeline.isEmpty }

    internal var tokens: Set<AnyHashable>
    internal var pipeline: Pipeline
    
    /// Initialises a dispatcher.
    public init() {
        tokens = Set()
        pipeline = Pipeline()
        workers = []
    }

    public func register(workers workersToInsert: [FluxWorker]) {
        workersToInsert.forEach { worker in
            if tokens.insert(worker.token).inserted {
                let sortedIndex = workers.sortedIndex(of: worker)
                workers.insert(worker, at: sortedIndex)
            }
        }
    }

    public func unregister(tokens tokensToRemove: [AnyHashable]) {
        tokens.subtract(Set(tokensToRemove))
        workers.removeAll { tokensToRemove.contains($0.token) }
    }

    public func dispatch<Action: FluxAction>(action: Action) {
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            willDispatchAction.send(action)
        }
        #endif
        
        pipeline
            .load(workers: workers)
            .emit(action: action)
        
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            didDispatchAction.send(action)
        }
        #endif
    }    
}

// MARK: - FluxDispatcher.Pipeline

extension FluxDispatcher {
    
    public class Pipeline: FluxActionEmitter {
        
        public var isEmpty: Bool { iterator == nil }
        
        private var iterator: IndexingIterator<[FluxWorker]>?
        
        public func load(workers: [FluxWorker]) -> Self {
            iterator = workers.makeIterator()
            return self
        }

        public func emit<Action: FluxAction>(action: Action) {
            if let worker = iterator?.next() {
                worker.handle(action: action).pass(to: self)
            } else {
                iterator = nil
            }
        }
    }
}

// MARK: - Utility

public extension RandomAccessCollection where Element == FluxWorker {

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
