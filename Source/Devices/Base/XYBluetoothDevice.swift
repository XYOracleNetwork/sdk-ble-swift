//
//  XYBluetoothDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import CoreLocation
import Promises
import CoreLocation



// Use for notifying when a property that the client has subscribed to has changed
public protocol XYBluetoothDeviceNotifyDelegate {
  func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult)
}

// A generic BLE device
public protocol XYBluetoothDevice: XYBluetoothBase {
  var family : XYDeviceFamily {get}
  var iBeacon : XYIBeaconDefinition? {get}
  var peripheral: CBPeripheral? { get set }
  var inRange: Bool { get }
  var connected: Bool { get }
  var markedForDeletion: Bool? { get }
  var isUpdatingFirmware: Bool { get }
  
  func stayConnected(_ value: Bool)
  func updatingFirmware(_ value: Bool)
  
  func connect()
  func disconnect()
  
  func verifyExit(_ callback:((_ exited: Bool) -> Void)?)
  
  @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void>
  
  func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval?) -> XYBluetoothResult
  func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval?, withResponse: Bool) -> XYBluetoothResult
  
  func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate)) -> XYBluetoothResult
  func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) -> XYBluetoothResult
  
  func subscribe(_ delegate: CBPeripheralDelegate, key: String)
  func unsubscribe(for key: String)
  
  func attachPeripheral(_ peripheral: XYPeripheral) -> Bool
  func detachPeripheral()
  func detected (_ rssi: Int)
  
  var state: CBPeripheralState { get }
}

// MARK: Methods to get, set, or notify on a characteristic using the Promises-based connection work block method below
public extension XYBluetoothDevice {
  
  var connected: Bool {
    return (self.peripheral?.state ?? .disconnected) == .connected
  }
  
  var state: CBPeripheralState {
    return self.peripheral?.state ?? .disconnected
  }
  
  func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
    do {
      return try await(serivceCharacteristic.get(from: self, timeout: timeout))
    } catch {
      return XYBluetoothResult(error: error as? XYBluetoothError)
    }
  }
  
  func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval? = nil, withResponse: Bool = true) -> XYBluetoothResult {
    do {
      try await(serivceCharacteristic.set(to: self, value: value, timeout: timeout, withResponse: withResponse))
      return XYBluetoothResult(data: nil)
    } catch {
      return XYBluetoothResult(error: error as? XYBluetoothError)
    }
  }
  
  func notify(_ serivceCharacteristic: XYServiceCharacteristic, enabled: Bool, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
    do {
      try await(serivceCharacteristic.notify(for: self, enabled: enabled, timeout: timeout))
      return XYBluetoothResult(data: nil)
    } catch {
      return XYBluetoothResult(error: error as? XYBluetoothError)
    }
  }
  
  func inquire(_ timeout: DispatchTimeInterval? = nil, callback: @escaping (GattDeviceDescriptor) -> Void) -> XYBluetoothResult {
    do {
      _ = try await(GattInquisitor(timeout).inquire(for: self).then { callback($0) })
      return XYBluetoothResult(data: nil)
    } catch {
      return XYBluetoothResult(error: error as? XYBluetoothError)
    }
  }
  
}

// MARK: Connecting to a device in order to complete a block of operations defined above, as well as disconnect from the peripheral
public extension XYBluetoothDevice {
  
  @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void> {
    // Check range before running operations block
    //        guard self.inRange else {
    //            return Promise<Void>(XYBluetoothError.deviceNotInRange)
    //        }
    
    // Process the queue, adding the connections agents if needed
    return Promise<Void>(on: self.deviceBleQueue) {
      print("STEP 2: Trying to lock for \(self.id.shortId)...")
      
      // If we don't have a powered on central, we'll see if we can't get that running
      if XYCentral.instance.state != .poweredOn {
        print("STEP 2a: Trying to power on Central for \(self.id.shortId)...")
        try await(XYCentralAgent().powerOn())
      }
      
      // If we are no connected, use the agent to handle that before running the operations block
      if self.peripheral?.state != .connected {
        print("STEP 3: Trying to connect for \(self.id.shortId)... STATE is \(self.peripheral?.state.rawValue ?? -1)")
        try await(XYConnectionAgent(for: self).connect())
      }
      
      print("STEP 4: Trying to run operations for \(self.id.shortId)...")
      
      // Run the requested Gatt operations
      try operations()
      
      }.then(on: self.deviceBleQueue) {
        print("STEP 5: All done for \(self.id.shortId)")
    }
    
  }
  
  
}

// MARK: Default implementations of protocol methods and variables
public extension XYBluetoothDevice {
  
  
  #if os(iOS)
  func beaconRegion(slot: UInt16) -> CLBeaconRegion {
    return beaconRegion(self.family.uuid, slot: slot)
  }
  
  // Builds a beacon region for use in XYLocation based on the current XYIBeaconDefinition
  func beaconRegion(_ uuid: UUID, slot: UInt16? = nil) -> CLBeaconRegion {
    if iBeacon?.hasMinor ?? false, let major = iBeacon?.major, let minor = iBeacon?.minor {
      let computedMinor = slot == nil ? minor : ((minor & 0xfff0) | slot!)
      return CLBeaconRegion(
        proximityUUID: uuid,
        major: major,
        minor: computedMinor,
        identifier: String(format:"%@:4", id))
    }
    
    if iBeacon?.hasMajor ?? false, let major = iBeacon?.major {
      return CLBeaconRegion(
        proximityUUID: uuid,
        major: major,
        identifier: String(format:"%@:4", id))
    }
    
    return CLBeaconRegion(
      proximityUUID: uuid,
      identifier: String(format:"%@:4", id))
  }
  #endif
}
