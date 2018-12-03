//
//  BasicConfigService.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public enum BasicConfigService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return BasicConfigService.serviceUuid }

    case lockStatus
    case lock
    case unlock
    case uuid
    case major
    case minor
    case interval
    case otaWrite
    case reboot

    private static let serviceUuid = CBUUID(string: "F014EE00-0439-3000-E001-00001001FFFF")

    public var characteristicUuid: CBUUID {
        return BasicConfigService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        switch self {
        case .lockStatus, .major, .minor, .reboot:
            return .integer
        default:
            return .byte
        }
    }

    public var displayName: String {
        switch self {
        case .lockStatus: return "Lock Status"
        case .lock: return "Lock"
        case .unlock: return "Unlock"
        case .uuid: return "UUID"
        case .major: return "Major"
        case .minor: return "Minor"
        case .interval: return "Interval"
        case .otaWrite: return "OTA Write"
        case .reboot: return "Reboot"
        }
    }

    private static let uuids: [BasicConfigService: CBUUID] = [
        lockStatus      : CBUUID(string: "F014EE01-0439-3000-E001-00001001FFFF"),
        lock            : CBUUID(string: "F014EE02-0439-3000-E001-00001001FFFF"),
        unlock          : CBUUID(string: "F014EE03-0439-3000-E001-00001001FFFF"),
        uuid            : CBUUID(string: "F014EE04-0439-3000-E001-00001001FFFF"),
        major           : CBUUID(string: "F014EE05-0439-3000-E001-00001001FFFF"),
        minor           : CBUUID(string: "F014EE06-0439-3000-E001-00001001FFFF"),
        interval        : CBUUID(string: "F014EE07-0439-3000-E001-00001001FFFF"),
        otaWrite        : CBUUID(string: "F014EE09-0439-3000-E001-00001001FFFF"),
        reboot          : CBUUID(string: "F014EE0A-0439-3000-E001-00001001FFFF")
    ]

    public static var values: [XYServiceCharacteristic] = [
        lockStatus, lock, unlock, uuid, major, minor, interval, otaWrite, reboot
    ]
}
