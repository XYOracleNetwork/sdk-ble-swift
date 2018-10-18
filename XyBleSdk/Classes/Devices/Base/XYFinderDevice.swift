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

// The base XYFinder class
public class XYFinderDeviceBase: XYBluetoothDeviceBase, XYFinderDevice {
    public let
    iBeacon: XYIBeaconDefinition?,
    family: XYFinderDeviceFamily

    public fileprivate(set) var
    location: XYLocationCoordinate2D = XYLocationCoordinate2D(),
    batteryLevel: Int = -1,
    firmware: String = ""

    public init(_ family: XYFinderDeviceFamily, id: String, iBeacon: XYIBeaconDefinition?, rssi: Int) {
        self.family = family
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    // Ensures we only fire the button press once when it is detected for 30 seconds
    // TODO find a better way to handle this
    fileprivate static let buttonTimeout: DispatchTimeInterval = .seconds(30)
    fileprivate static let buttonTimerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceButtonTimerQueue")
    fileprivate var buttonTimer: DispatchSourceTimer?

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid() -> CBUUID {
            let uuidSource = family.connectableSourceUuid
            let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uuidSource?.getBytes(uuidBytes)
            for i in (0...11) {
                uuidBytes[i] = uuidBytes[i + 4];
            }
            uuidBytes[13] = UInt8(major & 0x00ff)
            uuidBytes[12] = UInt8((major & 0xff00) >> 8)
            uuidBytes[15] = UInt8(minor & 0x00f0) | 0x04
            uuidBytes[14] = UInt8((minor & 0xff00) >> 8)

            return CBUUID(data: Data(bytes:uuidBytes, count:16))
        }

        return [XYFinderDeviceFamily.powerLow, XYFinderDeviceFamily.powerHigh].map { _ in getServiceUuid() }
    }

    // Each time a device is loaded/fetched from the factory, this method will get fired, as well as
    // each time the RSSI value is read from the peripheral callback
    override public func update(_ rssi: Int, powerLevel: UInt8) {
        super.update(rssi, powerLevel: powerLevel)

        var events: [XYFinderEventNotification] = [
            .detected(device: self, powerLevel: Int(self.powerLevel), signalStrength: self.rssi, distance: 0),
            .updated(device: self)]

        if powerLevel == 8, (family == .xy4 || family == .xy3 || family == .xygps) {
            if buttonTimer == nil {
                self.buttonTimer = DispatchSource.singleTimer(interval: XYFinderDeviceBase.buttonTimeout, queue: XYFinderDeviceBase.buttonTimerQueue) { [weak self] in
                    guard let strong = self else { return }
                    strong.buttonTimer = nil
                }

                events.append(.buttonPressed(device: self, type: .single))
            } else {
                events.append(.buttonRecentlyPressed(device: self, type: .single))
            }
        }

        XYFinderDeviceEventManager.report(events: events)
    }

    // Handles the xy1 and xy2 cases
    public func subscribeToButtonPress() {}
    public func unsubscribeToButtonPress() {}

    public func updateLocation(_ newLocation: XYLocationCoordinate2D) {
        self.location = newLocation
    }

    public func updateBatteryLevel(_ newLevel: Int) {
        self.batteryLevel = newLevel
    }

    @discardableResult public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func stayAwake() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func fallAsleep() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func lock() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func unlock() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func version() -> XYBluetoothResult {
        switch self.family {
        case .xy1:
            self.firmware = "1.0"
            fallthrough
        case .xy2:
            self.firmware = "2.0"
            return XYBluetoothResult(data: self.firmware.data(using: .utf8))
        default:
            return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        }
    }

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
