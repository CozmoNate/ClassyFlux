//
//  FluxEndware.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 25/08/2019.
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

/// An object that triggers handlers in a response to specific action dispatched.
/// Endware provides an easy access to associated store state.
open class FluxEndware<State>: FluxWorker {

    public typealias State = State

    /// An action handler closue. When the action returned it will be passed to next worker.
    /// - Parameter action: The action to handle
    /// - Parameter state: The current state of the linked store
    /// - Parameter composer: The object that passes the action to the next worker.
    ///     You can ignore the composer to stop further action propagation to other workers.
    ///     If you pass next action to the composer, this should be done synchronously in the same closure.
    /// - Returns: Return next action or nil to prevent the action to proppagate to other workers
    public typealias Handle<Action: FluxAction> = (_ action: Action, _ state: State) -> Void

    /// A unique identifier of the endware.
    public let token: UUID

    /// The store associated with the endware
    public let store: FluxStore<State>

    internal let handlers: ResolverContainer

    /// Initialise a broker representing the store provided.
    public init(store owner: FluxStore<State>) {
        token = UUID()
        store = owner
        handlers = ResolverContainer()
    }

    /// Associates a handler with the actions of specified type.
    /// - Parameter action: The type of the actions to associate with handler.
    /// - Parameter execute: The closure that will be invoked when the action received.
    public func registerHandler<Action: FluxAction>(for action: Action.Type = Action.self, work execute: @escaping Handle<Action>) {
        handlers.register { execute }
    }

    /// Unregisters handler associated with specified action type.
    /// - Parameter action: The action for which the associated handler should be removed
    /// - Returns:True if the handler is unregistered successfully. False when no handler was registered for the action type.
    public func unregisterHandler<Action: FluxAction>(for action: Action.Type) -> Bool {
        return handlers.unregister(Handle<Action>.self)
    }

    public func handle<Action: FluxAction>(action: Action) -> FluxPassthroughAction {
        if let handle = try? self.handlers.resolve(Handle<Action>.self) {
            handle(action, store.state)
        }

        return FluxNextAction(action)
    }
}
