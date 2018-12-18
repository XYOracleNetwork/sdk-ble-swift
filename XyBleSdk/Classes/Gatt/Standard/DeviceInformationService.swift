//
//  DeviceInformationService.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/12/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public enum DeviceInformationService: String, XYServiceCharacteristic {

    public var serviceDisplayName: String { return "Device Information" }
    public var serviceUuid: CBUUID { return DeviceInformationService.serviceUuid }

    case systemId
    case firmwareRevisionString
    case modelNumberString
    case serialNumberString
    case hardwareRevisionString
    case softwareRevisionString
    case manufacturerNameString
    case ieeeRegulatoryCertificationDataList
    case pnpId

    public var characteristicUuid: CBUUID {
        return DeviceInformationService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        switch self {
        case .systemId, .ieeeRegulatoryCertificationDataList, .pnpId:
            return .integer
        case .firmwareRevisionString, .hardwareRevisionString, .manufacturerNameString, .modelNumberString, .serialNumberString, .softwareRevisionString:
            return .string
        }
    }

    public var displayName: String {
        switch self {
        case .systemId: return "System Id"
        case .firmwareRevisionString: return "Firmware Revision"
        case .modelNumberString: return "Model Number"
        case .serialNumberString: return "Serial Number"
        case .hardwareRevisionString: return "Hardware Revision"
        case .softwareRevisionString: return "Software Revision"
        case .manufacturerNameString: return "Manufacturer Name"
        case .ieeeRegulatoryCertificationDataList: return "IEEE Regulatory Certification Data List"
        case .pnpId: return "PnP Id"
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
        .manufacturerNameString: CBUUID(string: "00002a29-0000-1000-8000-00805f9b34fb"),
        .ieeeRegulatoryCertificationDataList: CBUUID(string: "00002a2a-0000-1000-8000-00805f9b34fb"),
        .pnpId: CBUUID(string: "00002a50-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        systemId, firmwareRevisionString, modelNumberString, serialNumberString, hardwareRevisionString, softwareRevisionString, manufacturerNameString, ieeeRegulatoryCertificationDataList, pnpId
    ]
}
