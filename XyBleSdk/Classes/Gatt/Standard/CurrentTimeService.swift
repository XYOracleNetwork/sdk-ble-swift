//
//  CurrentTimeService.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public enum CurrentTimeService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return CurrentTimeService.serviceUuid }

    case currentTime
    case localTimeInformation
    case referenceTimeInformation

    public var characteristicUuid: CBUUID {
        return CurrentTimeService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        switch self {
        case.currentTime: return "Current Time"
        case .localTimeInformation: return "Local Time Information"
        case .referenceTimeInformation: return "Reference Time Information"
        }
    }

    private static let serviceUuid = CBUUID(string: "00001805-0000-1000-8000-00805F9B34FB")

    private static let uuids: [CurrentTimeService: CBUUID] = [
        .currentTime : CBUUID(string: "00002a2b-0000-1000-8000-00805f9b34fb"),
        .localTimeInformation : CBUUID(string: "00002a0f-0000-1000-8000-00805f9b34fb"),
        .referenceTimeInformation : CBUUID(string: "00002a14-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        currentTime, localTimeInformation, referenceTimeInformation
    ]
}
