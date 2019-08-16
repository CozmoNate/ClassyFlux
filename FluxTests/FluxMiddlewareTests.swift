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

        describe("FluxMiddleware") {

            var middleware: FluxMiddleware!
            var value: String!

            beforeEach {

                value = "initial"

                middleware = FluxMiddleware()


            }

            context("when registered action handler") {

                beforeEach {
                    middleware.registerHandler { (action: ChangeValueAction, completion) in
                        value = action.value
                        completion()
                    }
                }

                it("has registered ChangeValueAction performer") {
                    expect(try? middleware.handlers.resolve(FluxMiddleware.Handle<ChangeValueAction>.self)).toNot(beNil())
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

                        var didFinish: Bool = false

                        beforeEach {
                            middleware.handle(action: ChangeValueAction(value: "change it!")) {
                                didFinish = true
                            }
                        }

                        it("does not change the value") {
                            expect(value).to(equal("initial"))
                        }

                        it("finishes operation") {
                            expect(didFinish).to(beTrue())
                        }
                    }

                }

                context("when performed registered action") {

                    var didFinish: Bool = false

                    beforeEach {
                        middleware.handle(action: ChangeValueAction(value: "test")) {
                            didFinish = true
                        }
                    }

                    it("correctly reduces store's state") {
                        expect(value).to(equal("test"))
                    }

                    it("finishes operation") {
                        expect(didFinish).to(beTrue())
                    }
                }
            }

        }
    }
}
