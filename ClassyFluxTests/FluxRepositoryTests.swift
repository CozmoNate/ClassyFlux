//
//  FluxRepositoryTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 15/08/2020.
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2020 Natan Zalkin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

import Quick
import Nimble

@testable import ClassyFlux

class FluxRepositoryTests: QuickSpec {

    override func spec() {

        describe("FluxRepository") {

            var repository: MockRepository!

            beforeEach {
                repository = MockRepository()
            }

            context("when registered the action") {

                beforeEach {
                    repository.registerMutator(for: ChangeValueAction.self) { (state, action) in
                        state.value = action.value
                        return [\MockRepository.value]
                    }
                }

                it("has registered mutator") {
                    expect(repository.mutators.resolve(MockRepository.Mutator<ChangeValueAction>.self)).toNot(beNil())
                }

                context("when unregistered the action") {

                    beforeEach {
                        repository.unregisterMutator(for: ChangeValueAction.self)
                    }

                    it("successfully unregistered the mutator") {
                        expect(repository.mutators.resolve(MockRepository.Mutator<ChangeValueAction>.self)).to(beNil())
                    }

                    context("when performed unregistered action") {

                        beforeEach {
                            _ = repository.handle(action: ChangeValueAction(value: "change it!"))
                        }

                        it("doesn't change store state") {
                            expect(repository.value).to(equal("initial"))
                            expect(repository.number).to(equal(0))
                        }
                    }
                }

                context("when performed registered action") {

                    var emitter: MockEmitter!

                    beforeEach {
                        emitter = MockEmitter()
                        repository.handle(action: ChangeValueAction(value: "test")).pass(to: emitter)
                    }

                    it("correctly mutates properties") {
                        expect(repository.value).to(equal("test"))
                    }

                    it("passes action to composer") {
                        expect(emitter.lastAction as? ChangeValueAction).to(equal(ChangeValueAction(value: "test")))
                    }
                }

                context("can add another mutator") {

                    beforeEach {
                        repository.registerMutator(for: IncrementNumberAction.self) { (state, action) in
                            state.number += action.increment
                            return [\MockRepository.number]
                        }
                    }

                    it("has registered IncrementNumberAction mutator") {
                        expect(repository.mutators.resolve(MockRepository.Mutator<IncrementNumberAction>.self)).toNot(beNil())
                    }

                    context("when performed another action") {

                        var emitter: MockEmitter!

                        beforeEach {
                            emitter = MockEmitter()
                            repository.handle(action: IncrementNumberAction(increment: 2)).pass(to: emitter)
                        }

                        it("correctly reduces store state") {
                            expect(repository.number).toEventually(equal(2))
                        }

                        it("passes action to composer") {
                            expect(emitter.lastAction as? IncrementNumberAction).to(equal(IncrementNumberAction(increment: 2)))
                        }
                    }

                }
            }
        }
    }
}
