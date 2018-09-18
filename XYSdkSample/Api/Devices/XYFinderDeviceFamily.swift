//
//  XYFinderDeviceFamily.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum XYFinderDeviceFamily: Int {
    case xy1 = 0
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
        if index != 3 { print("Finder Index: \(index)") }
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
        }
    }

    private static let uuids = [
        "a500248c-abc2-4206-9bd7-034f4fc9ed10", // xy1
        "07775dd0-111b-11e4-9191-0800200c9a66", // xy2
        "08885dd0-111b-11e4-9191-0800200c9a66", // xy3
        "a44eacf4-0104-0000-0000-5f784c9977b5", // xy4
        "735344c9-e820-42ec-9da7-f43a2b6802b9", // xymobile
        "9474f7c6-47a4-11e6-beb8-9e71128cae77", // xygps
        "00000000-0000-0000-0000-000000000000"  // xynear
    ]
}
