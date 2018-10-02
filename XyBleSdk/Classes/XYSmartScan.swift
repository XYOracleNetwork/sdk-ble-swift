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
    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily)
    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily)
    func smartScan(entered device: XYFinderDevice)
//    func smartScan(exiting device:XYBluetoothDevice)
    func smartScan(exited device: XYFinderDevice)
//    func smartScan(updated device:XYBluetoothDevice)
}

public class XYSmartScan {

    public static let instance = XYSmartScan()

    fileprivate var delegates = [String: XYSmartScanDelegate?]()

    fileprivate var trackedDevices = [String: XYFinderDevice]()

    fileprivate let location = XYLocation.instance

    private init() {
        location.setDelegate(self)
    }

    public func start(for families: [XYFinderDeviceFamily]) {
        // TODO investigate threading on main
        // TODO BG vs FG mode, just FG for now

        location.startRanging(for: families)

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

    func startTracking(for device: XYFinderDevice) {
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
//        var devices = Set<XYFinderDevice>()
//        trackedDevices.forEach { (arg) in
//            let (_, device) = arg
//            devices.insert(device)
//        }
//
//        // TODO BG mode is monitoring
//        location.startRangning(for: devices)
    }
}

// MARK: BLELocationDelegate - Location monitoring and ranging delegates
extension XYSmartScan: XYLocationDelegate {

    public func locationsUpdated(_ locations: [XYLocationCoordinate2D]) {
        locations.forEach { location in
            self.delegates.forEach { $1?.smartScan(location: location) }
        }
    }

    public func didRangeBeacons(_ beacons: [XYFinderDevice], for family: XYFinderDeviceFamily?) {
        guard let family = family else { return }
        beacons.forEach { beacon in
            self.delegates.forEach { $1?.smartScan(detected: beacon, signalStrength: beacon.rssi, family: family)}
        }

        self.delegates.forEach { $1?.smartScan(detected: beacons, family: family) }
    }

    public func deviceEntered(_ device: XYFinderDevice) {
        self.delegates.forEach { $1?.smartScan(entered: device) }
    }

    public func deviceExited(_ device: XYFinderDevice) {
        self.delegates.forEach { $1?.smartScan(exited: device) }
    }
    
}
