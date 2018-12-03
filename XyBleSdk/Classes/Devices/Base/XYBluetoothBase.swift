//
//  XYBluetoothBase.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

// Basic protocol for all BLE devices 
public protocol XYBluetoothBase {
    var rssi: Int { get set }
    var powerLevel: UInt8 { get set }
    var name: String { get }
    var id: String { get }

    var lastPulseTime: Date? { get set }
    var totalPulseCount: Int { get }
    var lastMonitoredTime: Date? { get set }

    var proximity: XYDeviceProximity { get }

    func update(_ rssi: Int, powerLevel: UInt8)
    func resetRssi()

    var supportedServices: [CBUUID] { get }
}

public extension XYBluetoothBase {
    var proximity: XYDeviceProximity {
        return XYDeviceProximity.fromSignalStrength(self.rssi)
    }
}

public func ==(lhs: XYBluetoothBase, rhs: XYBluetoothBase) -> Bool {
    return lhs.id == rhs.id
}
