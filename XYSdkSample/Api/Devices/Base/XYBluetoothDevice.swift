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

public extension XYBluetoothDevice {

    func get(_ serivceCharacteristic: XYServiceCharacteristic) -> XYBluetoothResult {
        do {
            return try await(serivceCharacteristic.get(from: self))
        } catch {

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

fileprivate extension XYBluetoothDevice {

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

public class XYBluetoothDeviceBase: NSObject, XYBluetoothDevice, XYBluetoothBase {

    public var
    rssi: Int,
    name: String = "",
    id: String

    public fileprivate(set) var peripheral: CBPeripheral?

    fileprivate var delegates = [String: CBPeripheralDelegate?]()
    fileprivate var notifyDelegates = [String: (serviceCharacteristic: XYServiceCharacteristic, delegate: XYBluetoothDeviceNotifyDelegate?)]()

    internal static let workQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.OperationsQueue")

    init(_ id: String, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.id = id
        self.rssi = rssi
        super.init()
    }

}

extension XYBluetoothDeviceBase {

    public var inRange: Bool {
        let strength = XYDeviceProximity.fromSignalStrength(self.rssi)
        guard
            let peripheral = self.peripheral,
            peripheral.state == .connected,
            strength != .outOfRange && strength != .none
            else { return false }

        return true
    }

    public func subscribe(_ delegate: CBPeripheralDelegate, key: String) {
        guard self.delegates[key] == nil else { return }
        self.delegates[key] = delegate
    }

    public func unsubscribe(for key: String) {
        self.delegates.removeValue(forKey: key)
    }

    public func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate)) {
        self.notifyDelegates[delegate.key] = (serviceCharacteristic, delegate.delegate)
        setNotify(serviceCharacteristic, notify: true)
    }

    public func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) {
        setNotify(serviceCharacteristic, notify: false)
        self.notifyDelegates.removeValue(forKey: key)
    }

    public func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
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
extension XYBluetoothDeviceBase: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverServices: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // TODO barf
        for notify in self.notifyDelegates {
            if notify.value.serviceCharacteristic.characteristicUuid == characteristic.uuid {
                notify.value.delegate?.update(for: notify.value.serviceCharacteristic, value: XYBluetoothResult(characteristic.value))
            }
        }
        self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }
}
