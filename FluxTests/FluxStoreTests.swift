//
//  FluxStoreTests.swift
//  FluxTests
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import ClassyFlux

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class FluxStoreTests: QuickSpec {

    override func spec() {

        describe("FluxStore") {

            var store: FluxStore<TestSate>!

            beforeEach {
                store = FluxStore<TestSate>(initialState: TestSate(value: "initial", number: 0))
            }

            context("when registered an action") {

                beforeEach {
                    store.registerReducer { (state, action: ChangeValueAction) in
                        state.value = action.value
                        return true
                    }
                }

                it("has correct initial value") {
                    expect(store.state.value).to(equal("initial"))
                    expect(store.state.number).to(equal(0))
                }

                it("has registered initial ChangeValueAction reducer") {
                    expect(try? store.reducers.resolve(FluxStore<TestSate>.Reduce<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    var flag: Bool!

                    beforeEach {
                        flag = store.unregisterRedcer(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the reducer") {
                        expect(flag).to(beTrue())
                        expect(try? store.reducers.resolve(FluxStore<TestSate>.Reduce<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        it("doesn't change store's state") {
                            waitUntil { (done) in
                                store.handle(action: ChangeValueAction(value: "change it!")) {
                                    expect(store.state.value).to(equal("initial"))
                                    expect(store.state.number).to(equal(0))
                                    done()
                                }
                            }
                        }

                    }

                }

                context("when performed well known action") {

                    var didFinish: Bool = false

                    beforeEach {
                        store.handle(action: ChangeValueAction(value: "test")) {
                            didFinish = true
                        }
                    }

                    it("correctly reduces store's state") {
                        expect(store.state.value).toEventually(equal("test"))
                    }

                    it("finishes operation") {
                        expect(didFinish).toEventually(beTrue())
                    }
                }

                context("can add another reducer") {

                    beforeEach {
                        store.registerReducer { (state, action: IncrementNumberAction) in
                            state.number += action.increment
                            return true
                        }
                    }

                    it("has registered IncrementNumberAction reducer") {
                        expect(try? store.reducers.resolve(FluxStore<TestSate>.Reduce<IncrementNumberAction>.self)).toNot(beNil())
                    }

                    context("when performed another action") {

                        var didFinish: Bool = false

                        beforeEach {
                            store.handle(action: IncrementNumberAction(increment: 2)) {
                                didFinish = true
                            }
                        }

                        it("correctly reduces store's state") {
                            expect(store.state.number).toEventually(equal(2))
                        }

                        it("finishes operation") {
                            expect(didFinish).toEventually(beTrue())
                        }
                    }

                }
            }
        }
    }
}
