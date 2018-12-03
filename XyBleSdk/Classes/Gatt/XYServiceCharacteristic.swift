//
//  Service.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import Promises

// Used for proper upacking of the data result from reading characteristcs
public enum XYServiceCharacteristicType {
    case string
    case integer
    case byte
}

// Protocol which defines a service and a characteristic, implemented as enumerations in the various *Service files
public protocol XYServiceCharacteristic {
    var serviceUuid: CBUUID { get }
    var characteristicUuid: CBUUID { get }
    var characteristicType: XYServiceCharacteristicType { get }
    var displayName: String { get }

    static var values: [XYServiceCharacteristic] { get }
}

// Global methods for all service characteristics, these create a disposable GattRequest to handle the
// service and characteristic discovery and the setting or getting of a characteristic. 
public extension XYServiceCharacteristic {

    var characteristics: [XYServiceCharacteristic] {
        return type(of: self).values
    }

    func get(from device: XYBluetoothDevice, timeout: DispatchTimeInterval? = nil) -> Promise<XYBluetoothResult> {
        return GattRequest(self, timeout: timeout).get(from: device).then { value in
            XYBluetoothResult(data: value)
        }
    }

    func set(to device: XYBluetoothDevice, value: XYBluetoothResult, timeout: DispatchTimeInterval? = nil, withResponse: Bool = true) -> Promise<Void> {
        return GattRequest(self, timeout: timeout).set(to: device, valueObj: value, withResponse: withResponse)
    }

    func notify(for device: XYBluetoothDevice, enabled: Bool, timeout: DispatchTimeInterval? = nil) -> Promise<Void> {
        return GattRequest(self, timeout: timeout).notify(for: device, enabled: enabled)
    }

}
