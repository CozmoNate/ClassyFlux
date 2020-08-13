//
//  FluxAggregator.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 01/10/2019.
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
import ResolvingContainer

/// An object that aggregates multiple states from different stores and invokes appropriate handlers when the store changes.
public class FluxAggregator {

    /// State changes handler
    /// - Parameter state: Actual state value
    public typealias Handler<State> = (_ state: State) -> Void

    internal let storage: ResolvingContainer
    internal var subscriptions: [(observer: AnyObject, worker: FluxWorker)]
    internal var changeHandler: ((FluxAggregator) -> Void)?

    /// Initializes an aggregator instance with optional block what called each time when one of registered stores changed.
    public init(changeHandler collectHandler: ((FluxAggregator) -> Void)? = nil) {
        storage = ResolvingContainer()
        subscriptions = []
        changeHandler = collectHandler
    }

    /// Returns the state value or nil if the state of the specified type is not available.
    public subscript<State>(_ type: State.Type) -> State {
        guard let store = storage.resolve(FluxStore<State>.self) else {
            fatalError("Trying to access to the unknown state type: \(String(describing: State.self))")
        }
        return store.state
    }
    
    /// Registers a store and starts to aggregate that store state changes.
    /// - Parameter store: The store to register. Store will be registered under its token, and can be unregistered later by providing its token.
    /// - Parameter observingKeyPaths: The list of KeyPath describing the fields in particular state object which should trigger state change handlers.
    /// - Parameter queue: The queue where the handler will be called on.
    /// - Parameter handler: The closure that will be invoked when the state is changed.
    public func register<State>(store: FluxStore<State>, observing observingKeyPaths: Set<PartialKeyPath<State>> = Set(), queue: OperationQueue = .main, handler: @escaping Handler<State>) {
        storage.register(instance: store as FluxStore<State>)
        let observer = store.addObserver(for: .stateDidChange, observing: observingKeyPaths, queue: queue) { [weak self] state in
            guard let self = self else { return }
            handler(state)
            self.changeHandler?(self)
        }
        subscriptions.append((observer: observer, worker: store))
    }

    /// Unregisters store, remove aggregated state and handlers associated with specified state type.
    /// - Parameter store: The store to unregister
    public func unregister<State>(store: FluxStore<State>) {
        storage.unregister(FluxStore<State>.self)
        subscriptions = subscriptions.filter { $0.worker.token != store.token }
    }
 
    /// Unregisters all observers, remove aggregated state values and stop receiving state changed events
    public func unregisterAll() {
        storage.unregisterAll()
        subscriptions.removeAll()
    }
}
