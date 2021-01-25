//
//  XYFinderDeviceBase.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/18/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

// The base XYFinder class
public class XYFinderDeviceBase: XYBluetoothDeviceBase, XYFinderDevice {
    public var
    location: XYLocationCoordinate2D = XYLocationCoordinate2D(),
    isRegistered: Bool = false,
    batteryLevel: Int = -1,
    firmware: String = ""
    
    internal var handlingButtonPress: Bool = false
    var shouldCheckForButtonPressOnDetection = false

    public init(_ family: XYDeviceFamily, id: String, iBeacon: XYIBeaconDefinition?, rssi: Int) {
        super.init(id, rssi: rssi, family: family, iBeacon: iBeacon)
    }

    fileprivate static let buttonTimeout: DispatchTimeInterval = .seconds(30)
    fileprivate static let buttonTimerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceButtonTimerQueue")
    fileprivate var buttonTimer: DispatchSourceTimer?

    fileprivate static let monitorTimeout: DispatchTimeInterval = .seconds(30)
    fileprivate static let monitorTimerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceMonitorTimerQueue")
    fileprivate var monitorTimer: DispatchSourceTimer?
    
    override public func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        guard
            self.peripheral == nil,
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return false }
        
         let connectableServices = self.connectableServices
        
        guard
            connectableServices.count == 2,
            services.contains(connectableServices[0]) || services.contains(connectableServices[1])
            else { return false }
        
        // Set the peripheral and delegate to self
        self.peripheral = peripheral.peripheral
        self.peripheral?.delegate = self
        
        // Save off the services this device was found with for BG monitoring
        self.supportedServices = services
        
        return true
    }
    
    
    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major else {
            return []
        }
        
        guard let minor = iBeacon?.minor else {
            return []
        }

        func getServiceUuid() -> CBUUID {
            let uuidSource = NSUUID(uuidString: "a500248c-abc2-4206-9bd7-034f4fc9ed10")
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

        return [XYConstants.DEVICE_POWER_LOW, XYConstants.DEVICE_POWER_HIGH].map { _ in getServiceUuid() }
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
          monitorTimer = DispatchSource.makeTimerSource(queue: XYFinderDeviceBase.monitorTimerQueue)
          monitorTimer?.schedule(deadline: DispatchTime.now() + XYFinderDeviceBase.monitorTimeout)
          monitorTimer?.setEventHandler(handler: { [weak self] in
            guard let strong = self else { return }
            strong.monitorTimer = nil
            if strong.iBeacon?.hasMajor ?? false && strong.iBeacon?.hasMinor ?? false {
                print("MONITOR TIMER EXPIRE: Device \(strong.id)")
                strong.verifyExit()
            }
          })
          monitorTimer?.resume()
        }
    }

    // If the device enters while monitoring, we always cancel the timer and report it is back
    public func cancelMonitorTimer() {
        self.monitorTimer = nil
        XYFinderDeviceEventManager.report(events: [.entered(device: self)])
    }
    
  public override func detected(_ rssi: Int) {
        guard self.isUpdatingFirmware == false else { return }

        var events: [XYFinderEventNotification] = [.detected(device: self, powerLevel: Int(self.powerLevel), rssi: self.rssi, distance: 0)]

        // If the button has been pressed on a compatible devices, we add the appropriate event
        if powerLevel == 8, shouldCheckForButtonPressOnDetection {
            if buttonTimer == nil {              
              buttonTimer = DispatchSource.makeTimerSource(queue: XYFinderDeviceBase.buttonTimerQueue)
              buttonTimer?.schedule(deadline: DispatchTime.now() + XYFinderDeviceBase.buttonTimeout)
              buttonTimer?.setEventHandler(handler: { [weak self] in
                guard let strong = self else { return }
                strong.buttonTimer = nil
              })
              buttonTimer?.resume()
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

        XYFinderDeviceEventManager.report(events: [.exited(device: self)])

        // We put the device in the wait queue so it auto-reconnects when it comes back
        // into range. This works only while the app is in the background
        if XYSmartScan.instance.mode == .background {
            XYDeviceConnectionManager.instance.wait(for: self)
        }

        // The call back is used for app logic uses only
        callback?(true)
    }

    // Handles the xy1 and xy2 cases
    @discardableResult
    public func subscribeToButtonPress() -> XYBluetoothResult {
        return XYBluetoothResult.empty
    }

    @discardableResult
    public func unsubscribeToButtonPress(for referenceKey: UUID? = nil) -> XYBluetoothResult {
        return XYBluetoothResult.empty
    }

    public func updateLocation(_ newLocation: XYLocationCoordinate2D) {
        self.location = newLocation
    }

    public func updateBatteryLevel(_ newLevel: Int) {
        self.batteryLevel = newLevel
    }

    @discardableResult
    public func find(_ song: XYFinderSong = .findIt) -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func stayAwake() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func isAwake() -> XYBluetoothResult {
         return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func fallAsleep() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func lock() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func unlock() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }

    @discardableResult
    public func version() -> XYBluetoothResult {
        return XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
    }
}
