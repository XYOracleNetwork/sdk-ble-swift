//
//  XY4BluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY4-specific implementation
public class XY4BluetoothDevice: XYFinderDeviceBase {
    static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XY4BluetoothDevice.uuid)!,
                                                    prefix: XY4BluetoothDevice.prefix,
                                                    familyName: XY4BluetoothDevice.familyName,
                                                    id: XY4BluetoothDevice.id)
    
    public static let id = "XY4"
    public static let uuid : String = "08885dd0-111b-11e4-9191-0800200c9a66"
    public static let familyName : String = "XY4 Finder"
    public static let prefix : String = "xy:ibeacon"
    
    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(XY4BluetoothDevice.family, id: id, iBeacon: iBeacon, rssi: rssi)
        super.shouldCheckForButtonPressOnDetection = true
    }
    
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XY4BluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }

    public override var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major else {
            return []
        }
        
        guard let minor = iBeacon?.minor else {
            return []
        }

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

        return [XYConstants.DEVICE_POWER_LOW, XYConstants.DEVICE_POWER_HIGH].map {
            getServiceUuid($0)
        }
    }

    @discardableResult
    public override func subscribeToButtonPress() -> XYBluetoothResult {
        return self.subscribe(to: XYFinderPrimaryService.buttonState, delegate: (self.id, self))
    }

    @discardableResult
    public override func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
        return self.unsubscribe(from: XYFinderPrimaryService.buttonState, key: referenceKey?.uuidString ?? self.id)
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
    public override func isAwake() -> XYBluetoothResult {
        return self.get(XYFinderPrimaryService.stayAwake)
    }

    @discardableResult
    public override func fallAsleep() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x00])))
    }

    @discardableResult
    public override func lock() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.lock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_XY4))
    }

    @discardableResult
    public override func unlock() -> XYBluetoothResult {
        return self.set(XYFinderPrimaryService.unlock, value: XYBluetoothResult(data: XYConstants.DEVICE_LOCK_XY4))
    }

    @discardableResult
    public override func version() -> XYBluetoothResult {
        return self.get(DeviceInformationService.firmwareRevisionString)
    }
}
