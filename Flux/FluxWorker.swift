//
//  FluxWorker.swift
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
import Resolver

open class FluxWorker {

    // MARK: - Types

    public typealias Perform<Action: FluxAction> = (_ action: Action, _ completion: @escaping () -> Void) -> Void

    // MARK: - Public

    public let token: UUID

    // MARK: - Private

    private let performers: ResolverContainer

    // MARK: - Methods

    public init() {
        token = UUID()
        performers = ResolverContainer()
    }

    public func register<Action: FluxAction>(action: Action.Type = Action.self, work perform: @escaping Perform<Action>) {
        performers.register { perform }
    }

    public func unregister<Action: FluxAction>(action: Action.Type) {
        performers.unregister(Perform<Action>.self)
    }

    func perform<Action: FluxAction>(action: Action, completion: @escaping () -> Void) {
        guard let perform: Perform<Action> = try? self.performers.resolve() else {
            completion()
            return
        }

        perform(action, completion)
    }
}
