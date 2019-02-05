//
//  XYGPSBluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/2/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import Promises

// The XYGPS-specific implementation
public class XYGPSBluetoothDevice: XYFinderDeviceBase {
    private static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XYGPSBluetoothDevice.uuid)!,
                                                    prefix: XYGPSBluetoothDevice.prefix,
                                                    familyName: XYGPSBluetoothDevice.familyName,
                                                    id: XYGPSBluetoothDevice.id)
    
    public static let id = "GPS"
    public static let uuid : String = "9474f7c6-47a4-11e6-beb8-9e71128cae77"
    public static let familyName : String = "XY-GPS Finder"
    public static let prefix : String = "xy:gps"

    public var activated = false

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(XYGPSBluetoothDevice.family, id: id, iBeacon: iBeacon, rssi: rssi)
        super.shouldCheckForButtonPressOnDetection = true
    }

    public override func subscribeToButtonPress() -> XYBluetoothResult {
        return self.subscribe(to: ControlService.button, delegate: (self.id, self))
    }

    public override func unsubscribeToButtonPress(for referenceKey: UUID?) -> XYBluetoothResult {
        return self.unsubscribe(from: ControlService.button, key: referenceKey?.uuidString ?? self.id)
    }

    @discardableResult
    public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult
    public override func version() -> XYBluetoothResult {
        return self.get(ControlService.version)
    }

    @discardableResult
    public override func stayAwake() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult
    public override func fallAsleep() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult
    public override func lock() -> XYBluetoothResult {
        return self.set(BasicConfigService.lock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_DEFAULT))
    }

    @discardableResult
    public override func unlock() -> XYBluetoothResult {
        return self.set(BasicConfigService.unlock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_DEFAULT))
    }

}
