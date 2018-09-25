//
//  XYBluetoothBase.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public protocol XYBluetoothBase {
    var rssi: Int { get }
    var name: String { get }
    var id: String { get }
}
