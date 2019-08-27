//
//  FluxEndwareTests.swift
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

class FluxEndwareTests: QuickSpec {
    override func spec() {

        var store: TestStore!
        var broker: FluxEndware<TestState>!
        var value: String!

        describe("FluxEndware") {

            beforeEach {
                store = TestStore()
                broker = FluxEndware(store: store)
            }

            context("when registered action handler") {

                beforeEach {
                    broker.registerHandler { (action: ChangeValueAction, state, composer) in
                        value = action.value
                        composer.next(action: action)
                    }
                }

                it("has registered ChangeValueAction handler") {
                    expect(try? broker.handlers.resolve(FluxEndware<TestState>.Handle<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    var flag: Bool!

                    beforeEach {
                        flag = broker.unregisterHandler(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the action handler") {
                        expect(flag).to(beTrue())
                        expect(try? broker.handlers.resolve(FluxEndware<TestState>.Handle<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        var composer: TestComposer!

                        beforeEach {
                            composer = TestComposer()
                            broker.handle(action: ChangeValueAction(value: "change it!"), composer: composer)
                        }

                        it("does not change the value") {
                            expect(value).to(beNil())
                        }

                        it("does not call to composer") {
                            expect(composer.lastAction).to(beNil())
                        }
                    }

                }

                context("when performed registered action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        broker.handle(action: ChangeValueAction(value: "change it!"), composer: composer)
                    }

                    it("correctly reduces store's state") {
                        expect(value).to(equal("change it!"))
                    }

                    it("passes action to composer") {
                        expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "change it!")))
                    }
                }
            }
        }
    }
}
