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
import ResolverContainer

#if canImport(Combine)
import Combine
#endif

#if canImport(Combine)
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension FluxStore: ObservableObject {}
#endif

public enum FluxStoreEvent {
    case stateWillChange, stateDidChange

    internal var notificationName: Notification.Name {
        switch self {
        case .stateWillChange: return FluxNotificatons.StoreWillChangeNotification
        case .stateDidChange: return FluxNotificatons.StoreDidChangeNotification
        }
    }
}

/// Store contains a state object triggers reducer to modify the state as a response to action dispatched
open class FluxStore<State>: FluxWorker {

    public typealias State = State

    /// A state reducer closure. Returns boolen flag indicating if the state is changed.
    /// - Parameter state: The mutable copy of current state to apply changes.
    /// - Parameter action: The action invoked the reducer.
    public typealias Reduce<Action: FluxAction> = (inout State, Action) -> [PartialKeyPath<State>]

    #if canImport(Combine)
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var stateWillChange = PassthroughSubject<(State, Set<PartialKeyPath<State>>), Never>()

    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public lazy var stateDidChange = PassthroughSubject<(State, Set<PartialKeyPath<State>>), Never>()
    #endif

    /// A unique identifier of the store.
    public let token: UUID

    /// A state of the store.
    public private(set) var state: State {
        get {
            if Thread.isMainThread {
                return backingState
            } else {
                return DispatchQueue.main.sync { return backingState }
            }
        }
        set {
            if Thread.isMainThread {
                backingState = newValue
            } else {
                DispatchQueue.main.sync { backingState = newValue }
            }
        }
    }

    internal var backingState: State
    internal let reducers: ResolverContainer

    /// Initialises the store
    /// - Parameter initialState: The initial state of the store
    public init(initialState: State) {
        token = UUID()
        backingState = initialState
        reducers = ResolverContainer()
    }

    /// An event called before the state is passed to reducers.
    /// Default implementations sends notifications about state changes.
    /// If you want to preserve default behaivior you must call super in your custom store class implementation.
    open func stateWillChange(_ state: State, at keyPaths: Set<PartialKeyPath<State>>) {
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            objectWillChange.send()
            stateDidChange.send((state, keyPaths))
        }
        #endif

        NotificationCenter.default.post(name: FluxNotificatons.StoreWillChangeNotification, object: self, userInfo: [FluxNotificatons.ChangedKeyPathsKey: keyPaths])
    }

    /// An event called after the state is passed to reducers.
    /// Default implementations sends notifications about state changes.
    /// If you want to preserve default behaivior you must call super in your custom store class implementation.
    open func stateDidChange(_ state: State, at keyPaths: Set<PartialKeyPath<State>>) {
        #if canImport(Combine)
        if #available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            stateDidChange.send((state, keyPaths))
        }
        #endif

        NotificationCenter.default.post(name: FluxNotificatons.StoreDidChangeNotification, object: self, userInfo: [FluxNotificatons.ChangedKeyPathsKey: keyPaths])
    }

    /// Adds an observer that will be invoked each time the store chages its state
    /// - Parameter queue: The queue to schedule change handler on
    /// - Parameter changeHandler: The closure will be invoked each time the state chages with the actual state object
    public func addObserver(for event: FluxStoreEvent, queue: OperationQueue = .main, changeHandler: @escaping (State, Set<PartialKeyPath<State>>) -> Void) -> Observer {
        return Observer(for: event, from: self, queue: queue, changeHandler: changeHandler)
    }

    /// Associates a reducer with the actions of specified type.
    /// - Parameter action: The type of the actions to associate with reducer.
    /// - Parameter reducer: The closure that will be invoked when the action received.
    public func registerReducer<Action: FluxAction>(for action: Action.Type = Action.self, reducer: @escaping Reduce<Action>) {
        reducers.register { reducer }
    }

    /// Unregisters reducer associated with specified action type.
    /// - Parameter action: The action for which the associated reducer should be removed.
    /// - Returns: True if the reducer is unregistered successfully. False when no reducer was registered for the action type.
    public func unregisterReducer<Action: FluxAction>(for action: Action.Type) -> Bool {

        typealias Reducer = Reduce<Action>

        return reducers.unregister(Reducer.self)
    }

    public func handle<Action: FluxAction>(action: Action, composer: FluxComposer) {

        typealias Reducer = Reduce<Action>

        if let reduce = try? reducers.resolve(Reducer.self) {

            var draft = state

            let keyPaths = Set(reduce(&draft, action))
            
            if !keyPaths.isEmpty {
                stateWillChange(state, at: keyPaths)
                state = draft
                stateDidChange(state, at: keyPaths)
            }
        }

        composer.next(action: action)
    }

}

extension FluxStore {

    /// An object that helps to subscribe to store changes. Unregisters observer closure automatically when released from memory.
    public class Observer {

        internal let observer: NSObjectProtocol

        internal init<State>(for event: FluxStoreEvent,
                             from store: FluxStore<State>,
                             queue: OperationQueue,
                             changeHandler: @escaping (State, Set<PartialKeyPath<State>>) -> Void) {
            observer = NotificationCenter.default
                .addObserver(forName: event.notificationName, object: store, queue: queue) { notification in
                    guard let store = notification.object as? FluxStore<State> else { return }
                    guard let keyPaths = notification.userInfo?[FluxNotificatons.ChangedKeyPathsKey] as? Set<PartialKeyPath<State>> else { return }
                    changeHandler(store.state, keyPaths)
                }
        }

        deinit {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}
