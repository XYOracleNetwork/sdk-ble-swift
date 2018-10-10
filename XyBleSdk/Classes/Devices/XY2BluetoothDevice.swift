//
//  XY2BluetoothDevice.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth
import Promises

// The XY2-specific implementation
public class XY2BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public fileprivate(set) var
    powerLevel: UInt8 = 4

    public let family: XYFinderDeviceFamily = .xy2

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy2), iBeacon: iBeacon, rssi: rssi)
    }
}

extension XY2BluetoothDevice: XYFinderDevice {

    public func update(_ rssi: Int, powerLevel: UInt8) {
        super.detected(rssi)
        self.powerLevel = powerLevel
    }

    @discardableResult public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

}
