//
//  FluxConventionalStoreTests.swift
//  Flux
//
//  Created by Natan Zalkin on 12/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import ClassyFlux

class FluxRepositoryTests: QuickSpec {

    override func spec() {

        describe("FluxRepository") {

            var repository: TestRepository!

            beforeEach {
                repository = TestRepository()
                
                repository.registerReducer { (repo, action: ChangeValueAction) in
                    return repo.changeValue(action.value)
                }
            }

            it("has correct initial value") {
                expect(repository.value).to(equal("initial"))
            }

            it("has registered initial ChangeValueAction reducer") {
                expect(try? repository.reducers.resolve(TestRepository.Reduce<ChangeValueAction>.self)).toNot(beNil())
            }

            context("when performed unknown action") {

                it("doesn't change repository") {
                    waitUntil { done in
                        repository.handle(action: UnknownAction()) {
                            expect(repository.value).to(equal("initial"))
                            done()
                        }
                    }
                }

            }

            context("when performed well known action") {

                var didFinish: Bool = false
                var notificationSent: Bool?

                beforeEach {

                    notificationSent = nil

                    NotificationCenter.default.addObserver(forName: Notification.Name.FluxRepositoryChanged, object: nil, queue: OperationQueue()) { _ in
                        notificationSent = true
                    }
                }

                context("and has changes") {

                    beforeEach {
                        repository.handle(action: ChangeValueAction(value: "test")) {
                            didFinish = true
                        }
                    }

                    it("correctly changes value") {
                        expect(repository.value).toEventually(equal("test"))
                    }

                    it("finishes operation and sends notification") {
                        expect(didFinish).toEventually(beTrue())
                        expect(notificationSent).toEventually(beTruthy())
                    }
                }

                context("no changes") {

                    it("doesn't change repository") {
                        waitUntil { done in
                            repository.handle(action: ChangeValueAction(value: "initial")) {
                                expect(repository.value).to(equal("initial"))
                                expect(notificationSent).to(beNil())
                                done()
                            }
                        }
                    }
                }
            }

            context("can add another reducer") {

                beforeEach {
                    repository.registerReducer { (repo, action: IncrementNumberAction) in
                        return repo.incrementNumber(action.increment)
                    }
                }

                it("has registered IncrementNumberAction reducer") {
                    expect(try? repository.reducers.resolve(TestRepository.Reduce<IncrementNumberAction>.self)).toNot(beNil())
                }

                context("when performed another action") {

                    var didFinish: Bool = false

                    beforeEach {
                        repository.handle(action: IncrementNumberAction(increment: 2)) {
                            didFinish = true
                        }
                    }

                    it("correctly increments number") {
                        expect(repository.number).toEventually(equal(2))
                    }

                    it("finishes operation") {
                        expect(didFinish).toEventually(beTrue())
                    }
                }

            }
        }

    }

}

