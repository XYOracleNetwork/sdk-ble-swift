//
//  XYConstants.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

internal struct XYConstants {
    static let DEVICE_TUNING_SECONDS_INTERVAL_CONNECTED_RSSI_READ = 3
    static let DEVICE_TUNING_LOCATION_CHANGE_THRESHOLD = 10.0
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
