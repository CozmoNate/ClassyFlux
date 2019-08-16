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

                    worker = FluxMiddleware()

                    worker.registerHandler { (action: ChangeValueAction, done) in
                        value = action.value
                        done()
                    }

                    dispatcher.register(workers: [worker])
                }

                it("registers the worker and its token") {
                    dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                    expect(dispatcher.tokens.first).to(equal(worker.token))
                    expect(dispatcher.workers.first).to(beIdenticalTo(worker))
                }

                context("when unregisters worker by token") {

                    beforeEach {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        dispatcher.unregister(tokens: [dispatcher.tokens.first!])
                    }

                    it("unregisters the worker and its token") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(dispatcher.tokens).to(beEmpty())
                        expect(dispatcher.workers).to(beEmpty())
                    }
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
                        ChangeValueAction(value: "test").dispatch(with: dispatcher)
                    }

                    it("perform action on registered worker") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(value).to(equal("test"))
                    }
                }

                context("when dispatched block") {

                    var flag: Bool!

                    beforeEach {
                        flag = false
                        dispatcher.dispatch {
                            flag = true
                        }
                    }

                    it("perform action on registered worker") {
                        dispatcher.operationQueue.waitUntilAllOperationsAreFinished()
                        expect(flag).to(beTrue())
                    }
                }
            }
        }
    }

}
