//
//  XYLocation.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreLocation
import CoreBluetooth

public protocol XYLocationDelegate: class {
    func didRangeBeacons(_ beacons: [XYFinderDevice], for family: XYFinderDeviceFamily?)
    func deviceEntered(_ device: XYFinderDevice)
    func deviceExited(_ device: XYFinderDevice)
    func deviceExiting(_ device: XYFinderDevice)
    func locationsUpdated(_ locations: [XYLocationCoordinate2D2])
}

public class XYLocation: NSObject {

    public static let instance = XYLocation()

    fileprivate let manager = CLLocationManager()

    fileprivate weak var delegate: XYLocationDelegate?

    private override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        manager.delegate = self
    }

    public func setDelegate(_ delegate: XYLocationDelegate) {
        self.delegate = delegate
    }
}

// MARK: Ranging methods (used for foreground operations)
extension XYLocation {

    // Convenience method
    public func startRanging(for families: [XYFinderDeviceFamily]) {
        families.forEach { startRangning(for: $0) }
    }

    // Start ranging for a particular type of XY device
    public func startRangning(for family: XYFinderDeviceFamily) {
        guard let device = XYFinderDeviceFactory.build(from: family) else { return }
        self.startRanging(for: device)
    }

    public func startRangning(for devices: [XYFinderDevice]) {
        // Get the existing regions that location manager is looking for
        let rangedDevices = manager.rangedRegions
            .compactMap { $0 as? CLBeaconRegion }
            .filter { $0.minor != nil && $0.major != nil }
            .compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition ) }

        // Remove devices from rangning that are not on the list
        rangedDevices.filter { device in !devices.contains(where: { $0.id == device.id }) }.forEach { self.stopRanging(for: $0) }

        // Add unranged devices
        devices.filter { device in !rangedDevices.contains(where: { $0.id == device.id }) }.forEach { self.startRanging(for: $0) }
    }

    public func startRanging(for device: XYFinderDevice) {
        let beaconRegion = CLBeaconRegion(proximityUUID: device.uuid, identifier: device.id)
        manager.startRangingBeacons(in: beaconRegion)
    }

    public func clearRanging() {
        manager.rangedRegions
            .compactMap { $0 as? CLBeaconRegion }
            .forEach { manager.stopRangingBeacons(in: $0) }
    }

    public func stopRanging(for device: XYFinderDevice) {
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, id: device.id, slot: 4))
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, id: device.id, slot: 7))
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, id: device.id, slot: 8))
    }
}

// MARK: Monitoring methods (used for background operation)
extension XYLocation {

}

// MARK: CLLocationManagerDelegate
extension XYLocation: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.delegate?.didRangeBeacons(
            beacons.compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition, rssi: $0.rssi) },
            for: region.family
        )
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
        self.delegate?.locationsUpdated(locations.map { XYLocationCoordinate2D2($0) })
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return false
    }

}
