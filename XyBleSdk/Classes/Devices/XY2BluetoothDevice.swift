//
//  XY2BluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth
import Promises

// The XY2-specific implementation
public class XY2BluetoothDevice: XYFinderDeviceBase {

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(.xy2, id: id, iBeacon: iBeacon, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy2), iBeacon: iBeacon, rssi: rssi)
    }

    @discardableResult public override func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        let songData = Data(song.values(for: self.family))
        return self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: songData))
    }

    @discardableResult public override func unlock() -> XYBluetoothResult {
        return XYBluetoothResult.init(data: nil)
    }
}
