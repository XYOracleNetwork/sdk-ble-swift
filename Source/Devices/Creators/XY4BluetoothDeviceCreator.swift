//
//  XY4BluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XY4BluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = "a44eacf4-0104-0000-0000-5f784c9977b5"
    public var family: XYDeviceFamily = XY4BluetoothDevice.family
    
    
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
