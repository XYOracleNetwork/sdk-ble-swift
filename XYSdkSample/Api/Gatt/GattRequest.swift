//
//  GattRequest.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/12/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import Promises

public enum GattRequestStatus {
    case disconnected
    case connecting
    case communicating
    case completed
}

class GattRequest: NSObject {
    // Promises that resolve locating the characteristic and reading and writing data
    fileprivate lazy var characteristicPromise = Promise<CBCharacteristic>.pending()
    fileprivate lazy var readPromise = Promise<Data?>.pending()
    fileprivate lazy var writePromise = Promise<Void>.pending()

    fileprivate let serviceCharacteristic: XYServiceCharacteristic

    fileprivate var
    device: XYBluetoothDevice?,
    service: CBService?,
    characteristic: CBCharacteristic?

    public fileprivate(set) var error: XYBluetoothError?

    public fileprivate(set) var status: GattRequestStatus = .disconnected

    // Used for locking access to each request
    private static let lock = DispatchSemaphore(value: 1)
    private static let waitTimeout: TimeInterval = 30
    private static let callTimeout: TimeInterval = 30

    init(_ serviceCharacteristic: XYServiceCharacteristic) {
        self.serviceCharacteristic = serviceCharacteristic
    }

    func delegateKey(deviceUuid: UUID) -> String {
        return ["GC", deviceUuid.uuidString, serviceCharacteristic.characteristicUuid.uuidString].joined(separator: ":")
    }

    func get(from device: XYBluetoothDevice) -> Promise<Data?> {
        // TODO Timeouts here
        guard let peripheral = device.getPeripheral() else { return Promise(XYBluetoothError.notConnected) }
        self.getLock()
        return self.getCharacteristic(device).then(on: XYCentral.centralQueue) { _ in
            self.read(device)
        }.always {
            device.unsubscribe(for: self.delegateKey(deviceUuid: peripheral.identifier))
            self.freeLock()
        }
    }

    func set(to device: XYBluetoothDevice, valueObj: XYBluetoothResult, withResponse: Bool = true) -> Promise<Void> {
        // TODO Timeouts here
        guard let peripheral = device.getPeripheral() else { return Promise(XYBluetoothError.notConnected) }
        self.getLock()
        return self.getCharacteristic(device).then(on: XYCentral.centralQueue) { _ in
            self.write(device, data: valueObj, withResponse: withResponse)
        }.always {
            device.unsubscribe(for: self.delegateKey(deviceUuid: peripheral.identifier))
            self.freeLock()
        }
    }
    
    func getCharacteristic(_ device: XYBluetoothDevice) -> Promise<CBCharacteristic> {
        guard
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected
            else {
                return Promise(XYBluetoothError.notConnected)
            }
        
        self.device = device
        device.subscribe(self, key: self.delegateKey(deviceUuid: peripheral.identifier))
        peripheral.discoverServices(nil)
        
        return self.characteristicPromise
    }
}

// MARK: Locking methods
private extension GattRequest {

    func getLock() {
        if GattRequest.lock.wait(timeout: .now() + GattRequest.waitTimeout) == .timedOut {
            freeLock()
        }
    }

    func freeLock() {
        GattRequest.lock.signal()
    }

}

// MARK: Internal getters
private extension GattRequest {

    func read(_ device: XYBluetoothDevice) -> Promise<Data?> {
        guard
            let characteristic = self.characteristic,
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected
            else {
                self.readPromise.reject(XYBluetoothError.notConnected)
                return self.readPromise
            }

        print("Gatt(get): read")

        peripheral.readValue(for: characteristic)

        return self.readPromise
    }

}

// MARK: Internal setters
private extension GattRequest {

    func write(_ device: XYBluetoothDevice, data: XYBluetoothResult, withResponse: Bool) -> Promise<Void> {
        guard
            let characteristic = self.characteristic,
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected,
            let data = data.data
            else {
                print("Gatt(set): write ERROR")
                return Promise(XYBluetoothError.notConnected)
            }

        print("Gatt(set): write")

        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse)

        return self.writePromise
    }

}

extension GattRequest: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.getPeripheral() == peripheral
            else { return }

        guard
            let service = peripheral.services?.filter({ $0.uuid == self.serviceCharacteristic.serviceUuid }).first
            else { return }

        peripheral.discoverCharacteristics([self.serviceCharacteristic.characteristicUuid], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.getPeripheral() == peripheral
            else { return }

        guard
            let characteristic = service.characteristics?.filter({ $0.uuid == self.serviceCharacteristic.characteristicUuid }).first
            else { return }

        self.characteristic = characteristic
        
        self.characteristicPromise.fulfill(characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.getPeripheral() == peripheral
            else { return }

        guard characteristic.uuid == self.serviceCharacteristic.characteristicUuid
            else { return }

        guard
            let data = characteristic.value
            else {  return }

        print("Gatt(get): read delegate called, done")

        readPromise.fulfill(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.getPeripheral() == peripheral
            else {  return }

        guard characteristic.uuid == self.serviceCharacteristic.characteristicUuid
            else {  return }

        print("Gatt(set): write delegate called, done")

        writePromise.fulfill(())
    }

}
