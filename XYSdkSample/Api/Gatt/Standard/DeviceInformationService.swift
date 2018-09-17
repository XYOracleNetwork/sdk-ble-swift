//
//  DeviceInformationService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/12/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum DeviceInformationService: String, ServiceCharacteristic {

    public var serviceUuid: CBUUID { return DeviceInformationService.serviceUuid }

    case systemId
    case firmwareRevisionString
    case modelNumberString
    case serialNumberString
    case hardwareRevisionString
    case softwareRevisionString
    case manufacturerNameString

    public var characteristicUuid: CBUUID {
        return DeviceInformationService.uuids[self]!
    }

    public var characteristicType: GattCharacteristicType {
        switch self {
        case .systemId:
            return .integer
        case .firmwareRevisionString, .hardwareRevisionString, .manufacturerNameString, .modelNumberString, .serialNumberString, .softwareRevisionString:
            return .string
        }
    }

    private static let serviceUuid = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")

    private static let uuids: [DeviceInformationService: CBUUID] = [
        .systemId: CBUUID(string: "00002a23-0000-1000-8000-00805f9b34fb"),
        .firmwareRevisionString: CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb"),
        .modelNumberString: CBUUID(string: "00002a24-0000-1000-8000-00805f9b34fb"),
        .serialNumberString: CBUUID(string: "00002a25-0000-1000-8000-00805f9b34fb"),
        .hardwareRevisionString: CBUUID(string: "00002a27-0000-1000-8000-00805f9b34fb"),
        .softwareRevisionString: CBUUID(string: "00002a28-0000-1000-8000-00805f9b34fb"),
        .manufacturerNameString: CBUUID(string: "00002a29-0000-1000-8000-00805f9b34fb")
    ]
}
