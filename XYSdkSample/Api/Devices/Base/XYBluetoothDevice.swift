//
//  XYBluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

public protocol XYBluetoothDeviceNotifyDelegate {
    func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult)
}

// A generic BLE device
public protocol XYBluetoothDevice: XYBluetoothBase {
    var peripheral: CBPeripheral? { get }
    var inRange: Bool { get }

    func disconnect()
    func connection(_ operations: @escaping () throws -> Void) -> Promise<Void>

    func get(_ serivceCharacteristic: XYServiceCharacteristic) -> XYBluetoothResult
    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult)

    func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate))
    func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String)

    func subscribe(_ delegate: CBPeripheralDelegate, key: String)
    func unsubscribe(for key: String)

    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool
}

// MARK: Methods to get or set a characteristic using the Promises-based connection work block method below
public extension XYBluetoothDevice {

    func get(_ serivceCharacteristic: XYServiceCharacteristic) -> XYBluetoothResult {
        do {
            return try await(serivceCharacteristic.get(from: self))
        } catch {
            print("Something pooped!")
        }

        return XYBluetoothResult(nil)
    }

    func set(_ serivceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        do {
            try await(serivceCharacteristic.set(to: self, value: value))
        } catch {

        }
    }

}

public extension XYBluetoothDevice {

    func disconnect() {
        let central = XYCentral.instance
        central.disconnect(from: self)
    }

    func connection(_ operations: @escaping () throws -> Void) -> Promise<Void> {
        guard
            XYCentral.instance.state == .poweredOn,
            self.peripheral?.state == .connected
            else { return Promise(()) }

        return Promise<Void>(on: XYBluetoothDeviceBase.workQueue, operations)
    }

}

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
