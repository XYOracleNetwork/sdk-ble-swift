//
//  XYDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public protocol XYDeviceCreator {
    func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice?
    func createFromId (id: String) -> XYBluetoothDevice
    var family : XYDeviceFamily { get }
}
