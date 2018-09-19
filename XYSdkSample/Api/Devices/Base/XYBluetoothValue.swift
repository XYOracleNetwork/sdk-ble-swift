//
//  XYBluetoothResult.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/13/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public class XYBluetoothValue {
    public let serviceCharacteristic: ServiceCharacteristic
    public private(set) var data: Data?

    public init(_ serviceCharacteristic: ServiceCharacteristic) {
        self.serviceCharacteristic = serviceCharacteristic
    }

    public convenience init(_ serviceCharacteristic: ServiceCharacteristic, data: Data?) {
        self.init(serviceCharacteristic)
        self.data = data
    }

    public func setData(_ data: Data?) {
        self.data = data
    }

    public var type: GattCharacteristicType {
        return serviceCharacteristic.characteristicType
    }
}

extension Data {
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.pointee }
    }
}

public extension XYBluetoothValue {

    var asString: String? {
        guard let data = self.data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var asInteger: Int? {
        guard let data = self.data else { return nil }
        return data.to(type: Int.self)
    }

}
