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
    // Add for detected
}

// A generic BLE device
public protocol XYBluetoothDevice: XYBluetoothBase {
    var peripheral: CBPeripheral? { get }
    var inRange: Bool { get }

    func disconnect()
    func connection(_ operations: @escaping () throws -> Void) -> Promise<Void>

    func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval?) -> XYBluetoothResult
    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval?) -> XYBluetoothResult

    func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate))
    func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String)

    func subscribe(_ delegate: CBPeripheralDelegate, key: String)
    func unsubscribe(for key: String)

    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool
}

// MARK: Methods to get or set a characteristic using the Promises-based connection work block method below
public extension XYBluetoothDevice {

    func get(_ serivceCharacteristic: XYServiceCharacteristic, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult {
        do {
            return try await(serivceCharacteristic.get(from: self, timeout: timeout))
        } catch {
            return XYBluetoothResult(error: error as? XYBluetoothError)
        }
    }

    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult, timeout: DispatchTimeInterval? = nil) -> XYBluetoothResult  {
        do {
            try await(serivceCharacteristic.set(to: self, value: value, timeout: timeout))
            return XYBluetoothResult(data: nil)
        } catch {
            return XYBluetoothResult(error: error as? XYBluetoothError)
        }
    }

}

// MARK: Connecting to a device in order to complete a block of operations defined above, as well as disconnect from the peripheral
public extension XYBluetoothDevice {

    func connection(_ operations: @escaping () throws -> Void) -> Promise<Void> {
        guard
            XYCentral.instance.state == .poweredOn,
            self.peripheral?.state == .connected
            else { return Promise(()) }

        return Promise<Void>(on: XYBluetoothDeviceBase.workQueue, operations)
    }

    func disconnect() {
        let central = XYCentral.instance
        central.disconnect(from: self)
    }

}

// MARK: Allows the client to subscribe to a characteristic of a service on the device and receive udpates via the delegate
internal extension XYBluetoothDevice {

    func setNotify(_ serviceCharacteristic: XYServiceCharacteristic, notify: Bool) {
        guard
            let peripheral = self.peripheral,
            peripheral.state == .connected else { return }

        if
            let services = peripheral.services,
            let service = services.filter({ $0.uuid == serviceCharacteristic.serviceUuid }).first,
            let characteristic = service.characteristics?.filter({ $0.uuid == serviceCharacteristic.characteristicUuid }).first {

            peripheral.setNotifyValue(notify, for: characteristic)
        } else {
            let client = GattRequest(serviceCharacteristic)
            client.getCharacteristic(self).then { characteristic in
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

}
