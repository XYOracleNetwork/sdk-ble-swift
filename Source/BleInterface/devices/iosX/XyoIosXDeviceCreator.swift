//
//  XyoIosXDeviceCreator.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 4/9/19.
//

import Foundation
import XyBleSdk

public struct XyoIosXDeviceCreator : XyoManufactorDeviceCreator {
  public init () {}
  
  public func createFromIBeacon(iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
    return XyoIosXDevice(iBeacon: iBeacon, rssi: rssi)
  }
  
  public func enable (enable : Bool) {
    if (enable) {
      XyoBluetoothDeviceCreator.manufactorMap[0x02] = XyoIosXDeviceCreator()
    } else {
      XyoBluetoothDeviceCreator.manufactorMap.removeValue(forKey: 0x02)
    }
  }
}
