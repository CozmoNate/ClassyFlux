//
//  FluxViewTests.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 10/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import SwiftUI

@testable import ClassyFlux


class FluxViewTests: QuickSpec {

    override func spec() {

        guard #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) else {
            return
        }

        describe("FluxView") {

            var view: TestView!

            beforeEach {
                view = TestView(testValue: "Test")
            }

            it("correctly calculates properties") {
                expect(view.calculateProperties().value).to(equal("Test"))
            }

            it("correctly renders body") {
                expect(view.render(properties: TestView.Properties(value: "Test"))).to(beAKindOf(Text.self))
            }

            it("renders view regarding properties calculated") {
                expect(view.body).to(beAKindOf(Text.self))
            }
        }
        
    }
}
