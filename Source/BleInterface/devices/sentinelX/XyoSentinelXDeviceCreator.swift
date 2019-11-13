//
//  XyoSentinelXDeviceCreator.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 3/5/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import XyBleSdk

public struct XyoSentinelXDeviceCreator : XyoManufactorDeviceCreator {
    public init () {}
    
    public func createFromIBeacon(iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        return XyoSentinelXDevice(iBeacon: iBeacon, rssi: rssi)
    }
    
    public func enable (enable : Bool) {
        if (enable) {
            XyoBluetoothDeviceCreator.manufactorMap[0x01] = XyoSentinelXDeviceCreator()
        } else {
            XyoBluetoothDeviceCreator.manufactorMap.removeValue(forKey: 0x01)
        }
    }
}
