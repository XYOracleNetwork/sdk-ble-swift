//
//  XY4BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

public class XY4BluetoothDevice: XYBluetoothDeviceBase, XYFinderDevice {
    public let
    iBeacon: XYIBeaconDefinition?

    public let family: XYFinderDeviceFamily = .xy4

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy4), iBeacon: iBeacon, rssi: rssi)
    }

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid(_ connectablePowerLevel: UInt8) -> CBUUID {
            let uuidSource = family.connectableSourceUuid
            let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uuidSource?.getBytes(uuidBytes)

            uuidBytes[2] = UInt8(major & 0x00ff)
            uuidBytes[3] = UInt8((major & 0xff00) >> 8)
            uuidBytes[0] = UInt8(minor & 0x00f0) | connectablePowerLevel
            uuidBytes[1] = UInt8((minor & 0xff00) >> 8)

            return CBUUID(data: Data(bytes:uuidBytes, count:16))
        }

        return [XYFinderDeviceFamily.powerLow, XYFinderDeviceFamily.powerHigh].map { getServiceUuid($0) }
    }

}
