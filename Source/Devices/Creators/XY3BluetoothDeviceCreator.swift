//
//  XY3BluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XY3BluetoothDeviceCreator : XYDeviceCreator {
    private init () {}
    
    public static let uuid : String = XY3BluetoothDevice.uuid
    public var family: XYDeviceFamily = XY3BluetoothDevice.family
    
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XY3BluetoothDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XY3BluetoothDevice(id)
    }
    
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XY3BluetoothDeviceCreator.uuid, creator: XY3BluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XY3BluetoothDeviceCreator.uuid)
        }
    }
}
