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
                    
                    store.registerMutator { (state, action: IncrementNumberAction) in
                        guard action.increment != 0 else { return nil }
                        return TestState(value: "mutated", number: state.number + action.increment)
                    }
                }

                it("has correct initial value") {
                    expect(store.state.value).to(equal("initial"))
                    expect(store.state.number).to(equal(0))
                }

                it("has registered reducer & mutator") {
                    expect(try? store.reducers.resolve(TestStore.Reduce<ChangeValueAction>.self)).toNot(beNil())
                    expect(try? store.reducers.resolve(TestStore.Reduce<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    beforeEach {
                        store.unregisterReducer(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the reducer") {
                        expect(try? store.reducers.resolve(TestStore.Reduce<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        beforeEach {
                            store.handle(action: ChangeValueAction(value: "change it!"))(TestComposer())
                        }

                        it("doesn't change store state") {
                            expect(store.state.value).to(equal("initial"))
                            expect(store.state.number).to(equal(0))
                        }
                    }
                }

                context("when performed well known action") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        store.handle(action: ChangeValueAction(value: "test"))(composer)
                    }

                    it("calls state change events") {
                        expect(store.stateBeforeChange?.value).to(equal("initial"))
                        expect(store.stateAfterChange?.value).to(equal("test"))
                    }

                    it("correctly reduces store state") {
                        expect(store.state.value).to(equal("test"))
                    }

                    it("passes action to composer") {
                        expect(composer.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                    }
                }
                
                context("when performed action that mutates the whole state") {

                    var composer: TestComposer!

                    beforeEach {
                        composer = TestComposer()
                        store.handle(action: IncrementNumberAction(increment: 1))(composer)
                    }

                    it("calls state change events") {
                        expect(store.stateBeforeChange?.value).to(equal("initial"))
                        expect(store.stateBeforeChange?.number).to(equal(0))
                        expect(store.stateAfterChange?.value).to(equal("mutated"))
                        expect(store.stateAfterChange?.number).to(equal(1))
                    }

                    it("correctly reduces store state") {
                        expect(store.state.value).to(equal("mutated"))
                        expect(store.state.number).to(equal(1))
                    }

                    it("passes the action to composer") {
                        expect(composer.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 1)))
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
                            store.handle(action: IncrementNumberAction(increment: 2))(composer)
                        }

                        it("correctly reduces store state") {
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
