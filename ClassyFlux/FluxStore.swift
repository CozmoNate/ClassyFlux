//
//  FluxStore.swift
//  ClassyFlux
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
import ResolvingContainer

// MARK: - Constants

/// A name of the notification send alongside with corresponding store event.
public let FluxStoreWillChangeNotification = Notification.Name(rawValue: "FluxStoreWillChange")

/// A name of the notification send alongside with corresponding store event.
public let FluxStoreDidChangeNotification = Notification.Name(rawValue: "FluxStoreDidChange")

/// A key in the UserInfo dictionary of a notification pointing to the set of keypaths describing changed properties of store state object.
public let FluxStoreNotificationKeyPathsKey = "changedKeyPaths"

// MARK: - FluxStore

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FluxStore: ObservableObject {}
#endif

/// An object that stores the state and allows state mutation only by handling registered actions.
open class FluxStore<State>: FluxWorker {
    public typealias State = State

    /// A state reducer closure. Returns the list of keyPaths describing state changed fields.
    /// - Parameter state: The mutable copy of current state to apply changes.
    /// - Parameter action: The action invoked the reducer.
    public typealias Reducer<Action: FluxAction> = (inout State, Action) -> [PartialKeyPath<State>]

    #if canImport(Combine)
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var stateWillChange = PassthroughSubject<Change, Never>()

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var stateDidChange = PassthroughSubject<Change, Never>()
    #endif

    public let token: AnyHashable
    public let priority: UInt

    /// A state of the store.
    public private(set) var state: State

    internal let reducers: ResolvingContainer

    /// Initialises the store
    /// - Parameter initialState: The initial state of the store
    public init(priority aPriority: UInt = 0, initialState: State) {
        token = UUID()
        priority = aPriority
        state = initialState
        reducers = ResolvingContainer()
    }

    /// Associates a reducer with the action of specified type. Reducer applies changes to the part of the state object.
    /// - Parameter action: The type of the actions to associate with reducer.
    /// - Parameter reducer: The closure that will be invoked when the action received.
    public func registerReducer<Action: FluxAction>(for action: Action.Type = Action.self, reducer: @escaping Reducer<Action>) {
        reducers.register { reducer }
    }

    /// Unregisters reducer associated with specified action type.
    /// - Parameter action: The action for which the associated reducer should be removed.
    public func unregisterReducer<Action: FluxAction>(for action: Action.Type) {
        reducers.unregister(Reducer<Action>.self)
    }
    
    /// Unregisters all reducers.
    public func unregisterAllReducers() {
        reducers.unregisterAll()
    }

    public func handle<Action: FluxAction>(action: Action) -> FluxPassthroughAction {
        if let reducer = reducers.resolve(Reducer<Action>.self) {
            reduceState(with: reducer, applying: action)
        }

        return .next(action)
    }
    
    /// Adds an observer that will be invoked each time the store changes its state
    /// - Parameter queue: The queue to schedule change handler on
    /// - Parameter handler: The closure will be invoked each time the state changes with the actual state object
    public func addObserver(for event: Event, queue: OperationQueue = .main, handler: @escaping (State, Set<PartialKeyPath<State>>) -> Void) -> Subscription {
        return Subscription(for: event, from: self, queue: queue, handler: handler)
    }
    
    /// Adds an observer that will be invoked each time the store changes its state
    /// - Parameter queue: The queue to schedule change handler on
    /// - Parameter observingKeyPaths: The list of KeyPath describing the fields in particular state object which should trigger state change handlers.
    /// - Parameter handler: The closure will be invoked each time the state changes with the actual state object
    public func addObserver(for event: Event, observing observingKeyPaths: Set<PartialKeyPath<State>>, queue: OperationQueue = .main, handler: @escaping (State) -> Void) -> Subscription {
        return Subscription(for: event, from: self, queue: queue) { state, changedKeyPaths in
            if !changedKeyPaths.isDisjoint(with: observingKeyPaths) {
                handler(state)
            }
        }
    }
    
    /// An event called before the state will change.
    /// Default implementations sends notifications about state changes.
    /// If you want to preserve default behaviour you must call super in your custom store class implementation.
    open func stateWillChange(_ state: State, at keyPaths: Set<PartialKeyPath<State>>) {
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            objectWillChange.send()
            stateWillChange.send(Change(state: state, keyPaths: keyPaths))
        }
        #endif

        NotificationCenter.default.post(name: Event.stateWillChange.notificationName, object: self, userInfo: [FluxStoreNotificationKeyPathsKey: keyPaths])
    }

    /// An event called after the state is changed
    /// Default implementations sends notifications about state changes.
    /// If you want to preserve default behaviour you must call super in your custom store class implementation.
    open func stateDidChange(_ state: State, at keyPaths: Set<PartialKeyPath<State>>) {
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            stateDidChange.send(Change(state: state, keyPaths: keyPaths))
        }
        #endif

        NotificationCenter.default.post(name: Event.stateDidChange.notificationName, object: self, userInfo: [FluxStoreNotificationKeyPathsKey: keyPaths])
    }

    internal func reduceState<Action: FluxAction>(with reducer: Reducer<Action>, applying action: Action) {
        var draftState = state
        let keyPaths = Set(reducer(&draftState, action))

        if !keyPaths.isEmpty {
            stateWillChange(state, at: keyPaths)
            state = draftState
            stateDidChange(state, at: keyPaths)
        }
    }
}

// MARK: - FluxStore.Change

extension FluxStore {
    
    public struct Change {
        public let state: State
        public let keyPaths: Set<PartialKeyPath<State>>
    }
}

// MARK: - FluxStore.Event

extension FluxStore {
    
    public enum Event {
        case stateWillChange
        case stateDidChange

        /// A name of the notification send alongside with corresponding store event.
        public var notificationName: Notification.Name {
            switch self {
            case .stateWillChange: return FluxStoreWillChangeNotification
            case .stateDidChange: return FluxStoreDidChangeNotification
            }
        }
    }
}

// MARK: - FluxStore.Subscription

extension FluxStore {

    /// An object that helps to subscribe to store changes. Unregisters observer closure automatically when released from memory.
    public class Subscription {
        
        internal let observer: NSObjectProtocol

        internal init<State>(for event: Event, from store: FluxStore<State>, queue: OperationQueue, handler: @escaping (State, Set<PartialKeyPath<State>>) -> Void) {
            observer = NotificationCenter.default
                .addObserver(forName: event.notificationName, object: store, queue: queue) { notification in
                    guard let store = notification.object as? FluxStore<State> else { return }
                    guard let keyPaths = notification.userInfo?[FluxStoreNotificationKeyPathsKey] as? Set<PartialKeyPath<State>> else { return }
                    handler(store.state, keyPaths)
                }
        }

        /// Cancels the subscription.
        func cancel() {
            NotificationCenter.default.removeObserver(observer)
        }

        /// Stores subscription in the array.
        func store(in subscriptions: inout [Subscription]) {
            subscriptions.append(self)
        }

        deinit {
            cancel()
        }
    }
}
