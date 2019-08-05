//
//  FluxStoreTests.swift
//  FluxTests
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble

@testable import Flux

class FluxStoreTests: QuickSpec {

    override func spec() {

        describe("FluxStore") {

            var store: FluxStore<TestSate>!

            beforeEach {
                store = FluxStore<TestSate>(initialState: TestSate(value: "initial", number: 0)) {
                    $0.registerReducer { (state, action: ChangeValueAction) in
                        state.value = action.value
                    }
                }
            }

            it("has correct initial value") {
                expect(store.state.value).to(equal("initial"))
                expect(store.state.number).to(equal(0))
            }

            it("has registered initial ChangeValueAction reducer") {
                expect(try? store.reducers.resolve(FluxStore<TestSate>.Reduce<ChangeValueAction>.self)).toNot(beNil())
            }

            context("when performed unknown action") {

                var didFinish: Bool = false

                beforeEach {
                    store.handle(action: UnknownAction()) {
                        didFinish = true
                    }
                }

                it("doesn't change store's state") {
                    expect(store.state.value).toEventually(equal("initial"))
                    expect(store.state.number).toEventually(equal(0))
                }

                it("finishes operation") {
                    expect(didFinish).toEventually(beTrue())
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
