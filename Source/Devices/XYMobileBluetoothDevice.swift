//
//  XYMobileBluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/18/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

// The XY4-specific implementation
public class XYMobileBluetoothDevice: XYFinderDeviceBase {
    public static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XYMobileBluetoothDevice.uuid)!,
                                                    prefix: XYMobileBluetoothDevice.prefix,
                                                    familyName: XYMobileBluetoothDevice.familyName,
                                                    id: XYMobileBluetoothDevice.id)
    
    public static let id = "MOBILE"
    public static let uuid : String = "735344c9-e820-42ec-9da7-f43a2b6802b9"
    public static let familyName : String = "Mobile Device"
    public static let prefix : String = "xy:mobiledevice"

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(XYMobileBluetoothDevice.family, id: id, iBeacon: iBeacon, rssi: rssi)
    }
    
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XYMobileBluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }

    @discardableResult
    public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(XYFinderPrimaryService.buzzer, value: XYBluetoothResult(data: songData))
    }

    @discardableResult
    public override func stayAwake() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult
    public override func fallAsleep() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult
    public override func lock() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.lock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_DEFAULT))
    }

    @discardableResult
    public override func unlock() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.unlock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_DEFAULT))
    }

    @discardableResult
    public override func version() -> XYBluetoothResult {
        return self.get(DeviceInformationService.firmwareRevisionString)
    }
}
