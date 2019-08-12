//
//  FluxDispatcherTests.swift
//  FluxTests
//
//  Created by Natan Zalkin on 02/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import ClassyFlux

class FluxDispatcherTests: QuickSpec {

    override func spec() {

        describe("FluxDispatcher") {

            var dispatcher: FluxDispatcher!

            beforeEach {
                dispatcher = FluxDispatcher()
            }

            context("when registered worker") {

                var worker: FluxMiddleware!
                var value: String!

                beforeEach {

                    value = "initial"

                    worker = FluxMiddleware {
                        $0.registerHandler { (action: ChangeValueAction, done) in
                            value = action.value
                            done()
                        }
                    }

                    dispatcher.register(workers: [worker])
                }

                it("registers worker and token") {
                    dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                    expect(dispatcher.tokens.first).to(equal(worker.token))
                    expect(dispatcher.workers.first).to(beIdenticalTo(worker))
                }

                context("when tried to register worker with the same token") {

                    beforeEach {
                        dispatcher.register(workers: [worker])
                    }

                    it("does not registers new worker and token") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(dispatcher.tokens.count).to(equal(1))
                        expect(dispatcher.workers.count).to(equal(1))
                    }
                }

                context("when dispatched action") {

                    beforeEach {
                        dispatcher.dispatch(action: ChangeValueAction(value: "test"))
                    }

                    it("perform action on registered worker") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(value).to(equal("test"))
                    }
                }
            }
        }
    }

}
