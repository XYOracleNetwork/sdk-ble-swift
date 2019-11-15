//
//  XyoManufactorDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 3/5/19.
//

import Foundation

public protocol XyoManufactorDeviceCreator {
    func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice?
}
