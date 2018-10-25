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

    fileprivate static let connectedDevices = XYFinderDeviceManager()

    fileprivate var
    firstPulseTime: Date?,
    lastPulseTime: Date?

    public fileprivate(set) var totalPulseCount = 0

    fileprivate var semaphore = DispatchSemaphore(value: 1)

    public var
    rssi: Int,
    powerLevel: UInt8

    public let
    name: String,
    id: String

    public internal(set) var peripheral: CBPeripheral? {
        didSet {
            let id = self.id[self.id.index(self.id.endIndex, offsetBy: -10)...]
            let fam = (self as? XYFinderDevice)?.family.familyName ?? "unknown"
            print("************* SET: \(id) OBJ: \(self.peripheral != nil ? "\(ObjectIdentifier(self).hashValue)" : "not set") FAM: \(fam)")
            let i = 1
        }
    }

    internal var stayConnected: Bool = false

    fileprivate lazy var delegates = [String: CBPeripheralDelegate?]()
    fileprivate lazy var notifyDelegates = [String: (serviceCharacteristic: XYServiceCharacteristic, delegate: XYBluetoothDeviceNotifyDelegate?)]()

    internal static let workQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.OperationsQueue")

    init(_ id: String, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.id = id
        self.rssi = rssi
        self.name = ""
        self.powerLevel = 0
        super.init()
    }

    public func update(_ rssi: Int, powerLevel: UInt8) {
        if rssi != XYDeviceProximity.defaultProximity {
            self.rssi = rssi
        }
        self.powerLevel = powerLevel
        self.totalPulseCount += 1

        if self.firstPulseTime == nil {
            self.firstPulseTime = Date()
        }

        self.lastPulseTime = Date()
    }
}

// MARK: XYBluetoothDevice protocol base implementations
extension XYBluetoothDeviceBase: XYBluetoothDevice {

    public func lock() {
        if self.semaphore.wait(timeout: .now() + GattRequest.waitTimeout) == .timedOut {
            self.unlock()
        }
    }

    public func unlock() {
        self.semaphore.signal()
    }

    public var inRange: Bool {
        if self.peripheral?.state == .connected { return true }

        let strength = XYDeviceProximity.fromSignalStrength(self.rssi)
        guard
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
        self.connection {
            _ = self.notify(serviceCharacteristic, enabled: true)
            self.notifyDelegates[delegate.key] = (serviceCharacteristic, delegate.delegate)
        }
    }

    public func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) {
        self.connection {
            _ = self.notify(serviceCharacteristic, enabled: false)
            self.notifyDelegates.removeValue(forKey: key)
        }
    }

    public func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return false }

        guard
            let connectableServices = (self as? XYFinderDevice)?.connectableServices,
            connectableServices.count == 2,
            services.contains(connectableServices[0]) || services.contains(connectableServices[1])
            else { return false }

        self.peripheral = peripheral.peripheral
        self.peripheral?.delegate = self
        return true
    }

    // Connects to the device if requested, and the device is both not trying to connect or already has connected
    public func stayConnected(_ value: Bool) {
        self.stayConnected = value
        self.stayConnected ? connect() : disconnect()
    }

    public func connect() {
        XYBluetoothDeviceBase.connectedDevices.add(device: self)
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
        self.notifyDelegates
            .filter { $0.value.serviceCharacteristic.characteristicUuid == characteristic.uuid }
            .forEach { $0.value.delegate?.update(for: $0.value.serviceCharacteristic, value: XYBluetoothResult(data: characteristic.value))}

        self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error) }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        self.delegates.forEach { $1?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error) }
    }

    // We "recursively" call this method, updating the latest rssi value, and also calling detected if it is an XYFinder device
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.update(Int(truncating: RSSI), powerLevel: 0x4)
        self.delegates.forEach { $1?.peripheral?(peripheral, didReadRSSI: RSSI, error: error) }
        (self as? XYFinderDevice)?.detected()

        // TOOD Not sure this is the right place for this...
        DispatchQueue.global().asyncAfter(deadline: .now() + TimeInterval(XYConstants.DEVICE_TUNING_SECONDS_INTERVAL_CONNECTED_RSSI_READ)) {
            if (peripheral.state == .connected) {
                peripheral.readRSSI()
            }
        }
    }
}
