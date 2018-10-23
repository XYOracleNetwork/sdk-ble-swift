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
public class XY3BluetoothDevice: XYFinderDeviceBase {

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(.xy3, id: id, iBeacon: iBeacon, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy3), iBeacon: iBeacon, rssi: rssi)
    }

    public override func subscribeToButtonPress() {
        self.subscribe(to: ControlService.button, delegate: (self.id, self))
    }

    public override func unsubscribeToButtonPress(for referenceKey: UUID?) {
        guard let key = referenceKey?.uuidString else { return }
        self.unsubscribe(from: ControlService.button, key: key)
    }

    @discardableResult override public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public override func stayAwake() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult public override func fallAsleep() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult public override func lock() -> XYBluetoothResult {
        return self.set(BasicConfigService.lock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public override func unlock() -> XYBluetoothResult {
        return self.set(BasicConfigService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
    }

    @discardableResult public override func version() -> XYBluetoothResult {
        let result = self.get(ControlService.version)
        let version = result.data?.map { String($0, radix: 16) }.joined()
        return XYBluetoothResult(data: version?.data(using: .utf8))
    }

}
