//
//  XY2BluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/2/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY2-specific implementation
public class XY2BluetoothDevice: XYFinderDeviceBase {
    static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XY2BluetoothDevice.uuid)!,
                                             prefix: XY2BluetoothDevice.prefix,
                                             familyName: XY2BluetoothDevice.familyName,
                                             id: XY2BluetoothDevice.id)
    
    public static let id = "XY2"
    public static let uuid : String = "07775dd0-111b-11e4-9191-0800200c9a66"
    public static let familyName : String = "XY2 Finder"
    public static let prefix : String = "xy:ibeacon"

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(XY2BluetoothDevice.family, id: id, iBeacon: iBeacon, rssi: rssi)
    }
    
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XY2BluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }
    
    @discardableResult
    public override func isAwake() -> XYBluetoothResult {
        return XYBluetoothResult(data: Data([0x01]))
    }

    @discardableResult
    public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult
    public override func unlock() -> XYBluetoothResult {
        return XYBluetoothResult.init(data: nil)
    }
    
    @discardableResult
    public override func version() -> XYBluetoothResult {
        self.firmware = "2.0"
        return XYBluetoothResult(data: self.firmware.data(using: .utf8))
    }
}
