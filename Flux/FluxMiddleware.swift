//
//  FluxMiddleware.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 03/08/2019.
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

/// An object that can be registered in FluxDispatcher and perform the work in a response to FluxAction send
open class FluxMiddleware {

    /// An action handler closue
    /// - Parameter action: The action to handle
    /// - Parameter completion: The closure that should be called upon completion
    public typealias Handle<Action: FluxAction> = (_ action: Action, _ composer: () -> FluxComposer) -> Void

    /// A unique identifier of the middleware
    public let token: UUID

    let handlers: ResolverContainer

    public init() {
        token = UUID()
        handlers = ResolverContainer()
    }

    /// Associates a handler with the actions of specified type
    /// - Parameter action: The type of the actions to associate with handler
    /// - Parameter execute: The closure that will be invoked when the action received
    public func registerHandler<Action: FluxAction>(for action: Action.Type = Action.self, work execute: @escaping Handle<Action>) {
        handlers.register { execute }
    }

    /// Unregisters handler associated with specified action type. Returns true if handler unregistered successfully. Returns false when no handler was registered for the action type.
    /// - Parameter action: The action for which the associated handler should be removed
    public func unregisterHandler<Action: FluxAction>(for action: Action.Type) -> Bool {

        typealias Handler = Handle<Action>

        return handlers.unregister(Handler.self)
    }

}

extension FluxMiddleware: FluxWorker {

    public func handle<Action: FluxAction>(action: Action, composer: () -> FluxComposer) {

        typealias Handler = Handle<Action>

        guard let handle = try? self.handlers.resolve(Handler.self) else {
            composer().next(action: action)
            return
        }

        handle(action, composer)
    }

}
