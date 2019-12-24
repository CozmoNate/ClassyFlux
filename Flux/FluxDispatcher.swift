//
//  FluxDispatcher.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 19/08/2019.
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

/// A protocol describing object that dispatches an action to workers.
public protocol FluxDispatcher: AnyObject {

    /// Registers workers in the dispatcher. Only one worker with the same token can be registered in the dispatcher.
    /// - Parameter workers: The list of workers to register in the dispatcher
    func register(workers: [FluxWorker])
    
    /// Unregisters workers from the dispatcher.
    /// - Parameter tokens: The list of tokens of workers that should be unregistered.
    func unregister(tokens: [AnyHashable])
    
    /// Passes the action to workers.
    /// - Parameter action: The action to pass.
    func dispatch<Action: FluxAction>(action: Action)

}
