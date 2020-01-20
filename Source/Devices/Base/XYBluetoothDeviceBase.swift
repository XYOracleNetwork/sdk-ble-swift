//
//  XYBluetoothDeviceBase.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import CoreLocation


// A concrete base class to base any BLE device off of
open class XYBluetoothDeviceBase: NSObject, XYBluetoothBase, XYBluetoothDevice {
  public var
  firstPulseTime: Date?,
  lastPulseTime: Date?,
  lastMonitoredTime: Date?
  
  public internal(set) var
  totalPulseCount = 0,
  markedForDeletion: Bool? = false,
  queuedForConnection: Bool = false
  
  fileprivate var deviceLock = GenericLock(3)
  
  internal var verifyCounter = 0
  
  var _rssi: Int = 0
  
  public var
  rssi: Int {
    set {
      _rssi = newValue
    }
    get {
      return _rssi
    }
  }
  public var powerLevel: UInt8
  public var constraint : CLBeaconIdentityConstraint
  
  public let
  name: String,
  id: String
  
  public let
  deviceBleQueue: DispatchQueue,
  family : XYDeviceFamily,
  iBeacon : XYIBeaconDefinition?
  
  public fileprivate(set) var rssiRange: (min: Int, max: Int) = (0, 0) {
    didSet {
      // We use this hook due to how the FindIt app starts to connect to devices, and we don't want to
      // connect when they are not in range yet. Once the device is in range, we check if
      // it was queued in stayConnected below and try our connection. This allows for not waiting
      // for timeouts on GATT operations when a device can't be found.
      if self.queuedForConnection && self.isUpdatingFirmware == false && self.inRange {
        self.stayConnected(true)
      }
    }
  }
  
  public var peripheral: CBPeripheral?
  
  internal var stayConnected: Bool = false
  public fileprivate(set) var isUpdatingFirmware: Bool = false
  
  public lazy var supportedServices = [CBUUID]()
  
  fileprivate lazy var delegates = [String: CBPeripheralDelegate?]()
  fileprivate lazy var notifyDelegates = [String: (serviceCharacteristic: XYServiceCharacteristic, delegate: XYBluetoothDeviceNotifyDelegate?)]()
  
  public init(_ id: String, rssi: Int = XYDeviceProximity.none.rawValue, family : XYDeviceFamily, iBeacon : XYIBeaconDefinition?) {
    self.id = id
    self.name = ""
    self.powerLevel = 0
    self.deviceBleQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothBaseQueueFor\(id.shortId)")
    self.family = family
    self.iBeacon = iBeacon
    super.init()
    self.rssi = rssi
    self.constraint = constraint
  }
  
  open func detected(_ rssi: Int) {}
  
  public func update(_ rssi: Int, powerLevel: UInt8) {
    if rssi != XYDeviceProximity.defaultProximity {
      self.rssi = rssi
    }
    
    // Inital setting of range
    if rssiRange.min == 0 && rssiRange.max == 0 {
      rssiRange.min = rssi
      rssiRange.max = rssi
    } else if rssi != 0 {
      // Update range
      if rssiRange.max < rssi { rssiRange.max = rssi }
      if rssiRange.min > rssi { rssiRange.min = rssi }
    }
    
    self.powerLevel = powerLevel
    self.totalPulseCount += 1
    
    if self.firstPulseTime == nil {
      self.firstPulseTime = Date()
    }
    
    self.lastPulseTime = Date()
  }
  
  public func resetRssi() {
    self.rssi = XYDeviceProximity.defaultProximity
  }
  
  public func verifyExit(_ callback:((_ exited: Bool) -> Void)?) {}
  
  public var inRange: Bool {
    if self.peripheral?.state == .connected { return true }
    
    let strength = XYDeviceProximity.fromSignalStrength(self.rssi)
    guard
      strength != .outOfRange && strength != .none
      else { return false }
    
    return true
  }
  
  public func subscribe(_ delegate: CBPeripheralDelegate, key: String) {
    guard self.delegates[key] == nil else { return }
    self.delegates[key] = delegate
  }
  
  public func unsubscribe(for key: String) {
    self.delegates.removeValue(forKey: key)
  }
  
  public func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate)) -> XYBluetoothResult {
    let result = self.notify(serviceCharacteristic, enabled: true)
    
    if !result.hasError {
      self.notifyDelegates[delegate.key] = (serviceCharacteristic, delegate.delegate)
    }
    
    return result
  }
  
  public func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) -> XYBluetoothResult {
    self.notifyDelegates.removeValue(forKey: key)
    return self.notify(serviceCharacteristic, enabled: false)
  }
  
  open func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
    
    return false
  }
  
  
  public func detachPeripheral() {
    self.peripheral = nil
  }
  
  public func updatingFirmware(_ value: Bool) {
    self.isUpdatingFirmware = value
  }
  
  // Connects to the device if requested, and the device is both not trying to connect or already has connected
  public func stayConnected(_ value: Bool) {
    // Do not try to connect/disconnect when the firmware is updating
    guard self.isUpdatingFirmware == false else { return }
    
    self.stayConnected = value
    // Only try a connection when in range, otherwise queue this so when it does come into range
    // it will auto connect at that time
    if self.inRange {
      self.stayConnected ? connect() : disconnect()
      self.queuedForConnection = false
    } else {
      self.queuedForConnection = true
    }
  }
  
  public func connect() {
    XYDeviceConnectionManager.instance.add(device: self)
  }
  
  public func disconnect() {
    self.markedForDeletion = true
    XYDeviceConnectionManager.instance.remove(for: self.id, disconnect: true)
  }
}

// MARK: CBPeripheralDelegate, passes these on to delegate subscribers for this peripheral
extension XYBluetoothDeviceBase: CBPeripheralDelegate {
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverServices: error) }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.notifyDelegates
      .filter { $0.value.serviceCharacteristic.characteristicUuid == characteristic.uuid }
      .forEach { $0.value.delegate?.update(for: $0.value.serviceCharacteristic, value: XYBluetoothResult(data: characteristic.value))}
    
    self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.delegates.forEach { $1?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error) }
  }
  
  // We "recursively" call this method, updating the latest rssi value, and also calling detected if it is an XYFinder device
  // This is the driver for the distance meters in the primary application
  public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    guard peripheral == self.peripheral else { return }
    self.update(Int(truncating: RSSI), powerLevel: 0x4)
    self.delegates.forEach { $1?.peripheral?(peripheral, didReadRSSI: RSSI, error: error) }
    (self as? XYFinderDevice)?.detected(RSSI.intValue)
    
    // TOOD Not sure this is the right place for this...
    DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(XYConstants.DEVICE_TUNING_SECONDS_INTERVAL_CONNECTED_RSSI_READ)) {
      if (peripheral.state == .connected) {
        peripheral.readRSSI()
      }
    }
  }
}

