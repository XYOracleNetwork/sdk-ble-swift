//
//  XYFinderDeviceBase.swift
//  XYBleSdk
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
    isRegistered: Bool = false,
    batteryLevel: Int = -1,
    firmware: String = ""

    internal var handlingButtonPress: Bool = false

    public init(_ family: XYFinderDeviceFamily, id: String, iBeacon: XYIBeaconDefinition?, rssi: Int) {
        self.family = family
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    fileprivate static let buttonTimeout: DispatchTimeInterval = .seconds(30)
    fileprivate static let buttonTimerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceButtonTimerQueue")
    fileprivate var buttonTimer: DispatchSourceTimer?

    fileprivate static let monitorTimeout: DispatchTimeInterval = .seconds(10)
    fileprivate static let monitorTimerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceMonitorTimerQueue")
    fileprivate var monitorTimer: DispatchSourceTimer?

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

    public func getRegistrationFlag() {
        if !self.unlock().hasError {
            let result = self.isAwake()
            if !result.hasError, let value = result.asByteArray, value.count > 0 {
                self.isRegistered = value[0] != 0x00
            }
        }
    }

    // If while we are monitoring the device we detect it has exited, we start a timer as a device may have just
    // triggered the exit while still being close by. Once the timer expires before it enters, we fire the notification
    public func startMonitorTimer() {
        if monitorTimer == nil {
            self.monitorTimer = DispatchSource.singleTimer(interval: XYFinderDeviceBase.monitorTimeout, queue: XYFinderDeviceBase.monitorTimerQueue) { [weak self] in
                guard let strong = self else { return }
                print("MONITOR TIMER EXPIRE: Device \(strong.id)")
                if strong.iBeacon?.hasMajor ?? false && strong.iBeacon?.hasMinor ?? false {
                    strong.verifyExit()
                }
            }
        }
    }

    // If the device enters while monitoring, we always cancel the timer and report it is back
    public func cancelMonitorTimer() {
        self.monitorTimer = nil
        XYFinderDeviceEventManager.report(events: [.entered(device: self)])
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
            }
        }

        if self.isRegistered {
            XYFinderDeviceEventManager.report(events: [.updated(device: self)])
        }

        if stayConnected && connected == false {
            self.connect()
        }

        XYFinderDeviceEventManager.report(events: events)
    }

    public override func verifyExit(_ callback:((_ exited: Bool) -> Void)? = nil) {
        // If we're connected poke the device
        guard self.peripheral?.state != .connected else {
            peripheral?.readRSSI()
            return
        }

        // We set the proximity to none to ensure the visual meters pick up the change,
        // and change last pulse time to nil so this method is not picked up again by
        // checkExits()
        self.rssi = XYDeviceProximity.defaultProximity
        self.lastPulseTime = nil

        // We will only report this when the app is in the foreground, as monitoring
        // will handle the messaging while in the background
        // if XYSmartScan.instance.mode == .foreground {
            XYFinderDeviceEventManager.report(events: [.exited(device: self)])
        // }

        // We put the device in the wait queue so it auto-reconnects when it comes back
        // into range. This works only while the app is in the foreground/background
        XYDeviceConnectionManager.instance.wait(for: self)

        // The call back is used for app logic uses only
        callback?(true)
    }

    // Handles the xy1 and xy2 cases
    @discardableResult public func subscribeToButtonPress() -> XYBluetoothResult {
        return XYBluetoothResult.empty
    }

    @discardableResult public func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
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
