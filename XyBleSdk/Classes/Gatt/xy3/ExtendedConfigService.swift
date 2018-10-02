//
//  ExtendedConfigService.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth

public enum ExtendedConfigService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return ExtendedConfigService.serviceUuid }

    case virtualBeaconSettings
    case tone
    case registration
    case inactiveVirtualBeaconSettings
    case inactiveInterval
    case gpsInterval
    case gpsMode
    case simId

    private static let serviceUuid = CBUUID(string: "F014FF00-0439-3000-E001-00001001FFFF")

    public var characteristicUuid: CBUUID {
        return ExtendedConfigService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        switch self {
        case .virtualBeaconSettings: return "Virtual Beacon Settings"
        case .tone: return "Tone"
        case .registration: return "Registration"
        case .inactiveVirtualBeaconSettings: return "Inactive Virtual Beacon Settings"
        case .inactiveInterval: return "Inactive Interval"
        case .gpsInterval: return "GPS Interval"
        case .gpsMode: return "GPS Mode"
        case .simId: return "SIM Id"
        }
    }

    private static let uuids: [ExtendedConfigService: CBUUID] = [
        virtualBeaconSettings : CBUUID(string: "F014FF02-0439-3000-E001-00001001FFFF"),
        tone : CBUUID(string: "F014FF03-0439-3000-E001-00001001FFFF"),
        registration : CBUUID(string: "F014FF05-0439-3000-E001-00001001FFFF"),
        inactiveVirtualBeaconSettings : CBUUID(string: "F014FF06-0439-3000-E001-00001001FFFF"),
        inactiveInterval : CBUUID(string: "F014FF07-0439-3000-E001-00001001FFFF"),
        gpsInterval : CBUUID(string: "2ABBAA00-0439-3000-E001-00001001FFFF"),
        gpsMode : CBUUID(string: "2A99AA00-0439-3000-E001-00001001FFFF"),
        simId : CBUUID(string: "2ACCAA00-0439-3000-E001-00001001FFFF")
    ]

    public static var values: [XYServiceCharacteristic] = [
        virtualBeaconSettings, tone, registration, inactiveVirtualBeaconSettings, inactiveInterval, gpsInterval, gpsMode, simId
    ]
}
