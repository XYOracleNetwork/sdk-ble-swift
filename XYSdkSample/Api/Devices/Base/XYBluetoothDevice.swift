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

public typealias GattSuccessCallback = ([XYBluetoothValue]) -> Void
public typealias GattErrorCallback = (Error) -> Void
// public typealias GattTimeout = () -> Void

public class XYBluetoothDevice: NSObject {
    
    fileprivate var rssi: Int = XYDeviceProximity.none.rawValue
    fileprivate var peripheral: CBPeripheral?
    fileprivate var services = [ServiceCharacteristic]()
    fileprivate var connection: BLEConnect?

    // The chain ensures each call is made in sequence
    fileprivate lazy var promiseChain = Promise()
    
    fileprivate var delegates = [String: CBPeripheralDelegate]()

    fileprivate var successCallback: GattSuccessCallback?
    fileprivate var errorCallback: GattErrorCallback?
    
    public let
    uuid: UUID,
    id: String
    
    fileprivate static let connectionTimeoutInSeconds: TimeInterval = 5

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

// TODO may want to rethink this, as this does overload device will all these callbacks
public extension XYBluetoothDevice {
    
    func connectAndProcess(for serviceCharacteristics: Set<SerivceCharacteristicDirective>, complete: GattSuccessCallback?) {
        // Build a dictionary of the results
        var values = [XYBluetoothValue]()
        
        // Setup connection
        connection = BLEConnect(device: self)
        guard let connection = self.connection else {
            complete?([])
            return
        }
        
        // Connect
        promiseChain = connection.connect(to: self)
        
        // Iterate through set of requests and fulfill each one
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

        promiseChain.done { _ in
            complete?(values)
        }.ensure {
            // TODO hook to ensure stays open with new request
            after(.seconds(3)).done {
                self.connection?.disconnect()
            }
        }.catch {
            print($0)
        }
    }

}
