//
//  FluxStore.swift
//  Flux
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
import Combine
import Resolver

open class FluxStore<State: FluxState>: ObservableObject {

    // MARK: - Types

    public typealias State = State
    public typealias Reduce<Action: FluxAction> = (inout State, Action) -> Void

    // MARK: - Public

    public let token: UUID

    @Published public private(set) var state: State

    // MARK: - Private

    let reducers: ResolverContainer

    // MARK: - Methods

    public init(initialState: State, registration: ((_ store: FluxStore<State>) -> Void)? = nil) {

        token = UUID()
        state = initialState
        reducers = ResolverContainer()

        defer {
            registration?(self)
        }
    }

    public func registerReducer<Action: FluxAction>(for action: Action.Type = Action.self, reducer: @escaping Reduce<Action>) {
        reducers.register { reducer }
    }

}

extension FluxStore: FluxWorker {

    public func handle<Action: FluxAction>(action: Action, completion: @escaping () -> Void) {

        typealias Reducer = Reduce<Action>

        guard let reduce = try? reducers.resolve(Reducer.self) else {
            completion()
            return
        }

        var draftState = state

        reduce(&draftState, action)

        DispatchQueue.main.async {
            self.state = draftState
            completion()
        }
    }

}
