//
//  XYConstants.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation

internal struct XYConstants {
    static let DEVICE_TUNING_SECONDS_INTERVAL_CONNECTED_RSSI_READ = 3
    static let DEVICE_TUNING_LOCATION_CHANGE_THRESHOLD = 10.0
    static let DEVICE_TUNING_SECONDS_EXIT_CHECK_INTERVAL = 1.0
    static let DEVICE_TUNING_SECONDS_WITHOUT_SIGNAL_FOR_EXITING = 12.0

    static let DEVICE_TUNING_SECONDS_WITHOUT_SIGNAL_FOR_EXIT_GAP_SIZE = 2.0
    static let DEVICE_TUNING_SECONDS_WITHOUT_SIGNAL_FOR_EXIT_WINDOW_COUNT = 3
    static let DEVICE_TUNING_SECONDS_WITHOUT_SIGNAL_FOR_EXIT_WINDOW_SIZE = 2.5
}

public enum XYDeviceProximity: Int {
    case none
    case outOfRange
    case veryFar
    case far
    case medium
    case near
    case veryNear
    case touching

    public static func fromSignalStrength(_ strength: Int) -> XYDeviceProximity {
        if strength == -999 { return XYDeviceProximity.none }
        if strength >= -40 { return XYDeviceProximity.touching }
        if strength >= -60 { return XYDeviceProximity.veryNear }
        if strength >= -70 { return XYDeviceProximity.near }
        if strength >= -80 { return XYDeviceProximity.medium }
        if strength >= -90 { return XYDeviceProximity.far }
        if strength >= -200 { return XYDeviceProximity.veryFar }
        return XYDeviceProximity.outOfRange
    }

    public static let defaultProximity: Int = -999
}

public enum XYButtonType2 : Int {
    case none
    case single
    case double
    case long
}

public enum XYFinderSong {
    case off
    case findIt

    public func values(for device: XYFinderDeviceFamily) -> [UInt8] {
        switch self {
        case .off:
            switch device {
            case .xy4:
                return [0xff, 0x03]
            case .xy1:
                return [0x01]
            default:
                return [0xff]
            }
        case .findIt:
            switch device {
            case .xy4:
                return [0x0b, 0x03]
            case .xy2:
                return [0x01]
            case .xy1:
                return [0x01]
            default:
                return [0x02]
            }
        }

    }
}

// A generic semaphore lock with configurable lock amounts and timeout
internal class GenericLock {

    // Default 5 minute wait time
    private static let genericLockTimeout: TimeInterval = 300

    private let
    semaphore: DispatchSemaphore,
    waitTimeout: TimeInterval

    init(_ value: Int = 1, timeout: TimeInterval = GenericLock.genericLockTimeout) {
        self.semaphore = DispatchSemaphore(value: value)
        self.waitTimeout = timeout
    }

    public func lock() {
        if self.semaphore.wait(timeout: .now() + self.waitTimeout) == .timedOut {
            self.unlock()
        }
    }

    public func unlock() {
        self.semaphore.signal()
    }

}
