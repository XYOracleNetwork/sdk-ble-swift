//
//  Service.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

public protocol ServiceCharacteristic {
    var serviceUuid: CBUUID { get }
    var characteristicUuid: CBUUID { get }
    var characteristicType: GattCharacteristicType { get }
}

// Used since you can't have protocols as firm types for use in dictionaries, sets, etc. but also to
// provide a way to do read and write operations in the same connection set
public struct SerivceCharacteristicDirective: Hashable {
    let operation: GattOperation
    let serviceCharacteristic: ServiceCharacteristic
    let value: XYBluetoothValue?
    public var hashValue: Int {
        return [
            serviceCharacteristic.serviceUuid.uuidString,
            serviceCharacteristic.characteristicUuid.uuidString,
            operation.rawValue].joined(separator: ":").hashValue
    }
    
    init(_ operation: GattOperation, serviceCharacteristic: ServiceCharacteristic, value: XYBluetoothValue? = nil) {
        self.operation = operation
        self.serviceCharacteristic = serviceCharacteristic
        self.value = value
    }
}

public func ==(lhs: SerivceCharacteristicDirective, rhs: SerivceCharacteristicDirective) -> Bool
{
    // false if runtime type is different
    guard ("\(type(of: lhs.serviceCharacteristic))" == "\(type(of: rhs.serviceCharacteristic))") else {return false}
    return lhs.hashValue == rhs.hashValue
}

// Global methods for all service characteristics
public extension ServiceCharacteristic {

    func get(from device: XYBluetoothDevice) -> Promise<XYBluetoothValue> {
        return GattClient(self).get(from: device).then { value in
            XYBluetoothValue(self, data: value)
        }
    }

    func set(to device: XYBluetoothDevice, value: XYBluetoothValue, withResponse: Bool = true) -> Promise<Data?> {
        return GattClient(self).set(to: device, valueObj: value, withResponse: withResponse)
    }

    var read: SerivceCharacteristicDirective {
        return SerivceCharacteristicDirective(.read, serviceCharacteristic: self)
    }
    
    func write(_ value: XYBluetoothValue) -> SerivceCharacteristicDirective {
        return SerivceCharacteristicDirective(.write, serviceCharacteristic: self, value: value)
    }

}
