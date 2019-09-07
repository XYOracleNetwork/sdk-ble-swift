//
//  RangedDevicesManager.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth
import XyBleSdk
import Promises

protocol RangedDevicesManagerDelegate: class {
  func reloadTableView()
  func showDetails()
  func buttonPressed(on device: XYBluetoothDevice)
  func stateChanged(_ newState: CBManagerState)
  func deviceDisconnected(device: XYBluetoothDevice)
}

class RangedDevicesManager: NSObject {
  
  fileprivate let scanner = XYSmartScan.instance
  
  fileprivate(set) var rangedDevices = [TableSection: [XYBluetoothDevice]]()
  fileprivate(set) var selectedDevice: XYFinderDevice?
  
  fileprivate weak var delegate: RangedDevicesManagerDelegate?
  
  fileprivate(set) var subscriptionUuid: UUID?
  
  fileprivate(set) var xyFinderFamilyFilter: [XYDeviceFamily]
  
  public var
  rssiRangeToDisplay: Int = -95,
  showAlerts: Bool = true
  
  public var testDevices = [String: Bool]()
  
  static let instance = RangedDevicesManager()
  
  private override init() {
    XY2BluetoothDeviceCreator.enable(enable: true)
    XY2BluetoothDevice.family.enable(enable: true)
    XY3BluetoothDeviceCreator.enable(enable: true)
    XY3BluetoothDevice.family.enable(enable: true)
    XY4BluetoothDeviceCreator.enable(enable: true)
    XY4BluetoothDevice.family.enable(enable: true)
    XYGPSBluetoothDeviceCreator.enable(enable: true)
    XYGPSBluetoothDevice.family.enable(enable: true)
    XYMobileBluetoothDeviceCreator.enable(enable: true)
    XYMobileBluetoothDevice.family.enable(enable: true)
    
    
    self.xyFinderFamilyFilter = XYDeviceFamily.allFamlies()
    
    super.init()
    self.scanner.setDelegate(self, key: "RangedDevicesManager")
    
    
    // Subscribe to various events
    self.subscriptionUuid = XYFinderDeviceEventManager.subscribe(to: [.buttonPressed, .connected, .connectionError, .disconnected]) { event in
      guard let currentDevice = self.selectedDevice, currentDevice == event.device else { return }
      switch event {
      case .buttonPressed:
        self.delegate?.buttonPressed(on: currentDevice)
      case .connected:
        DispatchQueue.main.async {
          self.delegate?.showDetails()
        }
      case .disconnected, .connectionError:
        DispatchQueue.main.async {
          self.delegate?.deviceDisconnected(device: currentDevice)
        }
      default:
        break
      }
    }
  }
  
  func setDelegate(_ delegate: RangedDevicesManagerDelegate) {
    self.delegate = delegate
  }
  
  func start() {
    self.scanner.start(for: self.xyFinderFamilyFilter, mode: .foreground)
    self.scanner.setDelegate(self, key: "RangedDevicesManager")
  }
  
  func stop() {
    rangedDevices.removeAll()
    self.delegate?.reloadTableView()
    scanner.stop()
  }
  
  /*func startRanging() {
   if central.state != .poweredOn {
   central.setDelegate(self, key: "RangedDevicesManager")
   central.enable()
   } else {
   self.scanner.start(for: self.xyFinderFamilyFilter, mode: .foreground)
   }
   }
   
   func stopRanging() {
   guard central.state == .poweredOn else { return }
   rangedDevices.removeAll()
   self.delegate?.reloadTableView()
   scanner.stop()
   }
   
   func startMonitoring() {
   if central.state != .poweredOn {
   central.setDelegate(self, key: "RangedDevicesManager")
   central.enable()
   } else {
   self.scanner.start(for: self.xyFinderFamilyFilter, mode: .background)
   }
   }
   
   func stopMonitoring() {
   guard central.state == .poweredOn else { return }
   scanner.stop()
   }*/
  
  func connect(for section: TableSection?, deviceIndex: NSInteger) {
    
    guard
      let section = section,
      let device = self.rangedDevices[section]?[safe: deviceIndex]
      else { return }
    
    // todo
    
    self.selectedDevice = device as? XYFinderDevice
    
    
    if (self.selectedDevice != nil) {
      device.connect()
    }
  }
  
  func disconnect() {
    guard let device = selectedDevice else { return }
    device.disconnect()
    self.selectedDevice = nil
  }
}

extension RangedDevicesManager {
  
  func toggleFamilyFilter(for family: XYDeviceFamily) {
    if xyFinderFamilyFilter.contains(where: { (XYDeviceFamily) -> Bool in
      (XYDeviceFamily).familyName == family.familyName
    }) {
      self.xyFinderFamilyFilter.removeAll(where: { $0.familyName == family.familyName })
    } else {
      self.xyFinderFamilyFilter.append(family)
    }
  }
  
}

extension RangedDevicesManager: UITableViewDataSource {
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return TableSection.values.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard
      let tableSection = TableSection(rawValue: section),
      let devices = self.rangedDevices[tableSection] else { return 0 }
    
    return devices.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "rangedDeviceCell") as! RangedDeviceTableViewCell
    
    guard
      let section = TableSection(rawValue: indexPath.section),
      let device = rangedDevices[section]?[indexPath.row]
      else { return cell }
    
    let directive = RangedDeviceCellDirective(
      name:  device.family.familyName,
      major: device.iBeacon?.major ?? 0,
      rssi: device.rssi,
      uuid: device.family.uuid,
      connected: false,
      minor: device.iBeacon?.minor ?? 0,
      pulses: device.totalPulseCount,
      minRssi: device.rssiRange.min,
      maxRssi: device.rssiRange.max)
    
    cell.populate(from: directive)
    cell.accessoryType = device.powerLevel == UInt(8) ? .checkmark : .none
    return cell
  }
}

/*extension RangedDevicesManager: XYCentralDelegate {
 func located(peripheral: XYPeripheral) {}
 func connected(peripheral: XYPeripheral) {}
 func timeout() {}
 func couldNotConnect(peripheral: XYPeripheral) {}
 func disconnected(periperhal: XYPeripheral) {}
 
 func stateChanged(newState: CBManagerState) {
 if newState == .poweredOn {
 self.scanner.start(for: self.xyFinderFamilyFilter, mode: .foreground)
 }
 
 DispatchQueue.main.async {
 self.delegate?.stateChanged(newState)
 }
 }
 }*/

extension RangedDevicesManager: XYSmartScanDelegate {
  
  func smartScan(detected devices: [XYBluetoothDevice], family: XYDeviceFamily) {
    DispatchQueue.main.async {
      // Filter out devices not in the specified range and sort by rssi
      var inRange = devices
      
      if self.rssiRangeToDisplay != 0 {
        inRange = devices.filter { $0.rssi >= self.rssiRangeToDisplay && $0.rssi != 0 }
      }
      inRange = inRange.sorted(by: { ($0.powerLevel, $0.rssi) > ($1.powerLevel, $1.rssi) } )
      
      // Group up the values into the appropriate table section and reload the view
      let group = Dictionary(grouping: inRange, by: { $0.family.toTableSection! })
      if let family = group.keys.first {
        group.count > 0 ? self.rangedDevices[family] = group[family] : self.rangedDevices[family]?.removeAll()
        self.delegate?.reloadTableView()
      }
    }
  }
  
  func smartScan(status: XYSmartScanStatus) {    }
  func smartScan(entered device: XYBluetoothDevice) {    }
  func smartScan(exiting device: XYBluetoothDevice) {    }
  func smartScan(location: XYLocationCoordinate2D) {    }
  func smartScan(detected device: XYBluetoothDevice, rssi: Int, family: XYDeviceFamily) {    }
  func smartScan(exited device: XYBluetoothDevice) {    }
}
