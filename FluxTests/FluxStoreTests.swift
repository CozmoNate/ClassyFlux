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
                    $0.register { (action: ChangeValueAction, state) in
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

            context("when performed ChangeValueAction") {

                var didFinish: Bool = false

                beforeEach {
                    store.perform(action: ChangeValueAction(value: "test")) {
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
                    store.register { (action: IncrementNumberAction, state) in
                        state.number += action.increment
                    }
                }

                it("has registered IncrementNumberAction reducer") {
                    expect(try? store.reducers.resolve(FluxStore<TestSate>.Reduce<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when performed IncrementNumberAction") {

                    var didFinish: Bool = false

                    beforeEach {
                        store.perform(action: IncrementNumberAction(increment: 2)) {
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
