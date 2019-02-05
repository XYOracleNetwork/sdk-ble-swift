//
//  XY4BluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

struct XY4BluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = "08885dd0-111b-11e4-9191-0800200c9a66"
    public var familyName : String = "XY4 Finder"
    public var prefix : String = "xy:ibeacon"
    
    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XY4BluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XY4BluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XY4BluetoothDeviceCreator.uuid, creator: XY4BluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XY4BluetoothDeviceCreator.uuid)
        }
    }
}
