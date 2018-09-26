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

public enum GattRequestStatus: String {
    case disconnected
    case discoveringServices
    case discoveringCharacteristics
    case operating
    case timedOut
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

    // Used for handling timeouts
    fileprivate static let callTimeout: DispatchTimeInterval = .seconds(30)
    fileprivate static let queue = DispatchQueue(label:"com.xyfindables.sdk.XYGattRequestTimeoutQueue")
    fileprivate var timer: DispatchSourceTimer?

    init(_ serviceCharacteristic: XYServiceCharacteristic) {
        self.serviceCharacteristic = serviceCharacteristic
    }

    func delegateKey(deviceUuid: UUID) -> String {
        return ["GC", deviceUuid.uuidString, serviceCharacteristic.characteristicUuid.uuidString].joined(separator: ":")
    }

    func get(from device: XYBluetoothDevice) -> Promise<Data?> {
        guard let peripheral = device.peripheral else { return Promise(XYBluetoothError.notConnected) }
        var operationPromise = Promise<Data?>.pending()

        // Ensure single execution of operation
        GattRequest.queue.sync {
            // Create timeout using the operation queue. Self-cleaning if we timeout
            timer = DispatchSource.singleTimer(interval: GattRequest.callTimeout, queue: GattRequest.queue) { [weak self] in
                guard let s = self else { return }
                s.timer = nil
                s.status = .timedOut
                operationPromise.reject(XYBluetoothError.timedOut)
            }

            // Assign the pending operation promise to the results from getting services/characteristics and
            // reading the result from the characteristic. Always unsubscribe from the delegate to ensure the
            // request object is properly cleaned up by ARC
            operationPromise = self.getCharacteristic(device).then(on: XYCentral.centralQueue) { _ in
                self.read(device)
            }.always {
                device.unsubscribe(for: self.delegateKey(deviceUuid: peripheral.identifier))
            }
        }

        return operationPromise
    }

    func set(to device: XYBluetoothDevice, valueObj: XYBluetoothResult, withResponse: Bool = true) -> Promise<Void> {
        guard let peripheral = device.peripheral else { return Promise(XYBluetoothError.notConnected) }

        var operationPromise = Promise<Void>.pending()

        // Ensure single execution of operation
        GattRequest.queue.sync {
            // Create timeout using the operation queue. Self-cleaning if we timeout
            timer = DispatchSource.singleTimer(interval: GattRequest.callTimeout, queue: GattRequest.queue) { [weak self] in
                guard let s = self else { return }
                s.timer = nil
                s.status = .timedOut
                operationPromise.reject(XYBluetoothError.timedOut)
            }

            // Assign the pending operation promise to the results from getting services/characteristics and
            // reading the result from the characteristic. Always unsubscribe from the delegate to ensure the
            // request object is properly cleaned up by ARC
            operationPromise = self.getCharacteristic(device).then(on: XYCentral.centralQueue) { _ in
                self.write(device, data: valueObj, withResponse: withResponse)
            }.always {
                device.unsubscribe(for: self.delegateKey(deviceUuid: peripheral.identifier))
            }
        }

        return operationPromise
    }
}

// MARK: Get service and characteristic
internal extension GattRequest {

    func getCharacteristic(_ device: XYBluetoothDevice) -> Promise<CBCharacteristic> {
        guard
            self.status != .timedOut,
            let peripheral = device.peripheral,
            peripheral.state == .connected
            else {
                return Promise(XYBluetoothError.notConnected)
            }
        
        self.device = device
        device.subscribe(self, key: self.delegateKey(deviceUuid: peripheral.identifier))
        self.status = .discoveringServices
        peripheral.discoverServices(nil)
        
        return self.characteristicPromise
    }
}

// MARK: Internal getters
private extension GattRequest {

    func read(_ device: XYBluetoothDevice) -> Promise<Data?> {
        guard
            self.status != .timedOut,
            let characteristic = self.characteristic,
            let peripheral = device.peripheral,
            peripheral.state == .connected
            else {
                self.readPromise.reject(XYBluetoothError.notConnected)
                return self.readPromise
            }

        print("Gatt(get): read")

        self.status = .operating
        peripheral.readValue(for: characteristic)

        return self.readPromise
    }

}

// MARK: Internal setters
private extension GattRequest {

    func write(_ device: XYBluetoothDevice, data: XYBluetoothResult, withResponse: Bool) -> Promise<Void> {
        guard
            let characteristic = self.characteristic,
            let peripheral = device.peripheral,
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
        guard self.status != .disconnected || self.status != .timedOut else {
            return
        }

        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.peripheral == peripheral
            else { return }

        guard
            let service = peripheral.services?.filter({ $0.uuid == self.serviceCharacteristic.serviceUuid }).first
            else { return }

        self.status = .discoveringCharacteristics
        peripheral.discoverCharacteristics([self.serviceCharacteristic.characteristicUuid], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.status != .disconnected || self.status != .timedOut else {
            return
        }

        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.peripheral == peripheral
            else { return }

        guard
            let characteristic = service.characteristics?.filter({ $0.uuid == self.serviceCharacteristic.characteristicUuid }).first
            else { return }

        self.characteristic = characteristic
        
        self.characteristicPromise.fulfill(characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard self.status != .disconnected || self.status != .timedOut else {
            return
        }

        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.peripheral == peripheral
            else { return }

        guard characteristic.uuid == self.serviceCharacteristic.characteristicUuid
            else { return }

        guard
            let data = characteristic.value
            else {  return }

        print("Gatt(get): read delegate called, done")

        self.status = .completed
        readPromise.fulfill(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard self.status != .disconnected || self.status != .timedOut else { return }

        guard
            error == nil else {
                self.error = XYBluetoothError.cbPeripheralDelegateError(error!)
                return
            }

        guard
            self.device?.peripheral == peripheral
            else {  return }

        guard characteristic.uuid == self.serviceCharacteristic.characteristicUuid
            else {  return }

        print("Gatt(set): write delegate called, done")

        writePromise.fulfill(())
    }

}
