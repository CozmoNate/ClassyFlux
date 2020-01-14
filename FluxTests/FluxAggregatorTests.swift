
//
//  FluxAggregatorTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 01/10/2019.
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

class FluxAggregatorTests: QuickSpec {
    override func spec() {

        var store: TestStore!
        var aggregator: FluxAggregator!

        describe("FluxAggregator") {

            beforeEach {
                store = TestStore()
                aggregator = FluxAggregator()
            }
            
            context("when registered the store") {
             
                beforeEach {
                    aggregator.register(store: store, observing: [\TestState.value])
                }
                
                it("adds store observer") {
                    expect(aggregator.observers[store.token]).notTo(beNil())
                }
                
                it("stores store state") {
                    expect(aggregator[TestState.self]).to(equal(TestState(value: "initial", number: 0)))
                }
                
                context("when registered state handler") {
                    
                    var changedState: TestState?
                    
                    beforeEach {
                        aggregator.registerHandler(for: TestState.self) { (state) in
                            changedState = state
                        }
                    }
                    
                    it("adds the handler into resolver container") {
                        expect(try? aggregator.storage.resolve(FluxAggregator.Handle<TestState>.self)).notTo(beNil())
                    }
                    
                    context("when store chages") {
                        
                        beforeEach {
                            _ = store.handle(action: ChangeValueAction(value: "aggregate"))
                        }
                        
                        it("invokes change handler on aggregator") {
                            expect(changedState).to(equal(TestState(value: "aggregate", number: 0)))
                        }
                        
                        it("passes changed state to aggregator") {
                            expect(aggregator[TestState.self]).to(equal(TestState(value: "aggregate", number: 0)))
                        }
                    }
                    
                    context("when unregistered the handler") {

                        beforeEach {
                            aggregator.unregisterHandler(for: TestState.self)
                        }
                    
                        it("removes the handler from resolver container") {
                            expect(try? aggregator.storage.resolve(FluxAggregator.Handle<TestState>.self)).to(beNil())
                        }
                    }
                }
                
                context("when unregistered the state") {
                    
                    beforeEach {
                        aggregator.unregister(state: TestState.self)
                    }
                    
                    it("removes store observer") {
                        expect(aggregator.observers[store.token]).to(beNil())
                        expect(try? aggregator.storage.resolve(TestState.self)).to(beNil())
                    }
                }

                context("when unregistered all") {

                    beforeEach {
                        aggregator.unregisterAll()
                    }

                    it("removes store observer") {
                        expect(aggregator.observers).to(beEmpty())
                        expect(try? aggregator.storage.resolve(TestState.self)).to(beNil())
                    }
                }
            }
        }
    }
}
