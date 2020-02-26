//
//  XYGPSBluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XYGPSBluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = XYGPSBluetoothDevice.uuid
    public var family: XYDeviceFamily = XYGPSBluetoothDevice.family

    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XYGPSBluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XYGPSBluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XYGPSBluetoothDeviceCreator.uuid, creator: XYGPSBluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XYGPSBluetoothDeviceCreator.uuid)
        }
    }
}
