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
import ResolverContainer

/// A class that aggregates states from multiple stores and invokes appropriate handlers when the store changes.
public class FluxAggregator {

    /// State changes handler
    /// - Parameter state: Actual state value
    public typealias Handle<State> = (_ state: State) -> Void
    
    internal let storage: ResolverContainer
    internal var observers: [UUID: AnyObject]
    internal var changeHandler: ((FluxAggregator) -> Void)?

    /// Initializes an aggregator instance with optional block what called each time when one of registered store changed.
    public init(changeHandler collectHandler: ((FluxAggregator) -> Void)? = nil) {
        storage = ResolverContainer()
        observers = [UUID: AnyObject]()
        changeHandler = collectHandler
    }

    /// Returns the state value or nil if the state of the specified type is not available.
    public subscript<State>(_ type: State.Type) -> State {
        guard let store = try? storage.resolve(FluxStore<State>.self) else {
            fatalError("Requested unregistered state type: \(String(describing: State.self))")
        }
            
        return store.state
    }
    
    /// Registers a store and starts to aggregate that store state changes.
    /// - Parameter store: The store to register. Store will be registered under its token, and can be unregistered later by providing its token.
    /// - Parameter observingKeyPaths: The list of KeyPath describing the fields in particular state object which should trigger state change handlers.
    public func register<State>(store: FluxStore<State>, observing observingKeyPaths: Set<PartialKeyPath<State>> = Set(), queue: OperationQueue = .main) {
        
        storage.register(instance: store as FluxStore<State>)

        observers[store.token] = store.addObserver(for: .stateDidChange, queue: queue) { [unowned self] state, changedKeyPaths in
            guard observingKeyPaths.isEmpty || !observingKeyPaths.isDisjoint(with: changedKeyPaths) else {
                return
            }

            if let handler = try? self.storage.resolve(Handle<State>.self) {
                handler(state)
            }
            
            self.changeHandler?(self)
        }
    }

    /// Associates change handler with the state of specified type.
    /// - Parameter state: The type of a state object to associate with handler.
    /// - Parameter execute: The closure that will be invoked when the state is changed.
    public func registerHandler<State>(for state: State.Type = State.self, handler: @escaping Handle<State>) {
        storage.register { handler }
    }

    /// Unregisters handler associated with specified state type.
    public func unregisterHandler<State>(for state: State.Type) {
        storage.unregister(Handle<State>.self)
    }

    /// Unregisters store and handler associated with specified state type.
    /// - Parameter state: The type of a state object.
    public func unregister<State>(state: State.Type) {
        if let store = storage.unregister(FluxStore<State>.self) {
            observers.removeValue(forKey: store.token)
        }
        unregisterHandler(for: state)
    }
 
    /// Unregisters all observers and stop receiving state changed events
    public func unregisterAll() {
        storage.unregisterAll()
        observers.removeAll()
    }
    
}
