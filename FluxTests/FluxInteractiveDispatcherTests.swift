//
//  FluxInteractiveDispatcherTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 17/12/2019.
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

class FluxInteractiveDispatcherTests: QuickSpec {

    override func spec() {
        describe("FluxDispatcher.Interactive") {

            var dispatcher: FluxDispatcher.Interactive!

            beforeEach {
                dispatcher = FluxDispatcher.Interactive()
            }

            context("when registered worker") {

                var worker: TestWorker!

                beforeEach {
                    worker = TestWorker(priority: 0)
                    dispatcher.register(workers: [worker])
                }

                it("registers the worker and its token") {
                    expect(dispatcher.tokens.contains(worker.token)).to(beTrue())
                    expect(dispatcher.workers.first).to(beIdenticalTo(worker))
                }

                context("when unregisters worker by token") {

                    beforeEach {
                        dispatcher.unregister(tokens: [worker.token])
                    }

                    it("unregisters the worker and its token") {
                        expect(dispatcher.tokens.contains(worker.token)).to(beFalse())
                        expect(dispatcher.workers).to(beEmpty())
                    }
                }

                context("when tried to register worker with the same token") {

                    beforeEach {
                        dispatcher.register(workers: [worker])
                    }

                    it("does not registers new worker and token") {
                        expect(dispatcher.tokens.count).to(equal(1))
                        expect(dispatcher.workers.count).to(equal(1))
                    }
                }

                context("when dispatched action") {

                    beforeEach {
                        dispatcher.dispatch(action: ChangeValueAction(value: "test"))
                    }

                    it("perform action with worker registered") {
                        expect(worker.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                    }
                }

                context("when registered additional workers") {

                    var first: FluxMiddleware!
                    var second: TestWorker!
                    var third: FluxStore<TestState>!
                    var fouth: FluxStore<TestState>!

                    context("when workers have different priorities") {
                        beforeEach {
                            first = FluxMiddleware(priority: 2)
                            second = TestWorker(priority: 3)
                            third = TestStore(priority: 1)
                            fouth = FluxStore(priority: 0, initialState: TestState(value: "1", number: 1))
                            
                            dispatcher.register(workers: [first, second, third, fouth])
                        }
                        
                        it("registers the worker and its token") {
                            expect(dispatcher.workers.count).to(equal(5))
                            expect(dispatcher.workers[0]).to(beIdenticalTo(worker))
                            expect(dispatcher.workers[1]).to(beIdenticalTo(fouth))
                            expect(dispatcher.workers[2]).to(beIdenticalTo(third))
                            expect(dispatcher.workers[3]).to(beIdenticalTo(first))
                            expect(dispatcher.workers[4]).to(beIdenticalTo(second))
                        }
                        
                        context("when dispatched action") {
                            
                            beforeEach {
                                ChangeValueAction(value: "test").dispatch(with: dispatcher)
                            }
                            
                            it("passes the action to last worker") {
                                expect(second.lastAction as? ChangeValueAction).toEventually(equal(ChangeValueAction(value: "test")))
                            }
                        }
                    }
                    
                    context("when workers have the same priority") {
                        beforeEach {
                            first = FluxMiddleware(priority: 0)
                            second = TestWorker(priority: 0)
                            third = TestStore(priority: 0)
                            fouth = FluxStore(priority: 0, initialState: TestState(value: "1", number: 1))
                            
                            dispatcher.register(workers: [first, second, third, fouth])
                        }
                        
                        it("registers the worker and its token") {
                            expect(dispatcher.workers.count).to(equal(5))
                            expect(dispatcher.workers[0]).to(beIdenticalTo(worker))
                            expect(dispatcher.workers[1]).to(beIdenticalTo(first))
                            expect(dispatcher.workers[2]).to(beIdenticalTo(second))
                            expect(dispatcher.workers[3]).to(beIdenticalTo(third))
                            expect(dispatcher.workers[4]).to(beIdenticalTo(fouth))
                        }
                        
                        context("when dispatched action") {
                            
                            beforeEach {
                                ChangeValueAction(value: "test").dispatch(with: dispatcher)
                            }
                            
                            it("passes the action to last worker") {
                                expect(second.lastAction as? ChangeValueAction).toEventually(equal(ChangeValueAction(value: "test")))
                            }
                        }
                    }
                }
            }
        }
    }

}
