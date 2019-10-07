//
//  FluxMiddlewareTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import ClassyFlux

class FluxMiddlewareTests: QuickSpec {

    override func spec() {

        describe("FluxMiddleware") {

            var middleware: TestMiddleware!
            var value: String!

            beforeEach {
                value = "initial"
                middleware = TestMiddleware()
            }

            context("when registered action handler") {

                beforeEach {
                    middleware.registerHandler(for: ChangeValueAction.self) { (action) in
                        value = action.value
                        return FluxNextAction(action)
                    }

                    middleware.registerHandler(for: IncrementNumberAction.self) { (self, action) in
                        self.didIncrement = true
                        return FluxNextAction(action)
                    }
                }

                it("has registered action handlers") {
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<ChangeValueAction>.self)).toNot(beNil())
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when performed registered action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        middleware.handle(action: ChangeValueAction(value: "change it!"))(composer)
                    }

                    it("calls action handler") {
                        expect(value).to(equal("change it!"))
                    }

                    it("passes action to composer") {
                        expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "change it!")))
                    }
                }

                context("when performed action associated with self-accessible handler") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        middleware.handle(action: IncrementNumberAction(increment: 1))(composer)
                    }

                    it("calls action handler") {
                        expect(middleware.didIncrement).to(beTruthy())
                    }

                    it("passes action to composer") {
                        expect(composer.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 1)))
                    }
                }

                context("when unregistered the action") {

                    var flag: Bool!

                    beforeEach {
                        flag = middleware.unregisterHandler(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the action handler") {
                        expect(flag).to(beTrue())
                        expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        var composer: TestComposer!

                        beforeEach {
                            composer = TestComposer()
                            middleware.handle(action: ChangeValueAction(value: "change it!"))(composer)
                        }

                        it("does not change the value") {
                            expect(value).to(equal("initial"))
                        }

                        it("passes action to composer") {
                            expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "change it!")))
                        }
                    }

                }
            }

        }
    }
}
