//
//  XYMobileBluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XYMobileBluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = "735344c9-e820-42ec-9da7-f43a2b6802b9"
    public var family: XYDeviceFamily = XYMobileBluetoothDevice.family
    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XYMobileBluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XYMobileBluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XYMobileBluetoothDeviceCreator.uuid, creator: XYMobileBluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XYMobileBluetoothDeviceCreator.uuid)
        }
    }
}
