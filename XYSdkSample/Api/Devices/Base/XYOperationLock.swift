//
//  XYBleOperationLock.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/24/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

internal class XYBleOperationLock {
    private static let lock = DispatchSemaphore(value: 1)

    private static let waitTimeout: TimeInterval = 30
    private static let callTimeout: TimeInterval = 30

    private static var timeoutHandler: DispatchWorkItem? = nil

    static func get() {
        if lock.wait(timeout: .now() + waitTimeout) == .timedOut {
            free()
            return
        }
    }

    static func free() {

    }
}
