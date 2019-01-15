//
//  SmartScanStatus.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XyBleSdk

extension XYSmartScanStatus {
    var toString: String {
        switch self {
        case .none: return "None"
        case .enabled: return "Enabled"
        case .bluetoothUnavailable: return "Bluetooth unavailable"
        case .bluetoothDisabled: return "Bluetooth disabled"
        case .backgroundLocationDisabled: return "Background location disabled"
        case .locationDisabled: return "Location disabled"
        }
    }
}
