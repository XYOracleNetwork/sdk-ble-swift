//
//  OtaService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum OtaService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return OtaService.serviceUuid }

    case memDev
    case gpioMap
    case memInfo
    case patchLen
    case patchData
    case servStatus

    public var characteristicUuid: CBUUID {
        return OtaService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        switch self {
        case .memDev: return "memDev"
        case .gpioMap: return "gpioMap"
        case .memInfo: return "memInfo"
        case .patchLen: return "patchLen"
        case .patchData: return "patchData"
        case .servStatus: return "servStatus"
        }
    }

    private static let serviceUuid = CBUUID(string: "0000fef5-0000-1000-8000-00805f9b34fb")

    private static let uuids: [OtaService: CBUUID] = [
        .memDev : CBUUID(string: "8082caa8-41a6-4021-91c6-56f9b954cc34"),
        .gpioMap : CBUUID(string: "724249f0-5eC3-4b5f-8804-42345af08651"),
        .memInfo : CBUUID(string: "6c53db25-47a1-45fe-a022-7c92fb334fd4"),
        .patchLen : CBUUID(string: "9d84b9a3-000c-49d8-9183-855b673fda31"),
        .patchData : CBUUID(string: "457871e8-d516-4ca1-9116-57d0b17b9cb2"),
        .servStatus : CBUUID(string: "5f78df94-798c-46f5-990a-b3eb6a065c88")
    ]

    public static var values: [XYServiceCharacteristic] = [
        memDev, gpioMap, memInfo, patchLen, patchData, servStatus
    ]
}
