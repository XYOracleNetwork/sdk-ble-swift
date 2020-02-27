//
//  XY2BluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation


public struct XY2BluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = XY2BluetoothDevice.uuid
    public var family: XYDeviceFamily = XY2BluetoothDevice.family
    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XY2BluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XY2BluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XY2BluetoothDeviceCreator.uuid, creator: XY2BluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XY2BluetoothDeviceCreator.uuid)
        }
    }
}
