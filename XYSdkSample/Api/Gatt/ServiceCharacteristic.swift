//
//  Service.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import PromiseKit

public protocol ServiceCharacteristic {
    var uuid: CBUUID { get }
    var characteristic: CBUUID { get }
    var characteristicType: CharacteristicType { get }
    var wrapper: SerivceCharacteristicWrapper { get }
}

// Used since you can't have protocols as firm types for use in dictionaries, sets, etc.
public struct SerivceCharacteristicWrapper: Hashable {
    let serviceCharacteristic: ServiceCharacteristic
    public var hashValue: Int { return [serviceCharacteristic.uuid.uuidString, serviceCharacteristic.characteristic.uuidString].joined(separator: ":").hashValue }
}

public func ==(lhs: SerivceCharacteristicWrapper, rhs: SerivceCharacteristicWrapper) -> Bool
{
    // false if runtime type is different
    guard ("\(type(of: lhs.serviceCharacteristic))" == "\(type(of: rhs.serviceCharacteristic))") else {return false}
    return lhs.hashValue == rhs.hashValue
}

// Global methods for all service characteristics
public extension ServiceCharacteristic {

    public func get(from device: XYBluetoothDevice, value: XYBluetoothValue) -> Promise<Void> {
        return GattClient(self).get(from: device, valueObj: value)
    }

    public func set(to device: XYBluetoothDevice, value: XYBluetoothValue, withResponse: Bool = true) -> Promise<Void> {
        return GattClient(self).set(to: device, valueObj: value, withResponse: withResponse)
    }

    public var wrapper: SerivceCharacteristicWrapper { return SerivceCharacteristicWrapper(serviceCharacteristic: self) }

}

// Used for proper upacking of the data result from reading characteristcs
public enum CharacteristicType {
    case string
    case integer
    case byte
}
