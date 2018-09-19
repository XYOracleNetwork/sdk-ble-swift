//
//  XYSmartScan.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public protocol XYSmartScanDelegate {
//    func smartScan(status:cXYSmartScanStatus)
    func smartScan(location: XYLocationCoordinate2D)
    func smartScan(detected device: XY4BluetoothDevice, signalStrength: Int)
    func smartScan(entered device: XYBluetoothDevice)
//    func smartScan(exiting device:XYBluetoothDevice)
    func smartScan(exited device: XYBluetoothDevice)
//    func smartScan(updated device:XYBluetoothDevice)
}

public class XYSmartScan {

    public static let instance = XYSmartScan()

    fileprivate var delegates = [String: XYSmartScanDelegate?]()

    fileprivate var trackedDevices = [String: XYBluetoothDevice]()

    fileprivate let location = XYLocation.instance

    private init() {
        location.setDelegate(self)
    }

    public func start() {
        // TODO investigate threading on main
        // TODO BG vs FG mode, just FG for now

        location.startRanging(for: [.xy4])

        // TODO find devices from tracked devices
    }

    public func stop() {
        location.clearRanging()
        // TODO clear tracked devices
    }

    public func setDelegate(_ delegate: XYSmartScanDelegate, key: String) {
        self.delegates[key] = delegate
    }

    public func removeDelegate(for key: String) {
        self.delegates.removeValue(forKey: key)
    }
}

// MARK: Tracking wranglers for known devices
extension XYSmartScan {

    func startTracking(for device: XYBluetoothDevice) {
        guard trackedDevices[device.id] == nil else { return }
        trackedDevices[device.id] = device
        updateTracking()
    }

    func stopTracking(for deviceId: String) {
        guard trackedDevices[deviceId] != nil else { return }
        trackedDevices.removeValue(forKey: deviceId)
        updateTracking()
    }

    private func updateTracking() {
        // TODO look into reduce here...
        var devices = Set<XYBluetoothDevice>()
        trackedDevices.forEach { (arg) in
            let (_, device) = arg
            devices.insert(device)
        }

        // TODO BG mode is monitoring
        location.startRangning(for: devices)
    }
}

// MARK: BLELocationDelegate - Location monitoring and ranging delegates
extension XYSmartScan: XYLocationDelegate {

    public func locationsUpdated(_ locations: [XYLocationCoordinate2D]) {
        locations.forEach { location in
            self.delegates.forEach { $1?.smartScan(location: location) }
        }
    }

    public func didRangeBeacons(_ beacons: [XYBluetoothDevice]) {
        beacons.forEach { beacon in
            if beacon.inRange {
                // TODO report in range
                print("I am in range")
            }

            if beacon.powerLevel == UInt(8) { print("found it \(beacon.id)") }

            if let xy4iBeacon = beacon as? XY4BluetoothDevice {
                self.delegates.forEach { $1?.smartScan(detected: xy4iBeacon, signalStrength: beacon.rssi)}
            }
        }
    }

    public func deviceEntered(_ device: XYBluetoothDevice) {
        self.delegates.forEach { $1?.smartScan(entered: device) }
    }

    public func deviceExited(_ device: XYBluetoothDevice) {
        self.delegates.forEach { $1?.smartScan(exited: device) }
    }
    
}
