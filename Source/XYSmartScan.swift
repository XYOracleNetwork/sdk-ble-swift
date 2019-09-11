//
//  XYSmartScan.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol XYSmartScanDelegate {
  func smartScan(status: XYSmartScanStatus)
  func smartScan(location: XYLocationCoordinate2D)
  func smartScan(detected device: XYBluetoothDevice, rssi: Int, family: XYDeviceFamily)
  func smartScan(detected devices: [XYBluetoothDevice], family: XYDeviceFamily)
  func smartScan(entered device: XYBluetoothDevice)
  func smartScan(exiting device:XYBluetoothDevice)
  func smartScan(exited device: XYBluetoothDevice)
}

public enum XYSmartScanStatus: Int {
  case none
  case enabled
  case bluetoothUnavailable
  case bluetoothDisabled
  case backgroundLocationDisabled
  case locationDisabled
}

public enum XYSmartScanMode {
  case initializing
  case foreground
  case background
}

public class XYSmartScan {
  
  public static let instance = XYSmartScan()
  
  fileprivate var delegates = [String: XYSmartScanDelegate?]()
  
  fileprivate var trackedDevices = [String: XYFinderDevice]()
  
  fileprivate lazy var currentDiscoveryList = [XYDeviceFamily]()
  
  fileprivate let location = XYLocation.instance
  fileprivate let central = XYCentral.instance
  
  public fileprivate(set) var currentLocation = XYLocationCoordinate2D()
  public fileprivate(set) var currentStatus = XYSmartScanStatus.none
  fileprivate var isActive: Bool = false
  
  public fileprivate(set) var mode: XYSmartScanMode = .initializing
  
  fileprivate var isCheckingExits: Bool = false
  
  internal static let queue = DispatchQueue(label: String(format: "com.xyfindables.sdk.XYSmartScan"))
  
  private init() {
    #if os(iOS)
    self.location.setDelegate(self, key: "XYSmartScan")
    self.central.setDelegate(self, key: "XYSmartScan")
    #elseif os(macOS)
    self.central.setDelegate(self, key: "XYSmartScan")
    #endif
  }
  
  public func start(for families: [XYDeviceFamily] = XYDeviceFamily.allFamlies(), mode: XYSmartScanMode) {
    if mode == self.mode { return }
    
    // For iOS, we use the Location manager to range/monitor for iBeacon devices
    #if os(iOS)
    self.location.start()
    
    switch mode {
    case .foreground: self.switchToForeground(families)
    case .background: self.switchToBackground(families)
    default: self.switchToForeground(families)
    }
    
    self.isActive = true
    #endif
    
    // In the case of macOS, we use central to discover and filter devices on ad data to determine if they are iBeacons
    #if os(macOS)
    self.currentDiscoveryList = families
    
    self.central.state == .poweredOn ?
      self.central.scan() :
      self.central.enable()
    
    self.isActive = true
    #endif
  }
  
  public func stop() {
    guard isActive else { return }
    
    #if os(iOS)
    self.location.stop()
    self.location.clearMonitoring()
    self.location.clearRanging()
    #endif
    
    #if os(macOS)
    self.central.stopScan()
    self.currentDiscoveryList.removeAll()
    #endif
    
    self.trackedDevices.removeAll()
    
    self.isActive = false
    self.isCheckingExits = false
    self.mode = .background
  }
  
  public func setDelegate(_ delegate: XYSmartScanDelegate, key: String) {
    self.delegates[key] = delegate
  }
  
  public func removeDelegate(for key: String) {
    self.delegates.removeValue(forKey: key)
  }
  
  public func invalidateSession() {
    XYDeviceConnectionManager.instance.invalidate()
    XYBluetoothDeviceFactory.invalidateCache()
  }
  
  public var trackDevicesCount: Int {
    return self.trackedDevices.count
  }
}

// MARK: Change monitoring state based on start/stop
fileprivate extension XYSmartScan {
  
  func switchToForeground(_ families: [XYDeviceFamily]) {
    guard self.mode != .foreground else { return }
    
    self.mode = .foreground
    
    #if os(iOS)
    self.location.clearMonitoring()
    self.location.startRanging(for: families)
    #endif
    
    self.central.state == .poweredOn ?
      self.central.scan() :
      self.central.enable()
    
    self.isCheckingExits = true
    self.checkExits()
    self.updateTracking()
    self.updateStatus()
  }
  
  func switchToBackground(_ families: [XYDeviceFamily]) {
    guard self.mode != .background else { return }
    
    self.mode = .background
    #if os(iOS)
    self.location.clearRanging()
    #endif
    self.isCheckingExits = false
    #if os(iOS)
    self.location.startMonitoring(for: families)
    #endif
    self.updateTracking()
    self.updateStatus()
  }
  
}

// MARK: Status updates
extension XYSmartScan {
  
  public func updateStatus() {
    #if os(iOS)
    var newStatus = XYSmartScanStatus.enabled
    let central = XYCentral.instance
    if !XYLocation.instance.locationServicesEnabled {
      newStatus = .locationDisabled
    } else {
      let authorizationStatus = XYLocation.instance.authorizationStatus
      if authorizationStatus != .authorizedAlways && authorizationStatus != .notDetermined {
        newStatus = .backgroundLocationDisabled
      }
    }
    
    switch central.state {
    case .unknown:
      newStatus = .none
    case .poweredOn:
      newStatus = .enabled
      break
    case .poweredOff:
      newStatus = .bluetoothDisabled
      break
    case .unsupported:
      newStatus = .bluetoothUnavailable
      break
    case .unauthorized:
      newStatus = .backgroundLocationDisabled
      break
    case .resetting:
      newStatus = .none
      break
    default:
      break;
    }
    
    if self.currentStatus != newStatus {
      self.currentStatus = newStatus
      // Currently used only by the app for displaying BLE/Location status
      self.delegates.map { $1 }.forEach { $0?.smartScan(status: self.currentStatus)}
    }
    #endif
  }
  
}

// MARK: Tracking wranglers for known devices
public extension XYSmartScan {
  
  // Called from the application code, used to track a device that is assigne to the user
  func startTracking(for device: XYFinderDevice) {
    XYSmartScan.queue.sync {
      guard trackedDevices[device.id] == nil else { return }
      trackedDevices[device.id] = device
      updateTracking()
    }
  }
  
  func stopTracking(for deviceId: String) {
    XYSmartScan.queue.sync {
      guard trackedDevices[deviceId] != nil else { return }
      trackedDevices.removeValue(forKey: deviceId)
      updateTracking()
    }
  }
  
  fileprivate func updateTracking() {
    #if os(iOS)
    self.mode == .foreground ?
      location.startRanging(for: self.trackedDevices.map { $1 as XYBluetoothDevice } ) :
      location.startMonitoring(for: self.trackedDevices.map { $1 } )
    #endif
  }
  
  // Another recursive method for checking exits of devices so we can alter the user
  fileprivate func checkExits() {
    XYSmartScan.queue.asyncAfter(deadline: DispatchTime.now() + TimeInterval(XYConstants.DEVICE_TUNING_SECONDS_EXIT_CHECK_INTERVAL)) {
      guard self.isCheckingExits else {
        return
      }
      
      // Loop through known devices that are connected
      let connectedDevices = XYDeviceConnectionManager.instance.connectedDevices
      for device in connectedDevices {
        guard
          let xyDevice = device as? XYFinderDevice,
          let lastPulseTime = device.lastPulseTime,
          device.isUpdatingFirmware == false,
          fabs(lastPulseTime.timeIntervalSinceNow) > XYConstants.DEVICE_TUNING_SECONDS_WITHOUT_SIGNAL_FOR_EXITING
          else { continue }
        
        // Currently used by the refresh signal meters, this will show .none
        XYFinderDeviceEventManager.report(events: [.exiting(device: xyDevice)])
        xyDevice.verifyExit(nil)
      }
      
      self.checkExits()
    }
  }
}

#if os(iOS)
// MARK: BLELocationDelegate - Location monitoring and ranging delegates
extension XYSmartScan: XYLocationDelegate {
  public func deviceExiting(_ device: XYBluetoothDevice) {
    self.delegates.forEach { $1?.smartScan(exiting: device) }
  }
  
  public func locationsUpdated(_ locations: [XYLocationCoordinate2D]) {
    locations.forEach { location in
      self.delegates.forEach { $1?.smartScan(location: location) }
      XYBluetoothDeviceFactory.updateDeviceLocations(location)
    }
  }
  
  public func didRangeBeacons(_ beacons: [XYBluetoothDevice], for family: XYDeviceFamily?) {
    guard let family = family else { return }
    
    let uniqueBeacons = beacons.reduce([], { initial, beacon in
      initial.contains(where: { $0.id == beacon.id }) ? initial : initial + [beacon]
    })
    
    uniqueBeacons.forEach { beacon in
      if !beacon.inRange {
        self.delegates.forEach { $1?.smartScan(entered: beacon)}
        XYFinderDeviceEventManager.report(events: [.entered(device: beacon)])
      }
      
      self.delegates.forEach {
        $1?.smartScan(detected: beacon, rssi: beacon.rssi, family: family)
      }
      
      // Handles button presses and other notifications
      beacon.detected(beacon.rssi)
    }
    
    self.delegates.forEach {
      $1?.smartScan(detected: uniqueBeacons, family: family)
    }
  }
  
  public func deviceEntered(_ device: XYBluetoothDevice) {
    self.delegates.forEach { $1?.smartScan(entered: device) }
    print("MONITOR ENTER: Device \(device.id)")
    (device as? XYFinderDevice)?.cancelMonitorTimer()
  }
  
  public func deviceExited(_ device: XYBluetoothDevice) {
    self.delegates.forEach { $1?.smartScan(exited: device) }
    print("MONITOR EXIT: Device \(device.id)")
    (device as? XYFinderDevice)?.startMonitorTimer()
  }
  
}
#endif

//#if os(macOS)
extension XYSmartScan: XYCentralDelegate {
  public func stateChanged(newState: CBManagerState) {
    if newState == .poweredOn {
      self.central.scan()
    }
    updateStatus()
  }
  
  public func located(peripheral: XYPeripheral) {
    guard
      let beacon = peripheral.beaconDefinitionFromAdData,
      let device = XYBluetoothDeviceFactory.build(from: beacon, rssi: peripheral.rssi, updateRssiAndPower: true)
      else { return }
    
    let family = device.family
    
    if !device.inRange {
      self.delegates.forEach { $1?.smartScan(entered: device)}
      XYFinderDeviceEventManager.report(events: [.entered(device: device)])
    }
    
    self.delegates.forEach {
      $1?.smartScan(detected: device, rssi: device.rssi, family: family)
    }
    
    // Handles button presses and other notifications
    device.detected(peripheral.rssi)
    
    self.delegates.forEach { $1?.smartScan(detected: [device], family: family) }
  }
  
  public func connected(peripheral: XYPeripheral) {}
  public func timeout() {}
  public func couldNotConnect(peripheral: XYPeripheral) {}
  public func disconnected(periperhal: XYPeripheral) {}
}
//#endif
