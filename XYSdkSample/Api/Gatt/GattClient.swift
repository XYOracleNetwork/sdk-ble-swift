//
//  GattClient.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/12/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import Promises

enum GattError: Error {
    case notConnected
    case mismatchedPeripheral
    case serviceNotFound
    case characteristicNotFound
    case dataNotPresent
}

enum GattOperation: String {
    case read
    case write
}

// Used for proper upacking of the data result from reading characteristcs
public enum GattCharacteristicType {
    case string
    case integer
    case byte
}

class GattClient: NSObject {
    // Promises that resolve locating the characteristic and reading and writing data
    fileprivate var characteristicPromise = Promise<Void>.pending()
    
    fileprivate lazy var readPromise = Promise<Data?>.pending()
    fileprivate lazy var writePromise = Promise<Void>.pending()

    fileprivate let serviceCharacteristic: ServiceCharacteristic

    fileprivate var
    device: XYBluetoothDevice?,
    service: CBService?,
    characteristic: CBCharacteristic?

    init(_ serviceCharacteristic: ServiceCharacteristic) {
        self.serviceCharacteristic = serviceCharacteristic
    }
    
    // TODO: Change to a per-session token for the key
    func delegateKey(deviceUuid: UUID) -> String {
        return ["GC", deviceUuid.uuidString, serviceCharacteristic.serviceUuid.uuidString, serviceCharacteristic.characteristicUuid.uuidString].joined(separator: ":")
    }

    func get(from device: XYBluetoothDevice, resultObj: XYBluetoothResult) -> Promise<Void> {
        return self.getCharacteristic(device).then {
            self.read(device)
        }.then { result in
            resultObj.add(for: self.serviceCharacteristic, data: result)
        }
    }

    func set(to device: XYBluetoothDevice, valueObj: XYBluetoothValue, withResponse: Bool = true) -> Promise<Void> {
        return self.getCharacteristic(device).then {
            self.write(device, data: valueObj, withResponse: withResponse)
        }.always {
            self.device?.unsubscribe(for: self.delegateKey(deviceUuid: device.uuid))
        }
    }
    
    func getCharacteristic(_ device: XYBluetoothDevice) -> Promise<Void> {
        guard
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected
            else {
                self.characteristicPromise.reject(GattError.notConnected)
                return self.characteristicPromise
            }
        
        self.device = device
        device.subscribe(self, key: self.delegateKey(deviceUuid: device.uuid))
        peripheral.discoverServices(nil)
        
        return self.characteristicPromise
    }
}

// MARK: Internal getters
private extension GattClient {

    func read(_ device: XYBluetoothDevice) -> Promise<Data?> {
        guard
            let characteristic = self.characteristic,
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected
            else {
                self.readPromise.reject(GattError.notConnected)
                return self.readPromise
            }

        peripheral.readValue(for: characteristic)

        return self.readPromise
    }

}

// MARK: Internal setters
private extension GattClient {

    func write(_ device: XYBluetoothDevice, data: XYBluetoothValue, withResponse: Bool) -> Promise<Void> {
        guard
            let characteristic = self.characteristic,
            let peripheral = device.getPeripheral(),
            peripheral.state == .connected,
            let data = data.data
            else {
                self.writePromise.reject(GattError.notConnected)
                return self.writePromise
            }

        peripheral.writeValue(data, for: characteristic, type: withResponse ? .withResponse : .withoutResponse)

        return self.writePromise
    }

}

extension GattClient: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard
            self.device?.getPeripheral() == peripheral
            else {  return }

        guard
            let service = peripheral.services?.filter({ $0.uuid == self.serviceCharacteristic.serviceUuid }).first
            else {  return }

        peripheral.discoverCharacteristics([self.serviceCharacteristic.characteristicUuid], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            self.device?.getPeripheral() == peripheral
            else {  return }

        guard
            let characteristic = service.characteristics?.filter({ $0.uuid == self.serviceCharacteristic.characteristicUuid }).first
            else {  return }

        self.characteristic = characteristic
        
        self.characteristicPromise.fulfill(())
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            self.device?.getPeripheral() == peripheral
            else {  return }

        guard characteristic.uuid == self.serviceCharacteristic.characteristicUuid
            else {  return }

        guard
            let data = characteristic.value
            else {  return }

        readPromise.fulfill(data)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            self.device?.getPeripheral() == peripheral
            else {  return }

        writePromise.fulfill(())
    }

}
