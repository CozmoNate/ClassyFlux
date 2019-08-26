//
//  FluxStoreBrokerTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 25/08/2019.
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

class FluxStoreEndwareTests: QuickSpec {
    override func spec() {

        var store: TestStore!
        var endware: TestStore.Endware!
        var value: String!
        
        describe("FluxStore.Endware") {

            beforeEach {
                store = TestStore()
                endware = TestStore.Endware()
            }

            context("when registered action handler") {

                beforeEach {

                    value = nil
                    
                    endware.registerHandler { (state, action: ChangeValueAction) in
                        value = action.value
                    }
                }

                it("has registered ChangeValueAction handler") {
                    expect(try? endware.handlers.resolve(TestStore.Endware.Handle<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when registered endware to the store") {

                    beforeEach {
                        store.append(endwares: [endware])
                    }

                    it("is added to the store's endware list") {
                        expect(store.tokens).to(contain(endware.token))
                        expect(store.endwares.contains(where: { $0 === endware})).to(beTrue())
                    }

                    context("when the store performed registered action") {

                        beforeEach {
                            store.handle(action: ChangeValueAction(value: "change it!"), composer: TestComposer())
                        }

                        it("correctly calls the action handler") {
                            expect(value).to(equal("change it!"))
                        }
                    }

                    context("when the store performed unregistered action") {

                        beforeEach {
                            store.handle(action: IncrementNumberAction(increment: 1), composer: TestComposer())
                        }

                        it("does not change the value") {
                            expect(value).to(beNil())
                        }
                    }

                    context("when unregistered endware from the store") {

                        beforeEach {
                            store.unregister(tokens: [endware.token])
                        }

                        it("is removed the endware from the endware list") {
                            expect(store.tokens).to(beEmpty())
                            expect(store.endwares).to(beEmpty())
                        }
                    }

                    context("when unregistered ChangeValueAction handler") {

                        var flag: Bool!

                        beforeEach {
                            flag = endware.unregisterHandler(for: ChangeValueAction.self)
                        }

                        it("successfully unregistered the action handler") {
                            expect(flag).to(beTrue())
                            expect(try? endware.handlers.resolve(TestStore.Endware.Handle<ChangeValueAction>.self)).to(beNil())
                        }

                        context("when the store performed registered action") {

                            beforeEach {
                                store.handle(action: ChangeValueAction(value: "change it!"), composer: TestComposer())
                            }

                            it("does not change the value") {
                                expect(value).to(beNil())
                            }
                        }

                    }

                    context("when registered another endware to the store") {

                        beforeEach {
                            let another = TestStore.Endware()
                            store.append(endwares: [another])
                        }

                        it("is added to the store's endware list") {
                            expect(store.tokens).to(contain(endware.token))
                            expect(store.endwares.contains(where: { $0 === endware})).to(beTrue())
                        }

                        context("when the store performed registered action") {

                            beforeEach {
                                store.handle(action: ChangeValueAction(value: "change it!"), composer: TestComposer())
                            }

                            it("correctly calls the action handler") {
                                expect(value).to(equal("change it!"))
                            }
                        }
                    }
                }
            }

        }

    }

}
