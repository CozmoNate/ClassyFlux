//
//  FluxComposer.swift
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

/// An object that passes the action to the next workers. It allows to compose
/// a function where resulting action depends on previous actions.
public protocol FluxComposer: AnyObject {

    /// Passes next action to workers.
    /// - Parameter action: The action to perform next.
    func next<Action: FluxAction>(action: Action)

}

/// A composer passing action from one worker to next worker located in the stack (array).
/// FluxStackingComposer instance can be used only once by calling 'next(action:)' method which will start action propagation to the workers.
public class FluxStackingComposer: FluxComposer {

    internal var iterator: IndexingIterator<[FluxWorker]>?

    public init(workers: [FluxWorker]) {
        iterator = workers.makeIterator()
    }

    public func next<Action: FluxAction>(action: Action)  {
        iterator?.next()?.handle(action: action)(self)
    }

}
