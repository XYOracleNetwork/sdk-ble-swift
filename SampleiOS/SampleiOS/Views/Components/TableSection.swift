//
//  TableSection.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XyBleSdk

enum TableSection: Int {
    case xy1 = 0, xy2, xy3, xy4, xyMobile, xyGps

    var title: String {
        switch self {
        case .xy1: return "XY1"
        case .xy2: return XY2BluetoothDevice.familyName
        case .xy3: return XY3BluetoothDevice.familyName
        case .xy4: return XY4BluetoothDevice.familyName
        case .xyMobile: return XYMobileBluetoothDevice.familyName
        case .xyGps: return XYGPSBluetoothDevice.familyName
        }
    }

    static let values = [xy1, xy2, xy3, xy4, xyMobile, xyGps]
}

extension XYDeviceFamily {

    var toTableSection: TableSection? {
        switch self.id {
        case XY2BluetoothDevice.id: return TableSection.xy2
        case XY3BluetoothDevice.id: return TableSection.xy3
        case XY4BluetoothDevice.id: return TableSection.xy4
        case XYMobileBluetoothDevice.id: return TableSection.xyMobile
        case XYGPSBluetoothDevice.id: return TableSection.xyGps
        default: return nil
        }
    }
}
