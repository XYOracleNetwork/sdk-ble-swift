//
//  XYMobileBluetoothDevice.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/18/18.
//

import CoreBluetooth
import Promises

// The XY4-specific implementation
public class XYMobileBluetoothDevice: XYFinderDeviceBase {

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(.xymobile, id: id, iBeacon: iBeacon, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xymobile), iBeacon: iBeacon, rssi: rssi)
    }

    @discardableResult public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(PrimaryService.buzzer, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public override func stayAwake() -> XYBluetoothResult {
        return self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x01])))
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
