//
//  XYFinderDevice.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Promises

// A device from the XY family, has an iBeacon and other XY-specific identifiers
public protocol XYFinderDevice: XYBluetoothDevice {
    var connectableServices: [CBUUID] { get }
    var location: XYLocationCoordinate2D { get }
    var batteryLevel: Int { get }
    var firmware: String { get }
    var isRegistered: Bool { get }

    // Handlers for button press subscriptions
    @discardableResult func subscribeToButtonPress() -> XYBluetoothResult
    @discardableResult func unsubscribeToButtonPress(for referenceKey: UUID?) -> XYBluetoothResult

    // Handle location updates
    func updateLocation(_ newLocation: XYLocationCoordinate2D)

    // Updates to battery level
    func updateBatteryLevel(_ newLevel: Int)

    // Handles when detected from the location manager
    func detected()

    // Updates the state of the device's isRegistered flag
    // I'm unsure as to what this is used for
    func getRegistrationFlag()

    // TODO make this an internal protocol or something...
    func startMonitorTimer()
    func cancelMonitorTimer()

    // Convenience methods for common operations
    @discardableResult
    func find(_ song: XYFinderSong) -> XYBluetoothResult
    
    @discardableResult
    func stayAwake() -> XYBluetoothResult
    
    @discardableResult
    func isAwake() -> XYBluetoothResult
    
    @discardableResult
    func fallAsleep() -> XYBluetoothResult
    
    @discardableResult
    func lock() -> XYBluetoothResult
    
    @discardableResult
    func unlock() -> XYBluetoothResult
    
    @discardableResult
    func version() -> XYBluetoothResult
    
}

// MARK: Default handler to report the button press should the finder subscribe to the notification
extension XYFinderDeviceBase: XYBluetoothDeviceNotifyDelegate {
    public func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        guard
            // Validate the proper services and the value from the notification, then report
            serviceCharacteristic.characteristicUuid == XYFinderPrimaryService.buttonState.characteristicUuid ||
            serviceCharacteristic.characteristicUuid == ControlService.button.characteristicUuid,
            let rawValue = value.asInteger,
            let buttonPressed = XYButtonType2.init(rawValue: rawValue)
            else { return }

        if !self.handlingButtonPress {
            self.handlingButtonPress = true
            XYFinderDeviceEventManager.report(events: [.buttonPressed(device: self, type: buttonPressed)])

            XYSmartScan.queue.asyncAfter(deadline: DispatchTime.now() + TimeInterval(3.0)) {
                self.handlingButtonPress = false
            }
        }
    }
}
