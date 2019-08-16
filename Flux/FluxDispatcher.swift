//
//  FluxDispatcher.swift
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
import ResolverContainer
import CustomOperation


/// An object that dispatches actions to registered workers
open class FluxDispatcher {

    public static let `default` = FluxDispatcher()

    var tokens: Set<UUID>
    var workers: [FluxWorker]
    let operationQueue: OperationQueue

    /// Initialises the dispatcher with specified quality of service of undelayng dispatch queue
    /// - Parameter qos: The QOS of theunderlaying dispatch queue
    public init(qos: QualityOfService = .userInitiated) {

        tokens = Set()
        workers = []

        operationQueue = OperationQueue()
        operationQueue.qualityOfService = qos
        operationQueue.maxConcurrentOperationCount = 1
    }

    /// Registers workers in dispatcher. If another worker with the same token is already registered, the worker will be ignored.
    /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as the workers were registered.
    public func register(workers: [FluxWorker]) {
        operationQueue.addOperation {
            workers.forEach { worker in
                if self.tokens.insert(worker.token).inserted {
                    self.workers.append(worker)
                }
            }
        }
    }

    /// Unregisters workers from dispatching actions
    /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered
    public func unregister(tokens: [UUID]) {
        operationQueue.addOperation {
            let tokensToRemove = Set<UUID>(tokens)
            self.tokens = self.tokens.subtracting(tokensToRemove)
            self.workers = self.workers.filter { !tokensToRemove.contains($0.token) }
        }
    }

    /// Dispatches an action to registered workers
    /// - Parameter action: The action to dispatch
    public func dispatch<Action: FluxAction>(action: Action) {
        operationQueue.addOperation {
            self.workers.forEach { worker in
                self.operationQueue.addOperation { completion in
                    worker.handle(action: action, completion: completion)
                }
            }
        }
    }

    /// Dispatches an operation to run in the same queue as the actions
    /// - Parameter operation: The operation to dispatch
    public func dispatch(operation: Operation) {
        operationQueue.addOperation(operation)
    }

    /// Dispatches a closure to run in the same queue as the actions
    /// - Parameter operation: The closure to dispatch
    public func dispatch(block: @escaping () -> Void) {
        dispatch(operation: BlockOperation(block: block))
    }

}
