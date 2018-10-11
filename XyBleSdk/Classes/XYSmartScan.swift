//
//  XYSmartScan.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public protocol XYSmartScan2Delegate {
//    func smartScan(status:cXYSmartScanStatus)
    func smartScan(location: XYLocationCoordinate2D2)
    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily)
    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily)
    func smartScan(entered device: XYFinderDevice)
//    func smartScan(exiting device:XYBluetoothDevice)
    func smartScan(exited device: XYFinderDevice)
//    func smartScan(updated device:XYBluetoothDevice)
}

public class XYSmartScan2 {

    public static let instance = XYSmartScan2()

    fileprivate var delegates = [String: XYSmartScan2Delegate?]()

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
    }

    public func setDelegate(_ delegate: XYSmartScan2Delegate, key: String) {
        self.delegates[key] = delegate
    }

    public func removeDelegate(for key: String) {
        self.delegates.removeValue(forKey: key)
    }
}

// MARK: Tracking wranglers for known devices
extension XYSmartScan2 {

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
extension XYSmartScan2: XYLocationDelegate {

    public func locationsUpdated(_ locations: [XYLocationCoordinate2D2]) {
        locations.forEach { location in
            self.delegates.forEach { $1?.smartScan(location: location) }
        }
    }

    public func didRangeBeacons(_ beacons: [XYFinderDevice], for family: XYFinderDeviceFamily?) {
        guard let family = family else { return }
        beacons.forEach { beacon in
            if beacon.inRange {
//                self.delegates.forEach { $1?.smartScan(entered: beacon)}
            }

            self.delegates.forEach {
                $1?.smartScan(detected: beacon, signalStrength: beacon.rssi, family: family)
                beacon.update(beacon.rssi, powerLevel: UInt8(4))
            }
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
