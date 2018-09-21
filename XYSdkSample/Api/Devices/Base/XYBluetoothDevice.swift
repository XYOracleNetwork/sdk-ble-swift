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

// TODO eh...
public protocol XYBluetoothDeviceNotifyDelegate {
    func update(for serviceCharacteristic: ServiceCharacteristic, value: XYBluetoothValue)
}

public class XYBluetoothDevice: NSObject {

    fileprivate static var counter = 1

    internal var rssi: Int = XYDeviceProximity.none.rawValue
    fileprivate var peripheral: CBPeripheral?
    
    fileprivate var delegates = [String: CBPeripheralDelegate?]()
    fileprivate var notifyDelegates = [String: (serviceCharacteristic: ServiceCharacteristic, delegate: XYBluetoothDeviceNotifyDelegate?)]()

    fileprivate var successCallback: GattSuccessCallback?
    fileprivate var errorCallback: GattErrorCallback?
    
    public let
    uuid: UUID,
    id: String

    public fileprivate(set) var state: XY4BluetoothDeviceStatus = .disconnected

    internal static let workQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.WorkQueue")
    fileprivate static let operationsQueue = DispatchQueue(label: "com.xyfindables.sdk.XYBluetoothDevice.OperationsQueue")

    fileprivate static let lockTimeoutInSeconds = DispatchTimeInterval.seconds(15)
    fileprivate static let operationTimeoutInSeconds = DispatchTimeInterval.seconds(15)

    // Locks
    fileprivate let bleLock = DispatchSemaphore(value: 1)

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
    // TODO fix this, it's iBeacon releated
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

// MARK: Notification subscribe/unsubscribe
public extension XYBluetoothDevice {
    func subscribe(to serviceCharacteristic: ServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate)) {
        self.notifyDelegates[delegate.key] = (serviceCharacteristic, delegate.delegate)
        setNotify(serviceCharacteristic, notify: true)
    }

    func unsubscribe(from serviceCharacteristic: ServiceCharacteristic, key: String) {
        setNotify(serviceCharacteristic, notify: false)
        self.notifyDelegates.removeValue(forKey: key)
    }

    private func setNotify(_ serviceCharacteristic: ServiceCharacteristic, notify: Bool) {
        guard
            let peripheral = self.peripheral,
            peripheral.state == .connected else { return }

        if
            let services = peripheral.services,
            let service = services.filter({ $0.uuid == serviceCharacteristic.serviceUuid }).first,
            let characteristic = service.characteristics?.filter({ $0.uuid == serviceCharacteristic.characteristicUuid }).first {

            peripheral.setNotifyValue(notify, for: characteristic)
        } else {
            let client = GattClient(serviceCharacteristic)
            client.getCharacteristic(self).then { characteristic in
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
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
        // TODO barf
        for notify in self.notifyDelegates {
            if notify.value.serviceCharacteristic.characteristicUuid == characteristic.uuid {
                notify.value.delegate?.update(for: notify.value.serviceCharacteristic, value: XYBluetoothValue(notify.value.serviceCharacteristic, data: characteristic.value))
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

//    func request(for serviceCharacteristics: [SerivceCharacteristicDirective], complete: GattSuccessCallback?, error: GattErrorCallback?) {
//        guard
//            XYCentral.instance.state == .poweredOn else { return }
//
//        guard self.peripheral?.state == .connected else {
//                error?(GattError.peripheralDisconected(state: self.peripheral?.state))
//                return
//            }
//
//        XYBluetoothDevice.operationsQueue.async {
//
//            let counter = XYBluetoothDevice.counter
//            XYBluetoothDevice.counter = XYBluetoothDevice.counter + 1
//
//            print("\(counter) bleLock: Trying to get lock")
//            if self.bleLock.wait(timeout: .now() + XYBluetoothDevice.lockTimeoutInSeconds) == .timedOut {
//                print("\(counter) bleLock: Timed out getting the lock")
//                self.bleLock.signal()
//                error?(GattError.timedOut)
//                return
//            }
//            print("\(counter) bleLock: Got a lock")
//
//            let results = XYBluetoothResult()
//
//            func perform(_ directive: SerivceCharacteristicDirective) -> Promise<Data?> {
//                switch directive.operation {
//                case .read:
//                    return directive.serviceCharacteristic.get(from: self, result: results)
//                case .write:
//                    return directive.serviceCharacteristic.set(to: self, value: directive.value!)
//                }
//            }
//
//            // Empty starting promise
//            var chain = Promise<Void>(())
//
//            // Process each directive on the bg work queue
//            // TODO reduce?
//            serviceCharacteristics.forEach { op in
//                chain = chain.then(on: XYBluetoothDevice.workQueue) { perform(op) }
//            }
//
//            // .then defaults to the main thread
//            chain.timeout(on: XYBluetoothDevice.workQueue, 30).then {
//                self.delegates.removeAll()
//                complete?(results.values)
//                print("\(counter) bleLock: Work done, unlocking")
//                self.bleLock.signal()
//                print("\(counter) bleLock: Unlocked")
//            }.catch { error in
//                print(error)
//                self.bleLock.signal()
//            }
//        }
//    }

    // If we wanted to use the await functionality, would look like this...
    func request(_ operations: @escaping () throws -> XYBluetoothValue?) -> Promise<XYBluetoothValue?> {
        let central = XYCentral.instance

        guard
            central.state == .poweredOn,
            self.peripheral?.state == .connected
            else { return Promise<XYBluetoothValue?>(nil) }

        return Promise<XYBluetoothValue?>(on: XYBluetoothDevice.workQueue, operations)

//        let results = XYBluetoothResult()
//        Promise<Void>(on: XYBluetoothDevice.workQueue) {



//        }
    }

}
