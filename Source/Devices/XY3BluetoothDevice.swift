//
//  XY3BluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

// The XY3-specific implementation
public class XY3BluetoothDevice: XYFinderDeviceBase {
    public static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XY3BluetoothDevice.uuid)!,
                                                    prefix: XY3BluetoothDevice.prefix,
                                                    familyName: XY3BluetoothDevice.familyName,
                                                    id: XY3BluetoothDevice.id)
    
    public static let id = "XY3"
    public static let uuid : String = "08885dd0-111b-11e4-9191-0800200c9a66"
    public static let familyName : String = "XY3 Finder"
    public static let prefix : String = "xy:ibeacon"
    
    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(XY3BluetoothDevice.family, id: id, iBeacon: iBeacon, rssi: rssi)
        super.shouldCheckForButtonPressOnDetection = true
    }
    
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XY3BluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }

    public override func subscribeToButtonPress() -> XYBluetoothResult {
        return self.subscribe(to: ControlService.button, delegate: (self.id, self))
    }

    public override func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
        return self.unsubscribe(from: ControlService.button, key: referenceKey?.uuidString ?? self.id)
    }

    @discardableResult
    override public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult
    public override func stayAwake() -> XYBluetoothResult {
        return self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
    }

    @discardableResult
    public override func isAwake() -> XYBluetoothResult {
        return self.get(ExtendedConfigService.registration)
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

    @discardableResult
    public override func version() -> XYBluetoothResult {
        let result = self.get(ControlService.version)
        let version = result.data?.map { String($0, radix: 16) }.joined()
        return XYBluetoothResult(data: version?.data(using: .utf8))
    }

}
