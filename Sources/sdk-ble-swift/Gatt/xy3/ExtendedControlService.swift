//
//  ExtendedControlService.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/23/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public enum ExtendedControlService: String, XYServiceCharacteristic {

    public var serviceDisplayName: String { return "Extended Control" }
    public var serviceUuid: CBUUID { return ExtendedControlService.serviceUuid }

    case simStatus
    case led
    case selfTest

    private static let serviceUuid = CBUUID(string: "F014AA00-0439-3000-E001-00001001FFFF")

    public var characteristicUuid: CBUUID {
        return ExtendedControlService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        switch self {
        case .simStatus: return "Sim Status"
        case .led: return "LED"
        case .selfTest: return "Self Test"
        }
    }

    private static let uuids: [ExtendedControlService: CBUUID] = [
        simStatus : CBUUID(string: "2ADDAA00-0439-3000-E001-00001001FFFF"),
        led : CBUUID(string: "2AAAAA00-0439-3000-E001-00001001FFFF"),
        selfTest : CBUUID(string: "2A77AA00-0439-3000-E001-00001001FFFF"),

    ]

    public static var values: [XYServiceCharacteristic] = [
        simStatus, led, selfTest
    ]
}
