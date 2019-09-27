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

            var store: TestStore!

            beforeEach {
                store = TestStore()
            }

            context("when registered the action") {

                beforeEach {
                    store.registerReducer { (state, action: ChangeValueAction) in
                        state.value = action.value
                        return [\TestState.value]
                    }
                }

                it("has correct initial value") {
                    expect(store.state.value).to(equal("initial"))
                    expect(store.state.number).to(equal(0))
                }

                it("has registered initial ChangeValueAction reducer") {
                    expect(try? store.reducers.resolve(TestStore.Reduce<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    var flag: Bool!

                    beforeEach {
                        flag = store.unregisterReducer(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the reducer") {
                        expect(flag).to(beTrue())
                        expect(try? store.reducers.resolve(TestStore.Reduce<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        beforeEach {
                            store.handle(action: ChangeValueAction(value: "change it!"), composer: TestComposer())
                        }

                        it("doesn't change store's state") {
                            expect(store.state.value).to(equal("initial"))
                            expect(store.state.number).to(equal(0))
                        }
                    }

                }

                context("when performed well known action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        store.handle(action: ChangeValueAction(value: "test"), composer: composer)
                    }

                    it("calls state change events") {
                        expect(store.stateBeforeChange?.value).to(equal("initial"))
                        expect(store.stateAfterChange?.value).to(equal("test"))
                    }

                    it("correctly reduces store's state") {
                        expect(store.state.value).to(equal("test"))
                    }

                    it("passes action to composer") {
                        expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                    }
                }

                context("can add another reducer") {

                    beforeEach {
                        store.registerReducer { (state, action: IncrementNumberAction) in
                            state.number += action.increment
                            return [\TestState.number]
                        }
                    }

                    it("has registered IncrementNumberAction reducer") {
                        expect(try? store.reducers.resolve(TestStore.Reduce<IncrementNumberAction>.self)).toNot(beNil())
                    }

                    context("when performed another action") {

                        var composer: TestComposer!

                        beforeEach {
                            composer = TestComposer()
                            store.handle(action: IncrementNumberAction(increment: 2), composer: composer)
                        }

                        it("correctly reduces store's state") {
                            expect(store.state.number).toEventually(equal(2))
                        }

                        it("passes action to composer") {
                            expect(composer.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 2)))
                        }
                    }

                }
            }
        }
    }
}
