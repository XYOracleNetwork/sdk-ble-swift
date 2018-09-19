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
    
    fileprivate var delegates = [String: CBPeripheralDelegate?]()

    fileprivate var successCallback: GattSuccessCallback?
    fileprivate var errorCallback: GattErrorCallback?
    
    public let
    uuid: UUID,
    id: String

    public fileprivate(set) var state: XY4BluetoothDeviceStatus = .disconnected

    fileprivate let workQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.WorkQueue")

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

// MARK: Locate from Central helpers
public extension XYBluetoothDevice {
    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return false }

        // TODO barf
        guard
            let connectableServices = (self as? XYFinderDevice)?.connectableServices,
            services.contains(connectableServices[0]) || services.contains(connectableServices[1])
            else { return false }

        self.peripheral = peripheral.peripheral
        self.peripheral?.delegate = self
        return true
    }
}

// MARK: CBPeripheralDelegate
extension XYBluetoothDevice: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverServices: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }
}

public class XYBluetoothResult {
    public fileprivate(set) lazy var values = [XYBluetoothValue]()

    func add(for serviceCharacteristic: ServiceCharacteristic, data: Data?) {
        self.values.append(XYBluetoothValue(serviceCharacteristic, data: data))
    }
}

// MARK: Connect and disconnect
public extension XYBluetoothDevice {

    func disconnect() {
        let central = XYCentral.instance
        central.disconnect(from: self)
    }

    func request(_ complete: GattSuccessCallback?, error: GattErrorCallback? = nil) {
        let central = XYCentral.instance

        guard
            central.state == .poweredOn,
            self.peripheral?.state == .connected
            else { error?(GattError.notConnected); return }

        let results = XYBluetoothResult()
        Promise<Void>(on: workQueue) { () -> Void in
//            try await(PrimaryService.buzzer.set(to: self, value: XYBluetoothValue(PrimaryService.buzzer, data: Data([UInt8(0x0b), 0x03]))))

            try await(BatteryService.level.get(from: self, result: results))
            try await(DeviceInformationService.firmwareRevisionString.get(from: self, result: results))
            try await(DeviceInformationService.modelNumberString.get(from: self, result: results))
            try await(DeviceInformationService.hardwareRevisionString.get(from: self, result: results))
            return try await(DeviceInformationService.manufacturerNameString.get(from: self, result: results))

        }.then {
            self.delegates.removeAll()
            complete?(results.values)
        }
    }

}
