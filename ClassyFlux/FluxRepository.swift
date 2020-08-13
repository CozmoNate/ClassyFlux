//
//  FluxRepository.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 13/08/2020.
//  Copyright © 2020 Natan Zalkin. All rights reserved.
//

/*
 * Copyright (c) 2020 Natan Zalkin
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

/// A name of the notification send alongside with corresponding repository event.
public let FluxRepositoryWillChangeNotification = Notification.Name(rawValue: "FluxRepositoryWillChange")

/// A name of the notification send alongside with corresponding repository event.
public let FluxRepositoryDidChangeNotification = Notification.Name(rawValue: "FluxRepositoryDidChange")

public let FluxRepositoryChangedKeyPathsKey = "changedKeyPaths"

// MARK: - FluxRepository

/// An object that represents a state by itself and allows self mutation by handling registered actions.
open class FluxRepository: FluxWorker {
    
    public let token: AnyHashable
    public let priority: UInt
    
    internal let mutators: ResolvingContainer
    
    public init(priority aPriority: UInt = 0) {
        token = UUID()
        priority = aPriority
        mutators = ResolvingContainer()
    }
}

extension FluxWorker where Self: FluxRepository {
    
    /// A repository mutator closure.
    /// - Parameter action: The action to handler.
    public typealias Mutator<Action: FluxAction> = (Self, Action) -> [PartialKeyPath<Self>]
    
    /// Associates the mutator closure with the actions of specified type.
    /// - Parameter action: The type of the actions to associate with the mutator closure.
    /// - Parameter execute: The closure that will be invoked when the action received.
    public func registerMutator<Action: FluxAction>(for action: Action.Type, mutator: @escaping Mutator<Action>) {
        mutators.register { mutator }
    }
    
    /// Unregisters mutator associated with the specified action type.
    /// - Parameter action: The action for which the associated mutator should be removed
    public func unregisterMutator<Action: FluxAction>(for action: Action.Type) {
        mutators.unregister(Mutator<Action>.self)
    }
    
    /// Unregisters all mutators.
    /// - Parameter action: The action for which the associated handler should be removed
    public func unregisterAllMutators() {
        mutators.unregisterAll()
    }
    
    /// Adds an observer that will be invoked each time the repository changes its state
    /// - Parameter queue: The queue to schedule change handler on
    /// - Parameter changeHandler: The closure will be invoked each time the state changes with the actual state object
    public func addObserver(queue: OperationQueue = .main, handler: @escaping (Self, Set<PartialKeyPath<Self>>) -> Void) -> Subscription {
        return Subscription(repository: self, queue: queue, handler: handler)
    }
    
    /// Adds an observer that will be invoked each time the repository changes its state
    /// - Parameter queue: The queue to schedule change handler on
    /// - Parameter observingKeyPaths: The list of KeyPath describing the fields in particular state object which should trigger state change handlers.
    /// - Parameter changeHandler: The closure will be invoked each time the state changes with the actual state object
    public func addObserver(observing observingKeyPaths: Set<PartialKeyPath<Self>>, queue: OperationQueue = .main, handler: @escaping (Self) -> Void) -> Subscription {
        return Subscription(repository: self, queue: queue) { state, changedKeyPaths in
            if !changedKeyPaths.isDisjoint(with: observingKeyPaths) {
                handler(self)
            }
        }
    }
    
    public func handle<Action: FluxAction>(action: Action) -> FluxPassthroughAction {
        if let mutate = self.mutators.resolve(Mutator<Action>.self) {
            
            NotificationCenter.default.post(name: FluxRepositoryWillChangeNotification, object: self)
            
            let changedKeyPaths = mutate(self, action)
            
            NotificationCenter.default.post(
                name: FluxRepositoryDidChangeNotification,
                object: self,
                userInfo: [FluxRepositoryChangedKeyPathsKey: Set(changedKeyPaths)]
            )
        }
        return .next(action)
    }
}

// MARK: - FluxRepository.Subscription

extension FluxRepository {
    
    /// An object that helps to subscribe to repository changes. Unregisters observer closure automatically when released from memory.
    public class Subscription {
        
        internal let observer: NSObjectProtocol
        
        internal init<Repository: FluxRepository>(repository: Repository, queue: OperationQueue, handler: @escaping (Repository, Set<PartialKeyPath<Repository>>) -> Void) {
            observer = NotificationCenter.default
                .addObserver(forName: FluxRepositoryDidChangeNotification, object: repository, queue: queue) { notification in
                    guard let repository = notification.object as? Repository else { return }
                    guard let keyPaths = notification.userInfo?[FluxRepositoryChangedKeyPathsKey] as? Set<PartialKeyPath<Repository>> else { return }
                    handler(repository, keyPaths)
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
