//
//  XYFinderDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Promises

// A device from the XY family, has an iBeacon and other XY-specific identifiers
public protocol XYFinderDevice: XYBluetoothDevice {
    var uuid: UUID { get }
    var iBeacon: XYIBeaconDefinition? { get }
    var family: XYFinderDeviceFamily { get }
    var prefix: String { get }
    var connectableServices: [CBUUID] { get }
    var location: XYLocationCoordinate2D { get }
    var batteryLevel: Int { get }
    var firmware: String { get }

    // Handlers for button press subscriptions
    func subscribeToButtonPress()
    func unsubscribeToButtonPress()

    // Handle location updates
    func updateLocation(_ newLocation: XYLocationCoordinate2D)

    // Updates to battery level
    func updateBatteryLevel(_ newLevel: Int)

    // Convenience methods for common operations
    @discardableResult func find(_ song: XYFinderSong) -> XYBluetoothResult
    @discardableResult func stayAwake() -> XYBluetoothResult
    @discardableResult func fallAsleep() -> XYBluetoothResult
    @discardableResult func lock() -> XYBluetoothResult
    @discardableResult func unlock() -> XYBluetoothResult
    @discardableResult func version() -> XYBluetoothResult
}

// MARK: Default handler to report the button press should the finder subscribe to the notification
extension XYFinderDeviceBase: XYBluetoothDeviceNotifyDelegate {
    public func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        guard
            // Validate the proper services and the value from the notification, then report
            serviceCharacteristic.characteristicUuid == PrimaryService.buttonState.characteristicUuid ||
            serviceCharacteristic.characteristicUuid == ControlService.button.characteristicUuid,
            let rawValue = value.asInteger,
            let buttonPressed = XYButtonType2.init(rawValue: rawValue)
            else { return }

        XYFinderDeviceEventManager.report(events: [.buttonPressed(device: self, type: buttonPressed)])
    }
}

// MARK: Default implementations of protocol methods and variables
public extension XYFinderDevice {

    var uuid: UUID {
        return self.family.uuid
    }

    var name: String {
        return self.family.familyName
    }

    var prefix: String {
        return self.family.prefix
    }

    func beaconRegion(slot: UInt16) -> CLBeaconRegion {
        return beaconRegion(self.uuid, slot: slot)
    }

    // Builds a beacon region for use in XYLocation based on the current XYIBeaconDefinition
    func beaconRegion(_ uuid: UUID, slot: UInt16? = nil) -> CLBeaconRegion {
        if iBeacon?.hasMinor ?? false, let major = iBeacon?.major, let minor = iBeacon?.minor {
            let computedMinor = slot == nil ? minor : ((minor & 0xfff0) | slot!)
            return CLBeaconRegion(
                proximityUUID: uuid,
                major: major,
                minor: computedMinor,
                identifier: String(format:"%@:4", id))
        }

        if iBeacon?.hasMajor ?? false, let major = iBeacon?.major {
            return CLBeaconRegion(
                proximityUUID: uuid,
                major: major,
                identifier: String(format:"%@:4", id))
        }

        return CLBeaconRegion(
            proximityUUID: uuid,
            identifier: String(format:"%@:4", id))
    }
}
