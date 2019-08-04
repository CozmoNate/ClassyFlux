//
//  FluxMiddlewareTests.swift
//  Flux
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import Flux

class FluxMiddlewareTests: QuickSpec {

    override func spec() {

        describe("FluxMiddleware") {

            var middleware: FluxMiddleware!
            var value: String!

            beforeEach {

                value = "initial"

                middleware = FluxMiddleware {
                    $0.register { (action: ChangeValueAction, completion) in
                        value = action.value
                        completion()
                    }
                }
            }

            it("has registered ChangeValueAction performer") {
                expect(try? middleware.performers.resolve(FluxMiddleware.Perform<ChangeValueAction>.self)).toNot(beNil())
            }

            context("when performed ChangeValueAction") {

                var didFinish: Bool = false

                beforeEach {
                    middleware.perform(action: ChangeValueAction(value: "test")) {
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
