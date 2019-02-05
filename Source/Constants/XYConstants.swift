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
    
    static let DEVICE_POWER_LOW: UInt8 = 0x04
    static let DEVICE_POWER_HIGH: UInt8 = 0x08
    static let DEVICE_LOCK_DEFAULT = Data([0x2f, 0xbe, 0xa2, 0x07, 0x52, 0xfe, 0xbf, 0x31, 0x1d, 0xac, 0x5d, 0xfa, 0x7d, 0x77, 0x76, 0x80])
    static let DEVICE_LOCK_XY4 = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])
    
    static let DEVICE_CONNECTABLE_SOURCE_UUID_XY4 =  NSUUID(uuidString: "00000000-785F-0000-0000-0401F4AC4EA4")
    static let DEVICE_CONNECTABLE_SOURCE_UUID_DEFAULT =  NSUUID(uuidString: "a500248c-abc2-4206-9bd7-034f4fc9ed10")
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

    public func values(for device: XYDeviceFamily) -> [UInt8] {
        switch self {
        case .off:
            switch device.id {
            case XY4BluetoothDevice.id:
                return [0xff, 0x03]
//            case .xy1:
//                return [0x01]
            default:
                return [0xff]
            }
        case .findIt:
            switch device.id {
            case XY4BluetoothDevice.id:
                return [0x0b, 0x03]
            case XY2BluetoothDevice.id:
                return [0x01]
//            case .xy1:
//                return [0x01]
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
