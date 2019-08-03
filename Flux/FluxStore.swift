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

open class FluxStore<State: FluxState>: ObservableObject {

    // MARK: - Types

    public typealias State = State

    // MARK: - Public

    @Published public private(set) var state: State

    // MARK: - Private

    private let worker: FluxDispatcher.Worker
    private var dispatcher: FluxDispatcher?

    // MARK: - Methods

    public init(initialState: State, register reducers: ((_ reducers: Reducers<State>) -> Void)? = nil) {
        state = initialState
        worker = FluxDispatcher.Worker()

        defer {
            if let reducers = reducers {
                register(reducers: reducers)
            }
        }
    }

    public func register(reducers: (_ reducers: Reducers<State>) -> Void)  {
        reducers(Reducers(store: self, worker: worker))
    }

    public func register(to dispatcher: FluxDispatcher) {
        self.dispatcher = dispatcher
        self.dispatcher?.register(worker: worker)
    }

    public func dispatch<Action: FluxAction>(action: Action) {
        dispatcher?.dispatch(action: action)
    }

}

extension FluxStore {

    public class Reducers<State: FluxState> {

        private let worker: FluxDispatcher.Worker
        private let store: FluxStore<State>

        internal init(store: FluxStore<State>, worker: FluxDispatcher.Worker) {
            self.worker = worker
            self.store = store
        }

        public func register<Action: FluxAction>(reducer reduce: @escaping (Action, State) -> State) {

            let performer: FluxDispatcher.Worker.Perform<Action> = { [weak store] action, completion in

                guard let store = store else {
                    completion()
                    return
                }

                let state = reduce(action, store.state)

                DispatchQueue.main.async {
                    store.state = state
                    completion()
                }
            }

            worker.register(work: performer)
        }

    }

}
