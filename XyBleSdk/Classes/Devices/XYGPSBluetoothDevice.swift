//
//  XYGPSBluetoothDevice.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth
import Promises

// The XYGPS-specific implementation
public class XYGPSBluetoothDevice: XYFinderDeviceBase {

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(.xygps, id: id, iBeacon: iBeacon, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xygps), iBeacon: iBeacon, rssi: rssi)
    }

}

extension XYGPSBluetoothDevice {

    @discardableResult public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public func version() -> XYBluetoothResult {
        return self.get(ControlService.version)
    }

}
