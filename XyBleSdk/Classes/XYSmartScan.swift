//
//  XYSmartScan.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation

public protocol XYSmartScanDelegate {
    func smartScan(status: XYSmartScanStatus)
    func smartScan(location: XYLocationCoordinate2D)
    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily)
    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily)
    func smartScan(entered device: XYFinderDevice)
    func smartScan(exiting device:XYBluetoothDevice)
    func smartScan(exited device: XYFinderDevice)
}

public enum XYSmartScanStatus: Int {
    case none
    case enabled
    case bluetoothUnavailable
    case bluetoothDisabled
    case backgroundLocationDisabled
    case locationDisabled
}

public enum XYSmartScan2Mode {
    case foreground
    case background
}

public class XYSmartScan {

    public static let instance = XYSmartScan()

    fileprivate var delegates = [String: XYSmartScanDelegate?]()

    fileprivate var trackedDevices = [String: XYFinderDevice]()

    fileprivate let location = XYLocation.instance

    public fileprivate(set) var currentLocation = XYLocationCoordinate2D()
    public fileprivate(set) var currentStatus = XYSmartScanStatus.none
    fileprivate var isActive: Bool = false

    public fileprivate(set) var mode: XYSmartScan2Mode = .background

    fileprivate var isCheckingExits: Bool = false

    internal static let queue = DispatchQueue(label: String(format: "com.xyfindables.sdk.XYSmartScan"))

    private init() {
        self.location.setDelegate(self, key: "XYSmartScan")
    }

    public func start(for families: [XYFinderDeviceFamily] = XYFinderDeviceFamily.valuesToRange, mode: XYSmartScan2Mode) {
        if mode == self.mode { return }

        self.location.start()

        switch mode {
        case .foreground: self.switchToForeground(families)
        case .background: self.switchToBackground(families)
        }

        self.isActive = true
    }

    public func stop() {
        guard isActive else { return }

        self.location.stop()

        self.location.clearMonitoring()
        self.location.clearRanging()
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
        XYFinderDeviceFactory.invalidateCache()
    }
}

// MARK: Change monitoring state based on start/stop
fileprivate extension XYSmartScan {

    func switchToForeground(_ families: [XYFinderDeviceFamily]) {
        guard self.mode == .background else { return }

        self.mode = .foreground
        self.location.clearMonitoring()
        self.location.startRanging(for: families)
        self.isCheckingExits = true
        self.checkExits()
        self.updateTracking()
        self.updateStatus()
    }

    func switchToBackground(_ families: [XYFinderDeviceFamily]) {
        guard self.mode == .foreground else { return }

        self.mode = .background
        self.location.clearRanging()
        self.isCheckingExits = false
        self.location.startMonitoring(for: families)
        self.updateTracking()
        self.updateStatus()
    }

}

// MARK: Status updates
extension XYSmartScan {

    public func updateStatus() {
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
            newStatus = .none;
        case .poweredOn:
            break
        case .poweredOff:
            newStatus = .bluetoothDisabled
        case .unsupported:
            newStatus = .bluetoothUnavailable
        case .unauthorized:
            newStatus = .backgroundLocationDisabled
        case .resetting:
            newStatus = .none
        }

        if self.currentStatus != newStatus {
            self.currentStatus = newStatus
            // Currently used only by the app for displaying BLE status
            self.delegates.map { $1 }.forEach { $0?.smartScan(status: self.currentStatus)}
        }
    }

}

// MARK: Tracking wranglers for known devices
public extension XYSmartScan {

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

    private func updateTracking() {
        self.mode == .foreground ?
            location.startRangning(for: self.trackedDevices.map { $1 } ) :
            location.startMonitoring(for: self.trackedDevices.map { $1 } )
    }

    // Another recursive method for checking exits of devices so we can alter the user
    private func checkExits() {
        XYSmartScan.queue.asyncAfter(deadline: DispatchTime.now() + TimeInterval(XYConstants.DEVICE_TUNING_SECONDS_EXIT_CHECK_INTERVAL)) {
            guard self.isCheckingExits else {
                return
            }

            // Loop through known devices that are connected
            for device in XYDeviceConnectionManager.instance.connectedDevices {
                guard
                    let xyDevice = device as? XYFinderDevice,
                    let lastPulseTime = device.lastPulseTime,
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

// MARK: BLELocationDelegate - Location monitoring and ranging delegates
extension XYSmartScan: XYLocationDelegate {
    public func deviceExiting(_ device: XYFinderDevice) {
        self.delegates.forEach { $1?.smartScan(exiting: device) }
    }

    public func locationsUpdated(_ locations: [XYLocationCoordinate2D]) {
        locations.forEach { location in
            self.delegates.forEach { $1?.smartScan(location: location) }
            XYFinderDeviceFactory.updateDeviceLocations(location)
        }
    }

    public func didRangeBeacons(_ beacons: [XYFinderDevice], for family: XYFinderDeviceFamily?) {
        guard let family = family else { return }

        // Get the unique buttons that got pressed
        let buttonPressedBeacons = beacons.filter { $0.powerLevel == 8 }.reduce([], { initial, beacon in
            initial.contains(where: { $0.id == beacon.id }) ? initial : initial + [beacon]
        })

        // Get the unique buttons that didn't get pressed
        let buttonNotPressedBeacons = beacons.filter { $0.powerLevel != 8 }.reduce([], { initial, beacon in
            initial.contains(where: { $0.id == beacon.id }) ? initial : initial + [beacon]
        })

        let uniqueBeacons = buttonPressedBeacons + buttonNotPressedBeacons

        uniqueBeacons.forEach { beacon in
            if !beacon.inRange {
                self.delegates.forEach { $1?.smartScan(entered: beacon)}
                XYFinderDeviceEventManager.report(events: [.entered(device: beacon)])
            }

            self.delegates.forEach {
                $1?.smartScan(detected: beacon, signalStrength: beacon.rssi, family: family)
            }

            // Handles button presses and other notifications
            beacon.detected()
        }

        self.delegates.forEach { $1?.smartScan(detected: uniqueBeacons, family: family) }
    }

    public func deviceEntered(_ device: XYFinderDevice) {
        self.delegates.forEach { $1?.smartScan(entered: device) }
        print("MONITOR ENTER: Device \(device.id)")
        device.cancelMonitorTimer()
    }

    public func deviceExited(_ device: XYFinderDevice) {
        self.delegates.forEach { $1?.smartScan(exited: device) }
        print("MONITOR EXIT: Device \(device.id)")
        device.startMonitorTimer()
    }
    
}
