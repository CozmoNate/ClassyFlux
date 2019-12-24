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

class FluxStoreObserverTests: QuickSpec {

    var observer: TestStore.Observer?
    var anotherObserver: TestStore.Observer?
    
    override func spec() {

        describe("FluxStore.Observer") {

            var store: FluxStore<TestState>!
            var lastState: TestState?
            var lastKeyPaths: Set<PartialKeyPath<TestState>>?
            var lastValue: String?
            
            beforeEach {
                store = FluxStore(initialState: TestState(value: "initial", number: 0))

                store.registerReducer { (state, action: ChangeValueAction) in
                    state.value = action.value
                    return [\TestState.value]
                }

                self.observer = store.addObserver(for: .stateDidChange) { (state, keyPaths) in
                    lastState = state
                    lastKeyPaths = keyPaths
                }
                
                self.anotherObserver = store.addObserver(for: .stateDidChange, observing: [\TestState.value]) { (state) in
                    lastValue = state.value
                }
            }
            
            context("when state changed") {

                beforeEach {
                    store.handle(action: ChangeValueAction(value: "test"))(TestIterator())
                }

                it("receives changed state") {
                    expect(lastState?.value).toEventually(equal("test"))
                    expect(lastKeyPaths).toEventually(equal(Set([\TestState.value])))
                    expect(lastValue).toEventually(equal("test"))
                }

                context("when deallocated") {
                    beforeEach {
                        self.observer = nil
                        self.anotherObserver = nil
                    }

                    context("when state changed") {

                        beforeEach {
                            lastState = TestState(value: "one", number: 1)
                            lastKeyPaths = [\TestState.number]
                            lastValue = "ups"
                            store.handle(action: ChangeValueAction(value: "test 2"))(TestIterator())
                            
                        }

                        it("does not receives changed state") {
                            expect(lastState?.value).toNotEventually(equal("test 2"))
                            expect(lastKeyPaths).toNotEventually(equal(Set([\TestState.value])))
                            expect(lastValue).toNotEventually(equal("test 2"))
                        }
                    }
                }
            }
        }
    }
}
