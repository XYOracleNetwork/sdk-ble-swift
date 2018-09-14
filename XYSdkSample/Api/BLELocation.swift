//
//  BLELocation.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreLocation
import CoreBluetooth

public protocol BLELocationDelegate: class {
    func didRangeBeacons(_ beacons: [XYBluetoothDevice])
    func deviceEntered(_ device: XYBluetoothDevice)
    func deviceExited(_ device: XYBluetoothDevice)
    func locationsUpdated(_ locations: [XYLocationCoordinate2D])
}

public class BLELocation: NSObject {

    public static let instance = BLELocation()

    fileprivate let manager = CLLocationManager()

    fileprivate weak var delegate: BLELocationDelegate?

    private override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        manager.delegate = self
    }

    public func setDelegate(_ delegate: BLELocationDelegate) {
        self.delegate = delegate
    }

}

// MARK: Ranging methods (used for foreground operations)
extension BLELocation {

    public func startRanging(for families: [XYFinderDeviceFamily]) {
        families.forEach { startRangning(for: $0) }
    }

    public func startRangning(for family: XYFinderDeviceFamily) {
        guard let device = XYFinderDeviceFactory.build(from: family) else { return }
        startRanging(for: device)
    }

    public func stopRanging(for family: XYFinderDeviceFamily) {
        // TODO not used in old app, should be?
    }

    public func startRangning(for devices: Set<XYBluetoothDevice>) {
        let rangedDevices = manager.rangedRegions
            .compactMap { $0 as? CLBeaconRegion }
            .filter { $0.minor != nil && $0.major != nil }
            .compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition ) }

        // Remove devices from rangning that are not on the list
        Set<XYBluetoothDevice>.init(rangedDevices).subtracting(devices).forEach { self.stopRanging(for: $0) }

        // Add unranged devices
        Set<XYBluetoothDevice>.init(devices).subtracting(rangedDevices).forEach { self.startRanging(for: $0) }
    }

    public func startRanging(for device: XYBluetoothDevice) {
        let beaconRegion = CLBeaconRegion(proximityUUID: device.uuid, identifier: device.id)
        manager.startRangingBeacons(in: beaconRegion)
    }

    public func clearRanging() {
        manager.rangedRegions
            .compactMap { $0 as? CLBeaconRegion }
            .forEach { manager.stopRangingBeacons(in: $0) }
    }

    public func stopRanging(for device: XYBluetoothDevice) {
        guard let finder = device as? XYFinderDevice else { return }
        manager.stopRangingBeacons(in: finder.beaconRegion(device.uuid, id: device.id, slot: 4))
        manager.stopRangingBeacons(in: finder.beaconRegion(device.uuid, id: device.id, slot: 7))
        manager.stopRangingBeacons(in: finder.beaconRegion(device.uuid, id: device.id, slot: 8))
    }
}

// MARK: Monitoring methods (used for background operation)
extension BLELocation {

}

// MARK: CLLocationManagerDelegate
extension BLELocation: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.delegate?.didRangeBeacons(beacons.compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition) })
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard
            let beaconRegion = region as? CLBeaconRegion,
            let device = XYFinderDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
            else { return }

        self.delegate?.deviceEntered(device)
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard
            let beaconRegion = region as? CLBeaconRegion,
            let device = XYFinderDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
            else { return }

        self.delegate?.deviceExited(device)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // TODO updateStatus()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.delegate?.locationsUpdated(locations.map { XYLocationCoordinate2D($0) })
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return false
    }
}
