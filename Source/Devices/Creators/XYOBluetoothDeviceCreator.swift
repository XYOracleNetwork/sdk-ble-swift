//
//  XYOBluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/5/19.
//

import Foundation

public struct XYOBluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = XYOBluetoothDevice.uuid
    public var family: XYDeviceFamily = XYOBluetoothDevice.family
    
    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XYOBluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XYOBluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XYOBluetoothDevice.uuid, creator: XYOBluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XYOBluetoothDevice.uuid)
        }
    }
}
