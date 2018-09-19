//
//  PrimaryService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum PrimaryService: String, ServiceCharacteristic {

    public var serviceUuid: CBUUID { return PrimaryService.serviceUuid }

    case stayAwake
    case unlock
    case lock
    case major
    case minor
    case uuid
    case buttonState
    case buzzer
    case buzzerConfig
    case adConfig
    case buttonConfig
    case lastError
    case uptime
    case reset
    case selfTest
    case debug
    case leftBehind
    case eddystoneUID
    case eddystoneURL
    case eddystoneEID
    case color
    case hardwareCreateDate

    private static let serviceUuid = CBUUID(string: "a44eacf4-0104-0001-0000-5f784c9977b5")

    public var characteristicUuid: CBUUID {
        return PrimaryService.uuids[self]!
    }

    public var characteristicType: GattCharacteristicType { return .string }

    private static let uuids: [PrimaryService: CBUUID] = [
        .stayAwake          : CBUUID(string: "a44eacf4-0104-0001-0001-5f784c9977b5"),
        .unlock             : CBUUID(string: "a44eacf4-0104-0001-0002-5f784c9977b5"),
        .lock               : CBUUID(string: "a44eacf4-0104-0001-0003-5f784c9977b5"),
        .major              : CBUUID(string: "a44eacf4-0104-0001-0004-5f784c9977b5"),
        .minor              : CBUUID(string: "a44eacf4-0104-0001-0005-5f784c9977b5"),
        .uuid               : CBUUID(string: "a44eacf4-0104-0001-0006-5f784c9977b5"),
        .buttonState        : CBUUID(string: "a44eacf4-0104-0001-0007-5f784c9977b5"),
        .buzzer             : CBUUID(string: "a44eacf4-0104-0001-0008-5f784c9977b5"),
        .buzzerConfig       : CBUUID(string: "a44eacf4-0104-0001-0009-5f784c9977b5"),
        .adConfig           : CBUUID(string: "a44eacf4-0104-0001-000a-5f784c9977b5"),
        .buttonConfig       : CBUUID(string: "a44eacf4-0104-0001-000b-5f784c9977b5"),
        .lastError          : CBUUID(string: "a44eacf4-0104-0001-000c-5f784c9977b5"),
        .uptime             : CBUUID(string: "a44eacf4-0104-0001-000d-5f784c9977b5"),
        .reset              : CBUUID(string: "a44eacf4-0104-0001-000e-5f784c9977b5"),
        .selfTest           : CBUUID(string: "a44eacf4-0104-0001-000f-5f784c9977b5"),
        .debug              : CBUUID(string: "a44eacf4-0104-0001-0010-5f784c9977b5"),
        .leftBehind         : CBUUID(string: "a44eacf4-0104-0001-0011-5f784c9977b5"),
        .eddystoneUID       : CBUUID(string: "a44eacf4-0104-0001-0012-5f784c9977b5"),
        .eddystoneURL       : CBUUID(string: "a44eacf4-0104-0001-0013-5f784c9977b5"),
        .eddystoneEID       : CBUUID(string: "a44eacf4-0104-0001-0014-5f784c9977b5"),
        .color              : CBUUID(string: "a44eacf4-0104-0001-0015-5f784c9977b5"),
        .hardwareCreateDate : CBUUID(string: "a44eacf4-0104-0001-0017-5f784c9977b5")
    ]
}
