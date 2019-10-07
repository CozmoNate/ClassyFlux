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

import ResolverContainer

/// A class that aggregates states from multiple stores and invokes appropriate handlers when store changed.
public class FluxAggregator {

    /// State changes handler
    /// - Parameter state: Actual state value
    public typealias Handle<State> = (_ state: State) -> Void
    
    internal let storage: ResolverContainer
    internal var observers: [UUID: AnyObject]
    internal let handlers: ResolverContainer

    public init() {
        storage = ResolverContainer()
        observers = [UUID: AnyObject]()
        handlers = ResolverContainer()
    }

    /// Returns the state value or nil if the state of specified type not aggregated.
    public subscript<State>(_ type: State.Type) -> State? {
        return try? storage.resolve(State.self)
    }
    
    /// Registers store and starts to aggregate that store state changes.
    /// - Parameter store: The store to register. Store will be registered under its token, and can be unregistered later by providing its token.
    /// - Parameter observedKeyPaths: The list of KeyPath describing the fields in particulat state object, which should trigger state change handlers.
    public func register<State>(store: FluxStore<State>, observing observedKeyPaths: Set<PartialKeyPath<State>> = Set(), queue: OperationQueue = .main) {
        storage.register(instance: store.state)

        observers[store.token] = store.addObserver(for: .stateDidChange, queue: queue) { [unowned self] state, changedKeyPaths in
            self.storage.register(instance: state)

            guard observedKeyPaths.isEmpty || !observedKeyPaths.isDisjoint(with: changedKeyPaths) else {
                return
            }

            guard let handler = try? self.handlers.resolve(Handle<State>.self) else {
                return
            }
            
            handler(state)
        }
    }
    
    /// Unregisters stores registerd under tokens provided
    /// - Parameter tokens: The list of store tokens.
    public func unregister(tokens: [UUID]) {
        tokens.forEach {
            observers.removeValue(forKey: $0)
        }
    }
    
    /// Unregisters all observers and stop receiving state changed events
    public func unregisterAll() {
        observers.removeAll()
    }
    
   /// Associates change handler with the state of specified type.
    /// - Parameter state: The type of a state object to associate with handler.
    /// - Parameter execute: The closure that will be invoked when the state is changed.
    public func registerHandler<State>(for state: State.Type = State.self, handler: @escaping Handle<State>) {
        handlers.register { handler }
    }

    /// Unregisters handler associated with specified state type.
    /// - Returns:True if the handler is unregistered successfully. False when no handler was registered for the action type.
    public func unregisterHandler<State>(for state: State.Type) -> Bool {
        return handlers.unregister(Handle<State>.self)
    }
    
}
