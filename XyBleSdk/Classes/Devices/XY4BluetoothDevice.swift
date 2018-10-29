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
public class XY4BluetoothDevice: XYFinderDeviceBase {

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(.xy4, id: id, iBeacon: iBeacon, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy4), iBeacon: iBeacon, rssi: rssi)
    }

    public override var connectableServices: [CBUUID] {
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

    public override func subscribeToButtonPress() {
        self.subscribe(to: PrimaryService.buttonState, delegate: (self.id, self))
    }

    public override func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
        return self.unsubscribe(from: PrimaryService.buttonState, key: referenceKey?.uuidString ?? self.id)
    }

    @discardableResult public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(PrimaryService.buzzer, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public override func stayAwake() -> XYBluetoothResult {
        return self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult public override func isAwake() -> XYBluetoothResult {
        return self.get(PrimaryService.stayAwake)
    }

    @discardableResult public override func fallAsleep() -> XYBluetoothResult {
        return self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult public override func lock() -> XYBluetoothResult {
        return self.set(PrimaryService.lock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public override func unlock() -> XYBluetoothResult {
        return self.set(PrimaryService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public override func version() -> XYBluetoothResult {
        return self.get(DeviceInformationService.firmwareRevisionString)
    }
}
