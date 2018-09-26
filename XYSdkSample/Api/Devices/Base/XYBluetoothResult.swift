//
//  XYBluetoothResult.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/13/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public class XYBluetoothResult {
    public private(set) var data: Data?
    public private(set) var error: XYBluetoothError?

    public init(data: Data?) {
        self.data = data
    }

    public convenience init(_ data: Data?, error: XYBluetoothError?) {
        self.init(data: data)
        self.error = error
    }

    public convenience init(error: XYBluetoothError?) {
        self.init(data: nil)
        self.error = error
    }

    public func setData(_ data: Data?) { self.data = data }
    public func setError(_ error: XYBluetoothError?) { self.error = error }
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

public extension XYBluetoothResult {

    var asString: String? {
        guard let data = self.data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    var asInteger: Int? {
        guard let data = self.data else { return nil }
        return data.to(type: Int.self)
    }

}
