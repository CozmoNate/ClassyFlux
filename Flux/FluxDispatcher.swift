//
//  FluxDispatcher.swift
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

/// An object that dispatches actions serially to registered workers.
open class FluxDispatcher: FluxActionDispatching {

    public static let `default` = FluxDispatcher()

    var tokens: Set<UUID>
    var workers: [FluxWorker]
    let operationQueue: OperationQueue

    /// Initialises a dispatcher.
    /// - Parameter queue: The queue to be used to dispatch actions. Passed queue will be forcibly configured to run only one operation at a time.
    public init(queue: OperationQueue? = nil) {

        tokens = Set()
        workers = []

        if let queue = queue {
            operationQueue = queue
        } else {
            operationQueue = OperationQueue()
            operationQueue.qualityOfService = .userInitiated
        }

        operationQueue.maxConcurrentOperationCount = 1
    }

    /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
    /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as they were registered.
    public func append(workers: [FluxWorker]) {
        operationQueue.addOperation {
            workers.forEach { worker in
                if self.tokens.insert(worker.token).inserted {
                    self.workers.append(worker)
                }
            }
        }
    }

    /// Unregisters workers from the dispatcher.
    /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered.
    public func unregister(tokens: [UUID]) {
        operationQueue.addOperation {
            let tokensToRemove = Set<UUID>(tokens)
            self.tokens = self.tokens.subtracting(tokensToRemove)
            self.workers = self.workers.filter { !tokensToRemove.contains($0.token) }
        }
    }

    /// Dispatches an action to workers.
    /// - Parameter action: The action to dispatch to workers.
    public func dispatch<Action: FluxAction>(action: Action) {
        operationQueue.addOperation {
            FluxStackingComposer(workers: self.workers).next(action: action)
        }
    }

    /// Dispatches an operation to run in the same queue as regular actions.
    /// - Parameter operation: The operation to dispatch.
    public func dispatch(operation: Operation) {
        operationQueue.addOperation(operation)
    }

    /// Dispatches a closure to run in the same queue as regular actions.
    /// - Parameter operation: The closure to dispatch.
    public func dispatch(block: @escaping () -> Void) {
        dispatch(operation: BlockOperation(block: block))
    }

}
