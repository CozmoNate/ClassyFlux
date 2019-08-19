//
//  FluxStore.swift
//  Flux
//
//  Created by Natan Zalkin on 31/07/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2019 Natan Zalkin
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

import Foundation
import Combine
import ResolverContainer


extension Notification.Name {

    /// The notification will be send every time store's state is changed. The notificatin sender will be the store object.
    static let FluxStoreStateChanged = Notification.Name(rawValue: "FluxStoreStateChanged")

}

/// An observable container that stores state of specified type and send notifications when the state gets updated.
open class FluxStore<State> {

    public typealias State = State
    public typealias Middleware = FluxMiddleware<State>

    /// A state reducer closure. Returns boolen flag indicating if the state is changed.
    /// - Parameter state: The mutable copy of current state to apply changes.
    /// - Parameter action: The action invoked the reducer.
    public typealias Reduce<Action: FluxAction> = (inout State, Action) -> Bool

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()

    /// A unique identifier of the store.
    public let token: UUID

    /// A state of the store.
    public var state: State {
        get { syncQueue.sync { backingState } }
        set { syncQueue.sync(flags: .barrier) { backingState = newValue } }
    }

    var backingState: State {
        willSet {
            if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .FluxStoreStateChanged, object: self)
            }
        }
    }

    var tokens: Set<UUID>
    var middlewares: [Middleware]
    let reducers: ResolverContainer
    let syncQueue: DispatchQueue

    /// Initialises the store
    /// - Parameter initialState: The initial state of the store
    /// - Parameter qos: The QOS of the underlying  sync state queue.
    public init(initialState: State, qos: DispatchQoS = .userInitiated) {
        token = UUID()
        backingState = initialState
        reducers = ResolverContainer()
        tokens = Set()
        middlewares = []
        syncQueue = DispatchQueue(label: "FluxStore.SyncQueue", qos: qos, attributes: .concurrent)
    }

    /// Associates a reducer with the actions of specified type.
    /// - Parameter action: The type of the actions to associate with reducer.
    /// - Parameter reducer: The closure that will be invoked when the action received.
    public func registerReducer<Action: FluxAction>(for action: Action.Type = Action.self, reducer: @escaping Reduce<Action>) {
        reducers.register { reducer }
    }

    /// Unregisters reducer associated with specified action type. Returns true if reducer unregistered successfully. Returns false when no reducer was registered for the action type.
    /// - Parameter action: The action for which the associated reducer should be removed.
    public func unregisterReducer<Action: FluxAction>(for action: Action.Type) -> Bool {

        typealias Reducer = Reduce<Action>

        return reducers.unregister(Reducer.self)
    }

    /// Registers middlewares that handles actions after all reducers finished.
    /// - Parameter middlewares: The list of middlewares. Dispatched actions will be passed to the middlewares in the same order as they were registered.
    public func append(middlewares middlewaresToAppend: [Middleware]) {
        middlewaresToAppend.forEach { middleware in
            if tokens.insert(middleware.token).inserted {
                middlewares.append(middleware)
            }
        }
    }

    /// Unregisters middlewares
    /// - Parameter tokensToRemove: The list of middleware tokens that should be unregistered.
    public func unregister(tokens uuidsToRemove: [UUID]) {
        let tokensToRemove = Set<UUID>(uuidsToRemove)
        tokens = tokens.subtracting(tokensToRemove)
        middlewares = middlewares.filter { !tokensToRemove.contains($0.token) }
    }

}

extension FluxStore: FluxWorker {

    public func handle<Action: FluxAction>(action: Action, completion: @escaping () -> Void) {

        typealias Reducer = Reduce<Action>

        if let reduce = try? reducers.resolve(Reducer.self) {

            var draft = state

            if reduce(&draft, action) {
                state = draft
            }
        }

        middlewares.forEach { $0.handle(action: action, state: state) }

        completion()
    }

}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FluxStore: ObservableObject {}
