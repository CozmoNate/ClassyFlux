//
//  FluxRepositorySubscriptionTest.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 19/08/2020.
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2020 Natan Zalkin
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

class FluxRepositorySubscriptionTests: QuickSpec {

    override func spec() {

        describe("FluxRepository.Subscription") {
            
            var repository: MockRepository!
            var subscriptions: [MockRepository.Subscription]!
            var lastValue: String?
            var lastKeyPaths: Set<PartialKeyPath<MockRepository>>?
            
            beforeEach {
                repository = MockRepository()

                repository.registerMutator(for: ChangeValueAction.self) { (state, action) in
                    state.value = action.value
                    return [\MockRepository.value]
                }
                
                subscriptions = []

                repository.addObserver { (state, keyPaths) in
                    lastKeyPaths = keyPaths
                }.store(in: &subscriptions)
                
                repository.addObserver(observing: [\MockRepository.value]) { (state) in
                    lastValue = state.value
                }.store(in: &subscriptions)
            }
            
            context("when state changed") {

                beforeEach {
                    _ = repository.handle(action: ChangeValueAction(value: "test"))
                }

                it("receives changed state") {
                    expect(lastKeyPaths).toEventually(equal(Set([\MockRepository.value])))
                    expect(lastValue).toEventually(equal("test"))
                }

                context("when deallocated") {
                    beforeEach {
                        subscriptions.removeAll()
                        lastValue = "stub"
                        lastKeyPaths = []
                    }

                    context("when state changed") {

                        beforeEach {
                            _ = repository.handle(action: ChangeValueAction(value: "test 2"))
                        }

                        it("does not receives changed state") {
                            expect(lastKeyPaths).toNotEventually(equal(Set([\MockRepository.value])))
                            expect(lastValue).toNotEventually(equal("test 2"))
                        }
                    }
                }
            }
        }
    }
}
