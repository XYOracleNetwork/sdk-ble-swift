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
    func locationsUpdated(_ locations: [XYLocationCoordinate2D])
}

public class XYLocation: NSObject {

    public static let instance = XYLocation()

    fileprivate let manager = CLLocationManager()

    fileprivate lazy var delegates = [String: XYLocationDelegate?]()

    private override init() {
        super.init()
        self.manager.delegate = self
    }

    public func setDelegate(_ delegate: XYLocationDelegate, key: String) {
        self.delegates[key] = delegate
    }
}

// MARK: Start and stop
public extension XYLocation {

    func start() {
        self.manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.manager.allowsBackgroundLocationUpdates = true
        self.manager.distanceFilter = XYConstants.DEVICE_TUNING_LOCATION_CHANGE_THRESHOLD
        self.manager.requestAlwaysAuthorization()
        self.manager.startUpdatingLocation()
    }

    func stop() {
        self.manager.stopUpdatingLocation()
    }
}

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
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, slot: 4))
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, slot: 7))
        manager.stopRangingBeacons(in: device.beaconRegion(device.uuid, slot: 8))
    }
}

// MARK: Monitoring methods (used for background operation)
public extension XYLocation {

    public func clearMonitoring() {
        self.manager.monitoredRegions.forEach { region in
            self.manager.stopMonitoring(for: region)
        }
    }

    // Convenience method
    public func startMonitoring(for families: [XYFinderDeviceFamily]) {
        families.forEach { startMonitoring(for: $0, isHighPriority: false) }
    }

    func startMonitoring(for family: XYFinderDeviceFamily, isHighPriority: Bool) {
        guard let device = XYFinderDeviceFactory.build(from: family) else { return }
        self.startMonitoring(for: device, isHighPriority: isHighPriority)
    }

    func startMonitoring(for devices: [XYFinderDevice]) {
        // Get the existing regions that location manager is looking for
        let monitoredDevices = manager.monitoredRegions
            .compactMap { $0 as? CLBeaconRegion }
            .filter { $0.minor != nil && $0.major != nil }
            .compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition ) }

        // Remove devices from monitored that are not on the list
        monitoredDevices.filter { device in !devices.contains(where: { $0.id == device.id }) }.forEach { self.stopMonitoring(for: $0) }

        // Add unmonitored devices
        devices.filter { device in !monitoredDevices.contains(where: { $0.id == device.id }) }.forEach { self.startMonitoring(for: $0, isHighPriority: false) }
    }

    func startMonitoring(for device: XYFinderDevice, isHighPriority: Bool) {
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

    public func stopMonitoring(for device: XYFinderDevice) {
        manager.stopMonitoring(for: device.beaconRegion(device.uuid, slot: 4))
        manager.stopMonitoring(for: device.beaconRegion(device.uuid, slot: 7))
        manager.stopMonitoring(for: device.beaconRegion(device.uuid, slot: 8))
    }

}

// MARK: CLLocationManagerDelegate
extension XYLocation: CLLocationManagerDelegate {

    // This callback drives the update cycle which ensures we are still connected to a device by testing the last ping time
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.delegates.forEach { $1?.didRangeBeacons(
            beacons.compactMap { XYFinderDeviceFactory.build(from: $0.xyiBeaconDefinition, rssi: $0.rssi) },
            for: region.family
        )}
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard
            let beaconRegion = region as? CLBeaconRegion,
            let device = XYFinderDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
            else { return }

        self.delegates.forEach { $1?.deviceEntered(device) }
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard
            let beaconRegion = region as? CLBeaconRegion,
            let device = XYFinderDeviceFactory.build(from: beaconRegion.xyiBeaconDefinition)
            else { return }

        self.delegates.forEach { $1?.deviceExited(device) }
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // TODO updateStatus()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.delegates.forEach { $1?.locationsUpdated(locations.map { XYLocationCoordinate2D($0) }) }
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return false
    }

}
