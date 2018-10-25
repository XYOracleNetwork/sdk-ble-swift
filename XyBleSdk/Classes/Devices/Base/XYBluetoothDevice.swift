//
//  XYBluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// Use for notifying when a property that the client has subscribed to has changed
public protocol XYBluetoothDeviceNotifyDelegate {
    func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult)
}

// A generic BLE device
public protocol XYBluetoothDevice: XYBluetoothBase {
    var peripheral: CBPeripheral? { get }
    var inRange: Bool { get }
    var connected: Bool { get }

    func stayConnected(_ value: Bool)

    func connect()
    func disconnect()

    func lock()
    func unlock()

    @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void>

    func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval?) -> XYBluetoothResult
    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval?) -> XYBluetoothResult

    func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate))
    func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String)

    func subscribe(_ delegate: CBPeripheralDelegate, key: String)
    func unsubscribe(for key: String)

    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool
}

// MARK: Methods to get, set, or notify on a characteristic using the Promises-based connection work block method below
public extension XYBluetoothDevice {

    var connected: Bool {
        return (self.peripheral?.state ?? .disconnected) == .connected
    }

    func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
        do {
            return try await(serivceCharacteristic.get(from: self, timeout: timeout))
        } catch {
            return XYBluetoothResult(error: error as? XYBluetoothError)
        }
    }

    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
        do {
            try await(serivceCharacteristic.set(to: self, value: value, timeout: timeout))
            return XYBluetoothResult(data: nil)
        } catch {
            return XYBluetoothResult(error: error as? XYBluetoothError)
        }
    }

    func notify(_ serivceCharacteristic: XYServiceCharacteristic, enabled: Bool, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
        do {
            try await(serivceCharacteristic.notify(for: self, enabled: enabled, timeout: timeout))
            return XYBluetoothResult(data: nil)
        } catch {
            return XYBluetoothResult(error: error as? XYBluetoothError)
        }
    }

}

// A helper to allow for adding connecting to a peripheral to a connection() operation closure
internal final class XYConnectionAgent: XYCentralDelegate {
    private let
    central = XYCentral.instance,
    delegateKey: String,
    device: XYBluetoothDevice

    private static let callTimeout: DispatchTimeInterval = .seconds(30)
    private static let queue = DispatchQueue(label:"com.xyfindables.sdk.XYConnectionAgentTimeoutQueue")
    private var timer: DispatchSourceTimer?

    fileprivate static let connectionLock = GenericLock()

    private lazy var promise = Promise<Void>.pending()

    // 1. Called to set the device to connect to
    init(for device: XYBluetoothDevice) {
        self.device = device
        self.delegateKey = "XYConnectionAgent:\(device.id)"
    }

    // 2. Create a connection, or fulfill the promise if the device already is connected
    @discardableResult func connect(_ timeout: DispatchTimeInterval? = nil) -> Promise<Void> {
        guard self.device.peripheral?.state != .connected && self.device.peripheral?.state != .connecting else {
            return Promise(())
        }

        XYConnectionAgent.connectionLock.lock()

        guard self.device.peripheral?.state != .connected && self.device.peripheral?.state != .connecting else {
            XYConnectionAgent.connectionLock.unlock()
            return Promise(())
        }

        self.central.setDelegate(self, key: self.delegateKey)

        // Timeout on connection to the peripheral
        let callTimeout = timeout ?? XYConnectionAgent.callTimeout
        self.timer = DispatchSource.singleTimer(interval: callTimeout, queue: XYConnectionAgent.queue) { [weak self] in
            guard let strong = self else { return }
            XYConnectionAgent.connectionLock.unlock()
            strong.timer = nil
            strong.promise.reject(XYBluetoothError.timedOut)
        }

        // If we have no peripheral, we'll need to scan for the device
        if device.peripheral == nil {
            self.central.scan()
        // Otherwise we can just try to connect
        } else {
            self.central.connect(to: device)
        }

        return promise
    }

    // 4: Delegate from central.connect(), meaning we have connected and are ready to set/get characteristics
    func connected(peripheral: XYPeripheral) {
        self.central.removeDelegate(for: self.delegateKey)
        XYConnectionAgent.connectionLock.unlock()

        // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
        if let device = self.device as? XYFinderDevice {
            XYFinderDeviceEventManager.report(events: [.connected(device: device)])
            device.subscribeToButtonPress()
            if device.peripheral?.state == .connected {
                device.peripheral?.readRSSI() // TODO Final Check - crash here, peripheral not connected, but why?
            } else {
                print("Not sure!")
            }
        }
        promise.fulfill(())
    }

    // 3a. Delegate called from scan(), we found the device and now will connect
    func located(peripheral: XYPeripheral) {
        if self.device.attachPeripheral(peripheral) {
            self.central.connect(to: device)
            self.central.stopScan()
        }
    }

    func couldNotConnect(peripheral: XYPeripheral) {
        self.central.removeDelegate(for: self.delegateKey)
        promise.reject(XYBluetoothError.notConnected)
        XYConnectionAgent.connectionLock.unlock()
    }

    // Unused in this single connection case
    func timeout() {}
    func disconnected(periperhal: XYPeripheral) {}
    func stateChanged(newState: CBManagerState) {}
}

// MARK: Connecting to a device in order to complete a block of operations defined above, as well as disconnect from the peripheral
public extension XYBluetoothDevice {

    @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void> {
        // Must have BTLE on to attempt a connection
        guard XYCentral.instance.state == .poweredOn else {
            return Promise<Void>(XYBluetoothError.centralNotPoweredOn)
        }

        // Must be in range
        guard self.proximity != .outOfRange || self.proximity != .none else {
            return Promise<Void>(XYBluetoothError.deviceNotInRange)
        }

        // Process the queue, adding the connections agent if needed
        return Promise<Void>(on: XYBluetoothDeviceBase.workQueue, {
            self.lock()
            if self.peripheral?.state != .connected {
                try await(XYConnectionAgent(for: self).connect())
            }
            try operations()
        }).always {
            self.unlock()
        }
    }

    func disconnect() {
        let central = XYCentral.instance
        central.disconnect(from: self)
    }
}
