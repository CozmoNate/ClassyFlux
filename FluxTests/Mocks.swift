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

struct IncrementNumberAction: FluxAction, Equatable {
    var increment: Int
}

struct TestState: Equatable {
    var value: String
    var number: Int
}

class TestStore: FluxStore<TestState> {

    var stateBeforeChange: State?
    var pathsBeforeChange: [PartialKeyPath<TestState>]?
    var stateAfterChange: State?
    var pathsAfterChange: [PartialKeyPath<TestState>]?

    init() {
        super.init(initialState: TestState(value: "initial", number: 0))

        registerReducer { (state, action: ChangeValueAction) in
            state.value = action.value
            return [\TestState.value]
        }

        registerReducer { (state, action: IncrementNumberAction) in
            state.number += action.increment
            return [\TestState.number]
        }
    }

    override func stateWillChange(_ state: TestState, at keyPaths: [PartialKeyPath<TestState>]) {
        stateBeforeChange = state
        pathsBeforeChange = keyPaths
    }

    override func stateDidChange(_ state: TestState, at keyPaths: [PartialKeyPath<TestState>]) {
        stateAfterChange = state
        pathsAfterChange = keyPaths
    }
}

class TestComposer: FluxComposer {

    var lastAction: FluxAction?

    func next<Action>(action: Action) where Action : FluxAction {
        lastAction = action
    }
}

class TestWorker: FluxWorker {

    let token = UUID()

    var lastAction: FluxAction?

    func handle<Action>(action: Action, composer: FluxComposer) where Action : FluxAction {
        lastAction = action
        composer.next(action: action)
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
