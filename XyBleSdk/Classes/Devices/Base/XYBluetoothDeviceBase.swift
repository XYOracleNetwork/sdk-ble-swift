//
//  XYBluetoothDeviceBase.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth

// A concrete base class to base any BLE device off of
public class XYBluetoothDeviceBase: NSObject, XYBluetoothBase {

    public var firstPulseTime : Date?
    public var lastPulseTime : Date?

    public var
    rssi: Int,
    name: String = "",
    id: String

    public internal(set) var peripheral: CBPeripheral?

    fileprivate var delegates = [String: CBPeripheralDelegate?]()
    fileprivate var notifyDelegates = [String: (serviceCharacteristic: XYServiceCharacteristic, delegate: XYBluetoothDeviceNotifyDelegate?)]()

    internal static let workQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.OperationsQueue")

    init(_ id: String, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.id = id
        self.rssi = rssi
        super.init()
    }
}

// MARK: XYBluetoothDevice protocol base implementations
extension XYBluetoothDeviceBase: XYBluetoothDevice {

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

// MARK: CBPeripheralDelegate, passes these on to delegate subscribers for this peripheral
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
                notify.value.delegate?.update(for: notify.value.serviceCharacteristic, value: XYBluetoothResult(data: characteristic.value))
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
