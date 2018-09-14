//
//  XY4BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

public class XY4BluetoothDevice: XYBluetoothDevice, XYFinderDevice {

    public let
    iBeacon: XYIBeaconDefinition?

    public let family: XYFinderDeviceFamily = .xy4

    public final var name: String { return family.familyName }
    public final var prefix: String { return family.prefix }

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil) {
        self.iBeacon = iBeacon
        super.init(family.uuid, id: id)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition) {
        self.init(iBeacon.xyId(from: .xy4), iBeacon: iBeacon)
    }

    public var proximity: XYDeviceProximity = .none
    public var services: [ServiceCharacteristic] = []

    override public var powerLevel: UInt8 {
        guard
            let beacon = self.iBeacon,
            let minor = beacon.minor
            else { return super.powerLevel }
        return UInt8(minor & 0xf)
    }

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid(_ connectablePowerLevel: UInt8) -> CBUUID {
            let uuidSource = NSUUID(uuidString: "00000000-785F-0000-0000-0401F4AC4EA4")
            let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uuidSource?.getBytes(uuidBytes)

            uuidBytes[2] = UInt8(major & 0x00ff)
            uuidBytes[3] = UInt8((major & 0xff00) >> 8)
            uuidBytes[0] = UInt8(minor & 0x00f0) | connectablePowerLevel
            uuidBytes[1] = UInt8((minor & 0xff00) >> 8)

            return CBUUID(data: Data(bytes:uuidBytes, count:16))
        }

        return [0x04, 0x08].map { getServiceUuid($0) }
    }
}
