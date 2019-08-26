//
//  FluxObserver.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 23/08/2019.
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

extension FluxStore {
    
    /// An object that helps to subscribe to store changes. Unregisters observer closure automatically when released from memory.
    open class Observer {

        internal let observer: NSObjectProtocol

        internal init<State>(for store: FluxStore<State>, changeHandler: @escaping (State) -> Void) {
            observer = NotificationCenter.default
                .addObserver(forName: .FluxStoreChanged, object: store, queue: .main) { notification in
                    guard let store = notification.object as? FluxStore<State> else { return }
                    changeHandler(store.state)
                }
        }

        deinit {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}
