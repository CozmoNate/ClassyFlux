//
//  FluxMiddlewareTests.swift
//  Flux
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import ClassyFlux

class FluxMiddlewareTests: QuickSpec {

    override func spec() {

        typealias TestMiddleware = FluxMiddleware<TestState>

        describe("FluxMiddleware") {

            var middleware: TestMiddleware!
            var value: String!

            beforeEach {

                value = "initial"

                middleware = TestMiddleware()
            }

            context("when registered action handler") {

                beforeEach {
                    middleware.registerHandler { (action: ChangeValueAction, state) in
                        value = state.value + " " + action.value
                    }
                }

                it("has registered ChangeValueAction handler") {
                    expect(try? middleware.handlers.resolve(TestMiddleware.Handle<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    var flag: Bool!

                    beforeEach {
                        flag = middleware.unregisterHandler(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the action handler") {
                        expect(flag).to(beTrue())
                        expect(try? middleware.handlers.resolve(TestMiddleware.Handle<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        beforeEach {
                            middleware.handle(action: ChangeValueAction(value: "it!"), state: TestState(value: "Change", number: 0))
                        }

                        it("does not change the value") {
                            expect(value).to(equal("initial"))
                        }
                    }

                }

                context("when performed registered action") {

                    beforeEach {
                        middleware.handle(action: ChangeValueAction(value: "it!"), state: TestState(value: "Change", number: 0))
                    }

                    it("correctly reduces store's state") {
                        expect(value).to(equal("Change it!"))
                    }
                }
            }

        }
    }
}
