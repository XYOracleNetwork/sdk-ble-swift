//
//  XY3BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY3-specific implementation
public class XY3BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public fileprivate(set) var
    powerLevel: UInt8 = 4

    public let family: XYFinderDeviceFamily = .xy3

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy3), iBeacon: iBeacon, rssi: rssi)
    }

}

extension XY3BluetoothDevice: XYFinderDevice {

    public func update(_ rssi: Int, powerLevel: UInt8) {
        super.detected(rssi)
        self.powerLevel = powerLevel
    }

    @discardableResult public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public func stayAwake() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult public func fallAsleep() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult public func lock() -> XYBluetoothResult {
        return self.set(BasicConfigService.lock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public func unlock() -> XYBluetoothResult {
        return self.set(BasicConfigService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
    }

}
