//
//  XYBluetoothResult.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/13/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation

// Represents the result from any get/set request made via a GattRequest
// This result will contain the raw Data from a get, is used to set raw Data for a set,
// and will contain any error that occurred as part of the operation
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
  
  public static var empty: XYBluetoothResult { return XYBluetoothResult(data: nil) }
  
  public func setData(_ data: Data?) { self.data = data }
  public func setError(_ error: XYBluetoothError?) { self.error = error }
  
  public var hasError: Bool { return error != nil }
}

// Display a hex number from Data
extension Collection where Iterator.Element == UInt8 {
  public var hexa: String {
    return map{ String(format: "%02X", $0) }.joined()
  }
}

public extension XYBluetoothResult {
  
  var asString: String? {
    guard let data = self.data else { return nil }
    return String(data: data, encoding: .utf8)
  }
  
  var asInteger: Int? {
    guard let data = self.data, data.count > 0 else { return nil }
    let array = [UInt8](data)
    if (array.count == 1) {
      return data.withUnsafeBytes {
        let value = $0.load(as: UInt8.self)
        return Int(value)
      }
    }
    else if (array.count == 2) {
      return data.withUnsafeBytes {
        let value = $0.load(as: UInt16.self)
        return Int(bigEndian: Int(value))
      }
    }
    else if (array.count == 4) {
      return data.withUnsafeBytes {
        let value = $0.load(as: UInt32.self)
        return Int(bigEndian: Int(value))
      }
    }
    return nil
  }
  
  var asByteArray: [UInt8]? {
    guard let data = self.data else { return nil }
    return Array(data)
  }
  
}
