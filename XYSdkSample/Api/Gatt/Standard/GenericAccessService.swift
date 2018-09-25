//
//  GenericAccessService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/19/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//


import CoreBluetooth

public enum GenericAccessService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return GenericAccessService.serviceUuid }

    case deviceName
    case appearance
    case privacyFlag
    case reconnectionAddress
    case peripheralPreferredConnectionParameters

    public var characteristicUuid: CBUUID {
        return GenericAccessService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    private static let serviceUuid = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")

    private static let uuids: [GenericAccessService: CBUUID] = [
        .deviceName                                 : CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb"),
        .appearance                                 : CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb"),
        .privacyFlag                                : CBUUID(string: "00002a02-0000-1000-8000-00805f9b34fb"),
        .reconnectionAddress                        : CBUUID(string: "00002a03-0000-1000-8000-00805f9b34fb"),
        .peripheralPreferredConnectionParameters    : CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb")
    ]
}
