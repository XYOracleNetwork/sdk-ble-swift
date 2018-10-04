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
        super.detected()
        self.powerLevel = powerLevel
        self.rssi = rssi
    }

    @discardableResult public func find() -> Promise<Void>? {
        let song = Data(XYFinderSong.findIt.values(for: self.family))
        return self.connection {
            _ = self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: song))
        }
    }

    @discardableResult public func stayAwake() -> Promise<Void>? {
        return self.connection {
            _ = self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
        }
    }

    @discardableResult public func fallAsleep() -> Promise<Void>? {
        return self.connection {
            _ = self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x00])))
        }
    }

    @discardableResult public func lock() -> Promise<Void>? {
        return self.connection {
            _ = self.set(BasicConfigService.lock, value: XYBluetoothResult(data: self.family.lockCode))
        }
    }

    @discardableResult public func unlock() -> Promise<Void>? {
        return self.connection {
            _ = self.set(BasicConfigService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
        }
    }
}
