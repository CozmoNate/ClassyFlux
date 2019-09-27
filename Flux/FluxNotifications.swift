//
//  FluxNotifications.swift
//  ClassyFlux
//
//  Created by Natan Zalkin on 27/09/2019.
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

public struct FluxNotificatons {

    /// The notification sent before the store state is changed.
    /// The notification sender will be changed store object.
    public static let StoreWillChangeNotification = Notification.Name(rawValue: "FluxStoreDidChange")

    /// The notification sent after the store state is changed.
    /// The notification sender will be changed store object.
    /// User
    public static let StoreDidChangeNotification = Notification.Name(rawValue: "FluxStoreDidChange")

    /// A key in the UserInfo dictionary of store changed notification pointing to the set of keypaths describing changed properties of store state object.
    public static let ChangedKeyPathsKey = "ChangedKeyPaths"
}
