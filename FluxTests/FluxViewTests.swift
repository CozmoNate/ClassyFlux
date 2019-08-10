//
//  FluxViewTests.swift
//  Flux
//
//  Created by Natan Zalkin on 10/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Quick
import Nimble
import SwiftUI

@testable import Flux

class FluxViewTests: QuickSpec {

    override func spec() {

        describe("FluxView") {

            var view: TestView!

            beforeEach {
                view = TestView(testValue: "Test")
            }

            it("correctly calculates properties") {
                expect(view.calculateProperties().value).to(equal("Test"))
            }

            it("Renders view regarding properties calculated") {
                expect(view.body).to(beAKindOf(FluxRenderer<Text>.self))
            }
        }
        
    }
}

struct TestView: FluxView {

    struct Properties {
        let value: String
    }

    let testValue: String

    func calculateProperties() -> TestView.Properties {
        return Properties(value: testValue)
    }

    func render(properties: Properties) -> some View {
        Text(properties.value)
    }
}
