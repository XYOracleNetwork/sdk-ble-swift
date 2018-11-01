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

    func verifyExit(_ callback:((_ exited: Bool) -> Void)?)

    @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void>

    func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval?) -> XYBluetoothResult
    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval?) -> XYBluetoothResult

    func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate))
    func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) -> XYBluetoothResult

    func subscribe(_ delegate: CBPeripheralDelegate, key: String)
    func unsubscribe(for key: String)

    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool
    var state: CBPeripheralState { get }
}

// MARK: Methods to get, set, or notify on a characteristic using the Promises-based connection work block method below
public extension XYBluetoothDevice {

    var connected: Bool {
        return (self.peripheral?.state ?? .disconnected) == .connected
    }

    var state: CBPeripheralState {
        return self.peripheral?.state ?? .disconnected
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

// MARK: Connecting to a device in order to complete a block of operations defined above, as well as disconnect from the peripheral
public extension XYBluetoothDevice {

    @discardableResult func connection(_ operations: @escaping () throws -> Void) -> Promise<Void> {
//        // Check range before running operations block
//        guard self.proximity != .outOfRange && self.proximity != .none else {
//            return Promise<Void>(XYBluetoothError.deviceNotInRange)
//        }

        // Process the queue, adding the connections agent if needed
        return Promise<Void>(on: XYBluetoothDeviceBase.workQueue, {
            self.lock()

            // If we don't have a powered on central, we'll see if we can't get that running
            if XYCentral.instance.state != .poweredOn {
                try await(XYCentralAgent().powerOn())
            }

            // If we are no connected, use the agent to handle that before running the operations block
            if self.peripheral?.state != .connected {
                try await(XYConnectionAgent(for: self).connect())
            }

            // Run the requested Gatt operations
            try operations()

        }).always(on: XYBluetoothDeviceBase.workQueue) {
            self.unlock()
        }.catch { error in
            print((error as! XYBluetoothError).toString)
        }
    }

}
