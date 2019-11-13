//
//  XyoBridgeXDeviceCreator.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 4/9/19.
//

import Foundation
import XyBleSdk

public struct XyoBridgeXDeviceCreator : XyoManufactorDeviceCreator {
    public init () {}
    
    public func createFromIBeacon(iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XyoBridgeXDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func enable (enable : Bool) {
        if (enable) {
            XyoBluetoothDeviceCreator.manufactorMap[0x03] = XyoBridgeXDeviceCreator()
        } else {
            XyoBluetoothDeviceCreator.manufactorMap.removeValue(forKey: 0x03)
        }
    }
}
