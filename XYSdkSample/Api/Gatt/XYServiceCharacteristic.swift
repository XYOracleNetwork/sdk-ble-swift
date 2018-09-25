//
//  Service.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

public protocol XYServiceCharacteristic {
    var serviceUuid: CBUUID { get }
    var characteristicUuid: CBUUID { get }
    var characteristicType: GattCharacteristicType { get }
}

// Global methods for all service characteristics
public extension XYServiceCharacteristic {

    func get(from device: XYBluetoothDevice) -> Promise<XYBluetoothResult> {
        return GattClient(self).get(from: device).then { value in
            XYBluetoothResult(value)
        }
    }

    func set(to device: XYBluetoothDevice, value: XYBluetoothResult, withResponse: Bool = true) -> Promise<Void> {
        return GattClient(self).set(to: device, valueObj: value, withResponse: withResponse)
    }

}
