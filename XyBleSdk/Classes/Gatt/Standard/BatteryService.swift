//
//  BatteryService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/14/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum BatteryService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return BatteryService.serviceUuid }

    case level

    public var characteristicUuid: CBUUID {
        return BatteryService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        return "Battery Level"
    }

    private static let serviceUuid = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")

    private static let uuids: [BatteryService: CBUUID] = [
        .level: CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        level
    ]
}
