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
import Combine
import Resolver
import AsyncOperation

open class FluxDispatcher {

    // MARK: - Private

    var tokens: Set<UUID>
    var workers: [FluxWorker]
    let operationQueue: OperationQueue

    // MARK: - Methods

    public init() {

        tokens = Set()
        workers = []

        operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        operationQueue.maxConcurrentOperationCount = 1
    }

    public func register(worker: FluxWorker) {
        operationQueue.addOperation {
            if self.tokens.insert(worker.token).inserted {
                self.workers.append(worker)
            }
        }
    }
    
    public func dispatch<Action: FluxAction>(action: Action) {
        operationQueue.addOperation {
            self.workers.forEach { worker in
                self.operationQueue.addOperation { completion in
                    worker.perform(action: action, completion: completion)
                }
            }
        }
    }

}
