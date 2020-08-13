//
//  Mocks.swift
//  FluxTests
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Foundation
import SwiftUI
import ResolvingContainer

@testable import ClassyFlux

struct ChangeValueAction: FluxAction, Equatable {
    let value: String
}

struct IncrementNumberAction: FluxAction, Equatable {
    var increment: Int
}

struct EmptyAction: FluxAction, Equatable {}

struct MockState: Equatable {
    var value: String
    var number: Int
}

class MockMiddleware: FluxMiddleware {
    var didIncrement: Bool?
    var didIntercept: Bool?
}

class MockRepository: FluxRepository {
    var value: String = "initial"
    var number: Int = 0
}

class MockStore: FluxStore<MockState> {

    var stateBeforeChange: State?
    var pathsBeforeChange: Set<PartialKeyPath<MockState>>?
    var stateAfterChange: State?
    var pathsAfterChange: Set<PartialKeyPath<MockState>>?

    override func stateWillChange(_ state: MockState, at keyPaths: Set<PartialKeyPath<MockState>>) {
        stateBeforeChange = state
        pathsBeforeChange = keyPaths
        super.stateWillChange(state, at: keyPaths)
    }

    override func stateDidChange(_ state: MockState, at keyPaths: Set<PartialKeyPath<MockState>>) {
        stateAfterChange = state
        pathsAfterChange = keyPaths
        super.stateDidChange(state, at: keyPaths)
    }
}

class MockDispatcher: FluxDispatcher {

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

class MockEmitter: FluxActionEmitter {

    var lastAction: FluxAction?
    
    var isEmpty: Bool = false
    
    func emit<Action>(action: Action) where Action : FluxAction {
        lastAction = action
    }
}

class MockWorker: FluxWorker {
    
    let token: AnyHashable = UUID()
    let priority: UInt
    
    var lastAction: FluxAction?

    init(priority: UInt) {
        self.priority = priority
    }

    func handle<Action>(action: Action) -> FluxPassthroughAction where Action : FluxAction {
        lastAction = action
        return .next(action)
    }
}
