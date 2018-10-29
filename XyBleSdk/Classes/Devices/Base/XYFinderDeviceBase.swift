//
//  XYFinderDeviceBase.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/18/18.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Promises

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

    public func detected() {
        var events: [XYFinderEventNotification] = [.detected(device: self, powerLevel: Int(self.powerLevel), signalStrength: self.rssi, distance: 0)]

        // If the button has been pressed on a compatible devices, we add the appropriate event
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

        //        if self.registered {
        //            reportUpdated();
        //        }

        if stayConnected && connected == false {
            self.connect()
        }

        XYFinderDeviceEventManager.report(events: events)
    }

    // Handles the xy1 and xy2 cases
    public func subscribeToButtonPress() {}
    public func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
        return XYBluetoothResult.empty
    }

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

    @discardableResult public func isAwake() -> XYBluetoothResult {
        switch self.family {
        case .xy1, .xy2:
            return XYBluetoothResult(data: Data([0x01]))
        default:
            return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        }
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
