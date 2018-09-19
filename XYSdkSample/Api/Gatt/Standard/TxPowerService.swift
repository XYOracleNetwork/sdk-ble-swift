//
//  TxPowerService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/19/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum TxPowerService: String, ServiceCharacteristic {

    public var serviceUuid: CBUUID { return TxPowerService.serviceUuid }

    case txPowerLevel

    public var characteristicUuid: CBUUID {
        return TxPowerService.uuids[self]!
    }

    public var characteristicType: GattCharacteristicType {
        return .integer
    }

    private static let serviceUuid = CBUUID(string: "00001800-0000-1000-8000-00805F9B34FB")

    private static let uuids: [TxPowerService: CBUUID] = [
        .txPowerLevel: CBUUID(string: "00002a07-0000-1000-8000-00805f9b34fb")
    ]
}
