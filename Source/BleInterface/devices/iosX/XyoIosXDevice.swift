//
//  XyoIosXDevice.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 4/9/19.
//

import Foundation
import XyBleSdk
import sdk_objectmodel_swift
import CoreBluetooth

public enum XyoIosWifiStatus {
  case notConnected
  case connecting
  case connected
  case unknown
}

class XyoIosNetworkStausListener : XYBluetoothDeviceNotifyDelegate {
  var onWifiChangeCallback: ((_: XyoIosWifiStatus) -> ())? = nil
  
  func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
    print("XyoIosNetworkStausListener \(String(describing: value.asString))")
    guard let stringValue = value.asString else {
      return
    }
    
    if (stringValue == "0") {
      onWifiChangeCallback?(XyoIosWifiStatus.notConnected)
      return
    }
    
    if (stringValue == "1") {
      onWifiChangeCallback?(XyoIosWifiStatus.connecting)
      return
    }
    
    if (stringValue == "2") {
      onWifiChangeCallback?(XyoIosWifiStatus.connected)
      return
    }
    
    onWifiChangeCallback?(XyoIosWifiStatus.unknown)
  }
}

class XyoIosIpListener : XYBluetoothDeviceNotifyDelegate {
  var onIpChange: ((_: String) -> ())? = nil
  
  func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
    print("XyoIosIpListener \(String(describing: value.asString))")
    guard let stringValue = value.asString else {
      return
    }
    
    onIpChange?(stringValue)
  }
}

class XyoIosSsidListener : XYBluetoothDeviceNotifyDelegate {
  var onSsidChange: ((_: String) -> ())? = nil
  
  func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
    print("XyoIosSsidListener \(String(describing: value.asString))")
    guard let stringValue = value.asString else {
      return
    }
    
    onSsidChange?(stringValue)
  }
}


public class XyoIosXDevice : XyoDiffereniableDevice {
  private var delgateKey = ""
  private var hasMutex = false
  private let networkStatusListener = XyoIosNetworkStausListener()
  private let ipListener = XyoIosIpListener()
  private let ssidListener = XyoIosSsidListener()
  
  
  public func onNetworkStatusChange (callback: @escaping (_: XyoIosWifiStatus) -> ()) -> Bool {
    let key = "onNetworkStatusChange [DBG: \(#function)]: \(Unmanaged.passUnretained(networkStatusListener).toOpaque())"
    let result = self.subscribe(to: XyoIosXService.status,
                                delegate: (key: key, delegate: networkStatusListener))
    
    networkStatusListener.onWifiChangeCallback = callback
    
    return result.error == nil
  }
  
  public func onIpChange (callback: @escaping (_: String) -> ()) -> Bool {
    let key = "onIpChange [DBG: \(#function)]: \(Unmanaged.passUnretained(ipListener).toOpaque())"
    let result = self.subscribe(to: XyoIosXService.ip,
                                delegate: (key: key, delegate: ipListener))
    
    ipListener.onIpChange = callback
    
    return result.error == nil
  }
  
  public func onSsidChange (callback: @escaping (_: String) -> ()) -> Bool {
    let key = "onSsidChange [DBG: \(#function)]: \(Unmanaged.passUnretained(ssidListener).toOpaque())"
    let result = self.subscribe(to: XyoIosXService.ssid,
                                delegate: (key: key, delegate: ssidListener))
    
    ssidListener.onSsidChange = callback
    
    return result.error == nil
  }
  
  
  public func getMutex () -> Bool {
    self.delgateKey = "mutex [DBG: \(#function)]: \(Unmanaged.passUnretained(self).toOpaque())"
    print("A")
    let result = self.subscribe(to: XyoIosXService.mutex,
                                delegate: (key: self.delgateKey, delegate: self))
    
    if (result.error == nil) {
      self.hasMutex = true
    }
    
    
    return result.error == nil
  }
  
  public func connectToWifi (ssid: String, password: String) -> Bool {
    let json = "{\"ssid\": \"\(ssid)\",\"password\": \"\(password)\"}".data(using: .utf8)
    
    let error = self.set(XyoIosXService.connect, value: XYBluetoothResult(data: json)).error
    return error == nil
  }
  
  public func releaseMutex () -> Bool {
    if (hasMutex) {
      let result = self.unsubscribe(from: XyoIosXService.mutex, key: self.delgateKey)
      
      if (result.error == nil) {
        hasMutex = false
      }
      
      return result.error == nil
    }
    
    return false
  }
  
  public func getSsids () -> [Substring] {
    if (hasMutex) {
      guard let result = self.get(XyoIosXService.scan).asString else {
        return []
      }
      
      return result.split(separator: ",")
    }
    
    return []
  }
  
  public func isClaimed () -> Bool {
    guard let minor = self.iBeacon?.minor else {
      return false
    }
    
    let flags = XyoBuffer()
      .put(bits: minor)
      .getUInt8(offset: 1)
    
    return flags & 1 != 0
  }
  
  public func isConnected () -> Bool {
    guard let minor = self.iBeacon?.minor else {
      return false
    }
    
    let flags = XyoBuffer()
      .put(bits: minor)
      .getUInt8(offset: 1)
    
    return flags & 2 != 0
  }
  
}
