//
//  Mocks.swift
//  FluxTests
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Foundation
import SwiftUI
import ResolverContainer

@testable import ClassyFlux

struct ChangeValueAction: FluxAction {
    let value: String
}

struct IncrementNumberAction: FluxAction {
    var increment: Int
}

struct UnknownAction: FluxAction {
}

struct TestSate: FluxState {
    var value: String
    var number: Int
}

class TestRepository: FluxRepository {

    private(set) var value: String
    private(set) var number: Int

    init(value: String = "initial", number: Int = 0) {
        self.value = value
        self.number = number
    }

    func changeValue(_ newValue: String) -> Bool {
        guard newValue != value else { return false }
        value = newValue
        return true
    }

    func incrementNumber(_ newNumber: Int) -> Bool {
        guard newNumber != 0 else { return false }
        number += newNumber
        return true
    }
}

@available(iOS 13.0, OSX 10.15, *)
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
