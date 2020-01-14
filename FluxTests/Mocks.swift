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

struct EmptyAction: FluxAction, Equatable {}

struct TestState: Equatable {
    var value: String
    var number: Int
}

class TestMiddleware: FluxMiddleware {
    var didIncrement: Bool?
    var didIntercept: Bool?
}

class TestStore: FluxStore<TestState> {

    var stateBeforeChange: State?
    var pathsBeforeChange: Set<PartialKeyPath<TestState>>?
    var stateAfterChange: State?
    var pathsAfterChange: Set<PartialKeyPath<TestState>>?
    

    init(priority: UInt = 0) {
        super.init(priority: priority, initialState: TestState(value: "initial", number: 0))

        registerReducer { (state, action: ChangeValueAction) in
            state.value = action.value
            return [\TestState.value]
        }

        registerReducer { (state, action: IncrementNumberAction) in
            state.number += action.increment
            return [\TestState.number]
        }
    }

    override func stateWillChange(_ state: TestState, at keyPaths: Set<PartialKeyPath<TestState>>) {
        stateBeforeChange = state
        pathsBeforeChange = keyPaths
        super.stateWillChange(state, at: keyPaths)
    }

    override func stateDidChange(_ state: TestState, at keyPaths: Set<PartialKeyPath<TestState>>) {
        stateAfterChange = state
        pathsAfterChange = keyPaths
        super.stateDidChange(state, at: keyPaths)
    }
}

class TestDispatcher: FluxDispatcher {

    var lastAction: FluxAction?
    var lastWorkers: [FluxWorker]?
    var lastTokens: [AnyHashable]?

    override func register(workers: [FluxWorker]) {
        lastWorkers = workers
    }
    
    override func unregister(tokens: [AnyHashable]) {
        lastTokens = tokens
    }
    
    override func dispatch<Action>(action: Action) where Action : FluxAction {
        lastAction = action
    }
}

class TestPipeline: FluxPipeline {

    var lastAction: FluxAction?
    
    var isEmpty: Bool = false
    
    func next<Action>(action: Action) where Action : FluxAction {
        lastAction = action
    }
}

class TestWorker: FluxWorker {
    
    let token: AnyHashable = UUID()
    let priority: UInt
    
    var lastAction: FluxAction?

    init(priority: UInt) {
        self.priority = priority
    }

    func handle<Action>(action: Action) -> FluxComposer where Action : FluxAction {
        lastAction = action
        return .next(action)
    }
}
