//
//  PromiseTester.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/21/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import Promises

class PromiseTester {

    func test12() -> Promise<Int> {
        return Promise<Int>(12)
    }

    func test13(_ add: Int) -> Promise<Int> {
        return Promise<Int>(13 + add)
    }

    func doIt() {
        Promise<Int>(on: .global()) { () -> Int in
            let x = try await(self.test12())
            return try await(self.test13(x))
        }.then { result in
            print("hello = \(result)")
        }
    }

    func doItNew() {
        doItToIt {
            let x = try await(self.test12())
            return try await(self.test13(x))
        }
    }

    func doItToIt(_ work: @escaping () throws -> Int) {
        Promise<Int>(on: .global(), work).then { result in
            print(result)
        }


//        let result = Promise<Int>(on: .global()) { work }.catch { error in print(error) }
//        result.then { it in
//            print(it)
//        }
    }

}
