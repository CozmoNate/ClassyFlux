//
//  Mocks.swift
//  FluxTests
//
//  Created by Natan Zalkin on 04/08/2019.
//  Copyright © 2019 Natan Zalkin. All rights reserved.
//

import Foundation

@testable import Flux

struct ChangeValueAction: FluxAction {
    let value: String
}

struct IncrementNumberAction: FluxAction {
    var increment: Int
}

struct TestSate: FluxState {
    var value: String
    var number: Int
}
