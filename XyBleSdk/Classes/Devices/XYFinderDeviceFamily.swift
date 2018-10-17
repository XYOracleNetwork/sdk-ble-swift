//
//  XYFinderDeviceFamily.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

// Defines the various XY devices supported by this SDK
public enum XYFinderDeviceFamily: Int {
    case unknown
    case xy1
    case xy2
    case xy3
    case xy4
    case xymobile
    case xygps
    case xynear

    public static func get(from iBeacon: XYIBeaconDefinition) -> XYFinderDeviceFamily? {
        return XYFinderDeviceFamily.get(from: iBeacon.uuid.uuidString)
    }

    public static func get(from uuidString: String) -> XYFinderDeviceFamily? {
        guard let index = XYFinderDeviceFamily.uuids.index(of: uuidString.lowercased()) else { return nil }
        return XYFinderDeviceFamily(rawValue: index)
    }

    public var uuid: UUID {
        return UUID(uuidString: XYFinderDeviceFamily.uuids[self.rawValue])!
    }

    public var prefix: String {
        switch self {
        case .xy1, .xy2, .xy3, .xy4: return "xy:ibeacon"
        case .xymobile: return "xy:mobiledevice"
        case .xygps: return "xy:gps"
        case .xynear: return "xy:near"
        case .unknown: return "unknown"
        }
    }

    public var connectableSourceUuid: NSUUID? {
        switch self {
        case .xy4: return NSUUID(uuidString: "00000000-785F-0000-0000-0401F4AC4EA4")
        default: return NSUUID(uuidString: XYFinderDeviceFamily.xy1.uuid.uuidString)
        }
    }

    public var lockCode: Data {
        switch self {
        case .xy4: return XYFinderDeviceFamily.lockXy4
        default: return XYFinderDeviceFamily.lockDefault
        }
    }

    public var familyName: String {
        switch self {
        case .xy1: return "XY1 Finder"
        case .xy2: return "XY2 Finder"
        case .xy3: return "XY3 Finder"
        case .xy4: return "XY4 Finder"
        case .xygps: return "XY-GPS Finder"
        case .xymobile: return "Mobile Device"
        case .xynear: return "XY-Near Finder"
        case .unknown: return "Unknown"
        }
    }

    private static let uuids = [
        "", // unknown
        "a500248c-abc2-4206-9bd7-034f4fc9ed10", // xy1
        "07775dd0-111b-11e4-9191-0800200c9a66", // xy2
        "08885dd0-111b-11e4-9191-0800200c9a66", // xy3
        "a44eacf4-0104-0000-0000-5f784c9977b5", // xy4
        "735344c9-e820-42ec-9da7-f43a2b6802b9", // xymobile
        "9474f7c6-47a4-11e6-beb8-9e71128cae77", // xygps
        "00000000-0000-0000-0000-000000000000"  // xynear
    ]

    public static let powerLow: UInt8 = 0x04
    public static let powerHigh: UInt8 = 0x08

    fileprivate static let lockDefault = Data([0x2f, 0xbe, 0xa2, 0x07, 0x52, 0xfe, 0xbf, 0x31, 0x1d, 0xac, 0x5d, 0xfa, 0x7d, 0x77, 0x76, 0x80])
    fileprivate static let lockXy4 = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f])

    public static let values: [XYFinderDeviceFamily] = [unknown, xy1, xy2, xy3, xy4, xymobile, xygps, xynear]
}
