//
//  XYSmartScan.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

//public protocol XYSmartScanDelegate {
//    func smartScan(_ smartScan:XYSmartScan!, status:XYSmartScanStatus)
//    func smartScan(_ smartScan:XYSmartScan!, location:XYLocationCoordinate2D)
//    func smartScan(_ smartScan:XYSmartScan!, detected device: XYDevice!, signalStrength: Int)
//    func smartScan(_ smartScan:XYSmartScan!, entered device:XYDevice!)
//    func smartScan(_ smartScan:XYSmartScan!, exiting device:XYDevice!)
//    func smartScan(_ smartScan:XYSmartScan!, exited device:XYDevice!)
//    func smartScan(_ smartScan:XYSmartScan!, updated device:XYDevice!)
//}

public class XYSmartScan {

    public static let instance = XYSmartScan()

    fileprivate var trackedDevices = [String: XYBluetoothDevice]()

    fileprivate let location = BLELocation.instance

    private init() {
        location.setDelegate(self)
    }

    public func start() {
        // TODO investigate threading on main
        // TODO BG vs FG mode, just FG for now

        location.startRanging(for: [.xy4])

        // TODO find devices from tracked devices

        location.startRangning(for: [])
    }

    public func stop() {
        location.clearRanging()
        // TODO clear tracked devices
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
extension XYSmartScan: BLELocationDelegate {

    public func locationsUpdated(_ locations: [XYLocationCoordinate2D]) {
        
    }

    public func didRangeBeacons(_ beacons: [XYBluetoothDevice]) {
        beacons.forEach { beacon in
            if beacon.inRange {
                // TODO report in range
                print("I am in range")
            }

            // TODO Report powerlevel

            if beacon.powerLevel == UInt(8) { print("found it \(beacon.id)") }

//            if beacon.powerLevel == 8, let device = beacon as? XYFinderDevice {
//                print(device.iBeacon!.xyId(from: .xy4))
//            }
        }
    }

    public func deviceEntered(_ device: XYBluetoothDevice) {

    }

    public func deviceExited(_ device: XYBluetoothDevice) {

    }
    
}

// MARK: Handle connections to devices
extension XYSmartScan {

}
