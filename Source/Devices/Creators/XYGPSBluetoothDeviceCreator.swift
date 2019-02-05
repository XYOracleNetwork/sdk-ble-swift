//
//  XYGPSBluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

struct XYGPSBluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = "9474f7c6-47a4-11e6-beb8-9e71128cae77"
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
