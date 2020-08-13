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

            var middleware: MockMiddleware!
            var value: String!

            beforeEach {
                value = "initial"
                middleware = MockMiddleware()
            }

            context("when registered action handlers") {

                beforeEach {
                    middleware.registerComposer(for: ChangeValueAction.self) { (_, action) in
                        value = action.value
                        return .next(action)
                    }

                    middleware.registerHandler(for: IncrementNumberAction.self) { (owner, action) in
                        owner.didIncrement = true
                    }
                    
                    middleware.registerInterceptor(for: EmptyAction.self) { (owner, action) in
                        owner.didIntercept = true
                    }
                }

                it("has registered action handlers") {
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<ChangeValueAction>.self)).toNot(beNil())
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<IncrementNumberAction>.self)).toNot(beNil())
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<EmptyAction>.self)).toNot(beNil())
                }

                context("when performed registered action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        middleware.handle(action: ChangeValueAction(value: "change it!")).pass(to: emitter)
                    }

                    it("calls action handler") {
                        expect(value).to(equal("change it!"))
                    }

                    it("passes action to composer") {
                        expect(emitter.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "change it!")))
                    }
                }

                context("when performed another action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        middleware.handle(action: IncrementNumberAction(increment: 1)).pass(to: emitter)
                    }

                    it("calls action handler") {
                        expect(middleware.didIncrement).to(beTruthy())
                    }

                    it("passes action to composer") {
                        expect(emitter.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 1)))
                    }
                }
                
                context("when performed third action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        middleware.handle(action: EmptyAction()).pass(to: emitter)
                    }

                    it("calls action handler") {
                        expect(middleware.didIntercept).to(beTruthy())
                    }

                    it("does not pass the action to composer") {
                        expect(emitter.lastAction).to(beNil())
                    }
                }

                context("when unregistered the action") {

                    beforeEach {
                        middleware.unregisterHandler(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the action handler") {
                        expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        var emitter: MockEmitter!

                        beforeEach {
                            emitter = MockEmitter()
                            middleware.handle(action: ChangeValueAction(value: "change it!")).pass(to: emitter)
                        }

                        it("does not change the value") {
                            expect(value).to(equal("initial"))
                        }

                        it("passes action to composer") {
                            expect(emitter.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "change it!")))
                        }
                    }
                }
            }

            context("when registered basic handler") {

                var didCallHandler: Bool?

                beforeEach {
                    middleware.registerComposer(for: ChangeValueAction.self) { _ in
                        return .next(ChangeValueAction(value: "Transformed!"))
                    }

                    middleware.registerHandler(for: IncrementNumberAction.self) { _ in
                        didCallHandler = true
                    }
                }

                it("has registered action handler") {
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<ChangeValueAction>.self)).toNot(beNil())
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handler<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when performed first action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        middleware.handle(action: ChangeValueAction(value: "change it!")).pass(to: emitter)
                    }

                    it("passes correct action to composer") {
                        expect(emitter.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "Transformed!")))
                    }
                }

                context("when performed second action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        middleware.handle(action: IncrementNumberAction(increment: 1)).pass(to: emitter)
                    }

                    it("calls action handler") {
                        expect(didCallHandler).to(beTruthy())
                    }

                    it("passes the same action to composer") {
                        expect(emitter.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 1)))
                    }
                }
            }
        }
    }
}
