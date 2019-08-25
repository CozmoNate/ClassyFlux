//
//  FluxStoreObserverTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 23/08/2019.
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

import Quick
import Nimble

@testable import ClassyFlux

class FluxStoreObserverTests: QuickSpec, FluxComposer {

    var observer: FluxStoreObserver?

    override func spec() {

        describe("FluxStoreObserver") {

            var store: FluxStore<TestState>!
            var lastState: TestState?

            beforeEach {
                store = FluxStore(initialState: TestState(value: "initial", number: 0))

                store.registerReducer { (state, action: ChangeValueAction) in
                    state.value = action.value
                    return true
                }

                self.observer = FluxStoreObserver(store: store) { (state) in
                    lastState = state
                }
            }

            context("when state changed") {

                beforeEach {
                    store.handle(action: ChangeValueAction(value: "test"), composer: self)
                }

                it("receives changed state") {
                    expect(lastState?.value).toEventually(equal(store.state.value))

                }

                context("when deallocated") {
                    beforeEach {
                        self.observer = nil
                        store.handle(action: ChangeValueAction(value: "test 2"), composer: self)
                    }

                    context("when state changed") {

                        it("does not receives changed state") {
                            expect(lastState?.value).toNotEventually(equal(store.state.value))
                        }
                    }
                }
            }
        }
    }

    func next<Action>(action: Action) where Action : FluxAction {
    }
}
