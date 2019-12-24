//
//  FluxInteractiveDispatcher.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 17/12/2019.
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

/// Am object that dispatches actions to registered workers on the main thread.
final public class FluxInteractiveDispatcher: FluxSynchronousDispatcher {

    /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
    /// - Parameter workers: The list of workers to register in the dispatcher. Dispatched actions will be passed to the workers in the same order as they were registered.
    override public func register(workers workersToInsert: [FluxWorker]) {
        scheduleOnMain { super.register(workers: workersToInsert) }
    }

    /// Unregisters workers from the dispatcher.
    /// - Parameter tokensToRemove: The list of tokens of workers that should be unregistered.
    override public func unregister(tokens tokensToRemove: [AnyHashable]) {
        scheduleOnMain { super.unregister(tokens: tokensToRemove) }
    }

    /// Dispatches an action to workers.
    /// - Parameter action: The action to dispatch to workers.
    override public func dispatch<Action: FluxAction>(action: Action) {
        scheduleOnMain { super.dispatch(action: action) }
    }

    private func scheduleOnMain(execute action: @escaping () -> Void) {
        if Thread.isMainThread && !isDispatching {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

}
