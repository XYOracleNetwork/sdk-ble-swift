//
//  XYLocation.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreLocation
import CoreBluetooth

public protocol XYLocationDelegate: class {
  func didRangeBeacons(_ beacons: [XYBluetoothDevice], satisfyingConstraint beaconConstraint: CLBeaconIdentityConstraint)
  func deviceEntered(_ device: XYBluetoothDevice)
  func deviceExited(_ device: XYBluetoothDevice)
  func deviceExiting(_ device: XYBluetoothDevice)
  func locationsUpdated(_ locations: [XYLocationCoordinate2D])
}

public class XYLocation: NSObject {
  
  public static let instance = XYLocation()
  
  fileprivate let manager = CLLocationManager()
  
  fileprivate lazy var delegates = [String: XYLocationDelegate?]()
  
  private override init() {
    super.init()
    #if os(iOS)
    self.manager.delegate = self
    #endif
  }
  
  public func setDelegate(_ delegate: XYLocationDelegate, key: String) {
    self.delegates[key] = delegate
  }
  
  public var userLocation: CLLocationCoordinate2D? {
    return self.manager.location?.coordinate
  }
}

// MARK: Start and stop
public extension XYLocation {
  
  func start() {
    self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    self.manager.distanceFilter = XYConstants.DEVICE_TUNING_LOCATION_CHANGE_THRESHOLD
    #if os(iOS)
    self.manager.allowsBackgroundLocationUpdates = true
    self.manager.requestAlwaysAuthorization()
    self.manager.startUpdatingLocation()
    #endif
  }
  
  func stop() {
    self.manager.stopUpdatingLocation()
  }
}

#if os(iOS)
// MARK: Passthrough methods
public extension XYLocation {
  
  var locationServicesEnabled: Bool {
    return CLLocationManager.locationServicesEnabled()
  }
  
  var authorizationStatus: CLAuthorizationStatus {
    return CLLocationManager.authorizationStatus()
  }
  
}

// MARK: Ranging methods (used for foreground operations)
extension XYLocation {
  
  // Convenience method
  public func startRanging(for families: [XYDeviceFamily]) {
    
    families.forEach { startRanging(for: $0) }
  }
  
  // Start ranging for a particular type of XY device
  public func startRanging(for family: XYDeviceFamily) {
    guard let device = XYBluetoothDeviceFactory.build(from: family) else { return }
    self.startRanging(for: device)
  }
  
  public func startRanging(for devices: [XYBluetoothDevice]) {
    // Get the existing regions that location manager is looking for
    let rangedDevices = manager.rangedBeaconConstraints
      .compactMap { $0 as? CLBeaconRegion }
      .filter { $0.minor != nil && $0.major != nil }
      .compactMap { XYBluetoothDeviceFactory.build(from: $0.xyiBeaconDefinition ) }
    
    // Remove devices from rangning that are not on the list
    rangedDevices.filter { device in !devices.contains(where: { $0.id == device.id }) }.forEach { self.stopRanging(for: $0) }
    
    // Add unranged devices
    devices.filter { device in !rangedDevices.contains(where: { $0.id == device.id }) }.forEach { self.startRanging(for: $0) }
  }
  
  public func startRanging(for device: XYBluetoothDevice) {
    let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: device.constraint, identifier: device.id)
    manager.startRangingBeacons(satisfying: beaconRegion)
  }
  
  public func clearRanging() {
    manager.rangedBeaconConstraints
      .compactMap { $0 as? CLBeaconIdentityConstraint }
      .forEach { manager.stopRangingBeacons(satisfying: $0) }
  }
  
  public func stopRanging(for device: XYBluetoothDevice) {
    let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: device.constraint, identifier: device.id)
    manager.stopRangingBeacons(satisfying: beaconRegion)
  }
}

// MARK: Monitoring methods (used for background operation)
public extension XYLocation {
  
  func clearMonitoring() {
    self.manager.monitoredRegions.forEach { region in
      self.manager.stopMonitoring(for: region)
    }
  }
  
  // Convenience method
  func startMonitoring(for families: [XYDeviceFamily]) {
    
    families.forEach { startMonitoring(for: $0, isHighPriority: false) }
  }
  
  func startMonitoring(for family: XYDeviceFamily, isHighPriority: Bool) {
    
    guard let device = XYBluetoothDeviceFactory.build(from: family) else {
      return
    }
    
    self.startMonitoring(for: device, isHighPriority: isHighPriority)
  }
  
  func startMonitoring(for devices: [XYBluetoothDevice]) {
    // Get the existing regions that location manager is looking for
    let monitoredDevices = manager.monitoredRegions
      .compactMap { $0 as? CLBeaconRegion }
      .filter { $0.minor != nil && $0.major != nil }
      .compactMap { XYBluetoothDeviceFactory.build(from: $0.xyiBeaconDefinition ) }
    
    // Remove devices from monitored that are not on the list
    monitoredDevices.filter { device in !devices.contains(where: { $0.id == device.id }) }.forEach {
      self.stopMonitoring(for: $0)
    }
    
    // Add unmonitored devices
    devices.filter { device in !monitoredDevices.contains(where: { $0.id == device.id }) }.forEach {
      self.startMonitoring(for: $0, isHighPriority: false)
    }
  }
  
  func startMonitoring(for device: XYBluetoothDevice, isHighPriority: Bool) {
    if isHighPriority {
      //monitor for button presses also, aka power level 8
      let beaconRegionLevel8 = device.beaconRegion(slot: 8)
      beaconRegionLevel8.notifyOnExit = false
      beaconRegionLevel8.notifyOnEntry = false
      beaconRegionLevel8.notifyEntryStateOnDisplay = false
      self.manager.startMonitoring(for: beaconRegionLevel8)
    }
    
    //always monitor power level 4
    let beaconRegionLevel4 = device.beaconRegion(slot: 4)
    beaconRegionLevel4.notifyOnExit = true
    beaconRegionLevel4.notifyOnEntry = true
    beaconRegionLevel4.notifyEntryStateOnDisplay = true
    self.manager.startMonitoring(for: beaconRegionLevel4)
  }
  
  func stopMonitoring(for device: XYBluetoothDevice) {
    manager.stopMonitoring(for: device.beaconRegion(device.family.uuid, slot: 4))
    manager.stopMonitoring(for: device.beaconRegion(device.family.uuid, slot: 7))
    manager.stopMonitoring(for: device.beaconRegion(device.family.uuid, slot: 8))
  }
  
}

// MARK: CLLocationManagerDelegate
extension XYLocation: CLLocationManagerDelegate {
  
  // This callback drives the update cycle which ensures we are still connected to a device by testing the last ping time
  public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
    let processedBeacons = beacons.compactMap { XYBluetoothDeviceFactory.build(from: $0.xyiBeaconDefinition, rssi: $0.rssi, updateRssiAndPower: true) }
    self.delegates.forEach {
      $1?.didRangeBeacons(processedBeacons, satisfyingConstraint: device.constraint)
   }
  }
  
  public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard
      let beaconRegion = region as? CLBeaconRegion,
      let device = XYBluetoothDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
      else { return }
    
    
    self.delegates.forEach {
      $1?.deviceEntered(device)
      
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    guard
      let beaconRegion = region as? CLBeaconRegion,
      let device = XYBluetoothDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
      else { return }
    
    self.delegates.forEach {
      $1?.deviceExited(device)
    }
  }
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    // TODO updateStatus()
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    self.delegates.forEach {
      $1?.locationsUpdated(locations.map { XYLocationCoordinate2D($0) })
      
    }
  }
  
  public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    return false
  }
}
#endif
