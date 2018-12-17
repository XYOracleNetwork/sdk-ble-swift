//
//  GenericAttributeService.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public enum GenericAttributeService: String, XYServiceCharacteristic {

    public var serviceDisplayName: String { return "Generic Attribute" }
    public var serviceUuid: CBUUID { return GenericAttributeService.serviceUuid }

    case serviceChanged

    public var characteristicUuid: CBUUID {
        return GenericAttributeService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        return "Service Changed"
    }

    private static let serviceUuid = CBUUID(string: "00001801-0000-1000-8000-00805F9B34FB")

    private static let uuids: [GenericAttributeService: CBUUID] = [
        .serviceChanged : CBUUID(string: "00002a05-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        serviceChanged
    ]
}
