//
//  XYBluetoothBase.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

// Basic protocol for all BLE devices 
public protocol XYBluetoothBase {
    var rssi: Int { get set }
    var name: String { get }
    var id: String { get }
    var totalPulseCount: Int { get }
}
