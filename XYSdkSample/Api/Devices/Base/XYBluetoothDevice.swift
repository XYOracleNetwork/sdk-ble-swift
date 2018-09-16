//
//  XYBluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import PromiseKit

public protocol XY4BluetoothDeviceDelegate {
    func foundServices()
}

public class XYBluetoothDevice: NSObject {
    fileprivate var rssi: Int = XYDeviceProximity.none.rawValue
    fileprivate var peripheral: CBPeripheral?
    fileprivate var services = [ServiceCharacteristic]()

    fileprivate var delegates = [String: CBPeripheralDelegate]()

    public let
    uuid: UUID,
    id: String

    init(_ uuid: UUID, id: String) {
        self.uuid = uuid
        self.id = id
        super.init()
    }

    public var powerLevel: UInt8 { return UInt8(4) }

    public func subscribe(_ delegate: CBPeripheralDelegate, key: String) {
        guard self.delegates[key] == nil else { return }
        self.delegates[key] = delegate
    }

    public func unsubscribe(for key: String) {
        self.delegates.removeValue(forKey: key)
    }
}

// MARK: Peripheral methods
extension XYBluetoothDevice {

    public func setPeripheral(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }

    public func getPeripheral() -> CBPeripheral? {
        return self.peripheral
    }

    var inRange: Bool {
        let strength = XYDeviceProximity.fromSignalStrength(self.rssi)
        guard
            let peripheral = self.peripheral,
            peripheral.state == .connected,
            strength != .outOfRange && strength != .none
            else { return false }

        return true
    }

}

extension XYBluetoothDevice: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.delegates.forEach { $1.peripheral?(peripheral, didDiscoverServices: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.delegates.forEach { $1.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }
}

public extension XYBluetoothDevice {

    func connectAndProcess(for serviceCharacteristics: Set<SerivceCharacteristicDirective>, complete: @escaping ([XYBluetoothValue]) -> Void) {
        // Build a dictionary of the results
        var values = [XYBluetoothValue]()
        
        // The chain ensures each call is made in sequence
        var promiseChain = Promise()

        // TODO Connect
        
        serviceCharacteristics.forEach { serviceCharacteristic in
            switch serviceCharacteristic.operation {
            case .read:
                let newVal = XYBluetoothValue(serviceCharacteristic.serviceCharacteristic)
                values.append(newVal)
                promiseChain = promiseChain.then { _ in
                    serviceCharacteristic.serviceCharacteristic.get(from: self, value: newVal)
                }
            case .write:
                guard let value = serviceCharacteristic.value else { break }
                promiseChain = promiseChain.then { _ in
                    serviceCharacteristic.serviceCharacteristic.set(to: self, value: value)
                }
            }
        }

        // TODO Disconnect
        
        promiseChain.done { _ in
            complete(values)
        }.catch {
            print($0)
        }
    }

}
