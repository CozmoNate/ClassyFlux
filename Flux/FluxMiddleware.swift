//
//  FluxMiddleware.swift
//  Flux
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


open class FluxMiddleware {

    public typealias Handle<Action: FluxAction> = (_ action: Action, _ completion: @escaping () -> Void) -> Void

    public let token: UUID

    let handlers: ResolverContainer

    public init(registration: ((_ middleware: FluxMiddleware) -> Void)? = nil) {
        
        token = UUID()
        handlers = ResolverContainer()

        defer {
            registration?(self)
        }
    }

    public func registerHandler<Action: FluxAction>(for action: Action.Type = Action.self, work execute: @escaping Handle<Action>) {
        handlers.register { execute }
    }

}

extension FluxMiddleware: FluxWorker {

    public func handle<Action: FluxAction>(action: Action, completion: @escaping () -> Void) {

        typealias Handler = Handle<Action>

        guard let perform = try? self.handlers.resolve(Handler.self) else {
            completion()
            return
        }

        perform(action, completion)
    }

}
