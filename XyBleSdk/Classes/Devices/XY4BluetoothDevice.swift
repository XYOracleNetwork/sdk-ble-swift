//
//  XY4BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY4-specific implementation
public class XY4BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public fileprivate(set) var
    powerLevel: UInt8 = 4

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

extension XY4BluetoothDevice: XYFinderDevice {

    // TODO deal with distance and keep connected
    public func update(_ rssi: Int, powerLevel: UInt8) {
        super.detected(rssi)
        self.powerLevel = powerLevel
        XYFinderDeviceEventManager.report(events: [
            .detected(device: self, powerLevel: Int(self.powerLevel), signalStrength: self.rssi, distance: 0),
            .updated(device: self)])
        if stayConnected && connected == false {
            self.connect()
        }
    }

    @discardableResult public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(PrimaryService.buzzer, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public func stayAwake() -> XYBluetoothResult {
        return self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult public func fallAsleep() -> XYBluetoothResult {
        return self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult public func lock() -> XYBluetoothResult {
        return self.set(PrimaryService.lock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public func unlock() -> XYBluetoothResult {
        return self.set(PrimaryService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public func version() -> XYBluetoothResult {
        return self.get(DeviceInformationService.firmwareRevisionString)
    }
}
