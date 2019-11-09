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

            context("when registered action handlers") {

                beforeEach {
                    middleware.registerComposer(for: ChangeValueAction.self) { (_, action) in
                        value = action.value
                        return FluxNextAction(action)
                    }

                    middleware.registerHandler(for: IncrementNumberAction.self) { (owner, action) in
                        owner.didIncrement = true
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

                context("when performed another action") {

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

                    beforeEach {
                        middleware.unregisterHandler(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the action handler") {
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

            context("when registered basic handler") {

                var didCallHandler: Bool?

                beforeEach {
                    middleware.registerComposer(for: ChangeValueAction.self) { _ in
                        return FluxNextAction(ChangeValueAction(value: "Transformed!"))
                    }

                    middleware.registerHandler(for: IncrementNumberAction.self) { _ in
                        didCallHandler = true
                    }
                }

                it("has registered action handler") {
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<ChangeValueAction>.self)).toNot(beNil())
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when performed first action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        middleware.handle(action: ChangeValueAction(value: "change it!"))(composer)
                    }

                    it("passes correct action to composer") {
                        expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "Transformed!")))
                    }
                }

                context("when performed second action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        middleware.handle(action: IncrementNumberAction(increment: 1))(composer)
                    }

                    it("calls action handler") {
                        expect(didCallHandler).to(beTruthy())
                    }

                    it("passes the same action to composer") {
                        expect(composer.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 1)))
                    }
                }
            }
        }
    }
}
