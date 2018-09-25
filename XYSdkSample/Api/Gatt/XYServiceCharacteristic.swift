//
//  Service.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// Used for proper upacking of the data result from reading characteristcs
public enum XYServiceCharacteristicType {
    case string
    case integer
    case byte
}

public protocol XYServiceCharacteristic {
    var serviceUuid: CBUUID { get }
    var characteristicUuid: CBUUID { get }
    var characteristicType: XYServiceCharacteristicType { get }
}

// Global methods for all service characteristics
public extension XYServiceCharacteristic {

    func get(from device: XYBluetoothDevice) -> Promise<XYBluetoothResult> {
        return GattRequest(self).get(from: device).then { value in
            XYBluetoothResult(value)
        }
    }

    func set(to device: XYBluetoothDevice, value: XYBluetoothResult, withResponse: Bool = true) -> Promise<Void> {
        return GattRequest(self).set(to: device, valueObj: value, withResponse: withResponse)
    }

}
