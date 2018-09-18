//
//  XYBluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/10/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import Promises

public typealias GattSuccessCallback = ([XYBluetoothValue]) -> Void
public typealias GattErrorCallback = (Error) -> Void
// public typealias GattTimeout = () -> Void

public enum XY4BluetoothDeviceStatus {
    case disconnected
    case connecting
    case connected
    case communicating
}

public class XYBluetoothDevice: NSObject {
    
    internal var rssi: Int = XYDeviceProximity.none.rawValue
    fileprivate var peripheral: CBPeripheral?
    fileprivate var services = [ServiceCharacteristic]()
    
    fileprivate var delegates = [String: CBPeripheralDelegate]()

    fileprivate var successCallback: GattSuccessCallback?
    fileprivate var errorCallback: GattErrorCallback?
    
    public let
    uuid: UUID,
    id: String

    public fileprivate(set) var state: XY4BluetoothDeviceStatus = .disconnected {
        didSet {
            print("the state is being changed to \(self.state)")
        }
    }
    
    fileprivate static let connectionTimeoutInSeconds = DispatchTimeInterval.seconds(5)

    init(_ uuid: UUID, id: String, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.uuid = uuid
        self.id = id
        self.rssi = rssi
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

    func connect() {
        let central = XYCentral.instance

        central.connect(to: self)
    }

    /*
    func connectAndProcess(for serviceCharacteristics: Set<SerivceCharacteristicDirective>, complete: GattSuccessCallback?) {
        // Build a dictionary of the results
        var values = [XYBluetoothValue]()

        if !setupConnection() {
            complete?([])
            return
        }

        self.state = .communicating

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

        promiseChain.then { _ in
            self.state = .connected
            complete?(values)
        }.always {
            // Drop after 5 seconds, or maintain if another request is made and we are already connected
//            after(XYBluetoothDevice.connectionTimeoutInSeconds).done {
//                if self.state != .communicating && self.state != .connecting {
//                    self.connection?.disconnect().done {
//                        self.state = .disconnected
//                        self.peripheral = nil
//                        self.connection = BLEConnect(device: self)
//                    }
//                }
//            }
        }.catch {
            print($0)
        }
    }

    private func setupConnection() -> Bool {
        guard self.state == .disconnected else { return true }

        // Setup connection
        guard let connection = self.connection else {
            return false
        }

        // Connect
//        promiseChain = connection.connect(to: self)

        self.state = .connecting

        return true
    }
 */
}
