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

struct ChangeValueAction: FluxAction, Equatable {
    let value: String
}

struct IncrementNumberAction: FluxAction {
    var increment: Int
}

struct TestState: Equatable {
    var value: String
    var number: Int
}

class TestWorker: FluxWorker {

    let token = UUID()

    var lastAction: FluxAction?

    func handle<Action>(action: Action, completion: @escaping () -> Void) where Action : FluxAction {
        lastAction = action
        completion()
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
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
