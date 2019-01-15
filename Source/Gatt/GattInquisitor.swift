//
//  GattInquisitor.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/5/18.
//

import CoreBluetooth
import Promises

// Used to inquire for all the characteristics of all the services the device has
final class GattInquisitor: NSObject {

    fileprivate lazy var inquireServicesPromise = Promise<[CBService]>.pending()
    fileprivate lazy var inquireCharacteristicsPromise = Promise<[CBCharacteristic]>.pending()

    fileprivate let workQueue = DispatchQueue(label: "com.xyfindables.sdk.GattInquisitorQueue")

    fileprivate static let callTimeout: DispatchTimeInterval = .seconds(60)
    fileprivate static let queue = DispatchQueue(label:"com.xyfindables.sdk.XYGattInquisitorTimeoutQueue")
    fileprivate var timer: DispatchSourceTimer?

    fileprivate var device: XYBluetoothDevice?

    fileprivate let specifiedTimeout: DispatchTimeInterval

    fileprivate var disconnectSubKey: UUID? = nil

    public fileprivate(set) var status: GattRequestStatus = .disconnected

    public init(_ timeout: DispatchTimeInterval? = nil) {
        self.specifiedTimeout = timeout ??  GattInquisitor.callTimeout
        super.init()
    }

    func delegateKey(deviceUuid: UUID) -> String {
        return ["GI", deviceUuid.uuidString].joined(separator: ":")
    }

    @discardableResult public func inquire(for device: XYBluetoothDevice) -> Promise<GattDeviceDescriptor> {
        let operationPromise = Promise<GattDeviceDescriptor>.pending()
        guard
            let peripheral = device.peripheral,
            peripheral.state == .connected else {
                operationPromise.reject(XYBluetoothError.notConnected)
                return operationPromise
            }

        // If we disconnect at any point in the request, we stop the timeout and reject the promise
        self.disconnectSubKey = XYFinderDeviceEventManager.subscribe(to: [.disconnected]) { [weak self] event in
            XYFinderDeviceEventManager.unsubscribe(to: [.disconnected], referenceKey: self?.disconnectSubKey)
            guard let device = self?.device as? XYFinderDevice, device == event.device else { return }
            self?.timer = nil
            self?.status = .disconnected
            self?.inquireCharacteristicsPromise.reject(XYBluetoothError.peripheralDisconected(state: device.peripheral?.state))
        }

        print("START Inquire: \(device.id.shortId)")

        // Create timeout using the operation queue. Self-cleaning if we timeout
        timer = DispatchSource.singleTimer(interval: self.specifiedTimeout, queue: GattInquisitor.queue) { [weak self] in
            guard let s = self else { return }
            print("TIMEOUT Inquire: \(device.id.shortId)")
            s.timer = nil
            s.status = .timedOut
            s.inquireCharacteristicsPromise.reject(XYBluetoothError.timedOut)
        }

        var characteristics = [CBCharacteristic]()

        self.device = device
        device.subscribe(self, key: self.delegateKey(deviceUuid: peripheral.identifier))

        // Using an await-style promise, ask for each set of characteristics from the services
        // If we are not on the final service, we re-up the inquire promise
        self.inquireServices(device).then(on: self.workQueue) { services in
            for service in services {
                characteristics += try await(self.inquireCharacteristics(device, service: service))
                if services.last != service {
                    self.inquireCharacteristicsPromise = Promise<[CBCharacteristic]>.pending()
                }
            }
        }.then(on: self.workQueue) { _ in
            operationPromise.fulfill(GattDeviceDescriptor(characteristics))
        }.always(on: self.workQueue) {
            device.unsubscribe(for: self.delegateKey(deviceUuid: peripheral.identifier))
            self.timer = nil
            XYFinderDeviceEventManager.unsubscribe(to: [.disconnected], referenceKey: self.disconnectSubKey)
            print("ALWAYS Inquire: \(device.id.shortId)")
        }.catch(on: self.workQueue) { error in
            operationPromise.reject(error)
        }

        return operationPromise
    }

}

fileprivate extension GattInquisitor {

    @discardableResult func inquireServices(_ device: XYBluetoothDevice) -> Promise<[CBService]> {
        guard
            self.status != .timedOut,
            let peripheral = device.peripheral,
            peripheral.state == .connected
            else {
                self.inquireServicesPromise.reject(XYBluetoothError.notConnected)
                return self.inquireServicesPromise
        }

        self.status = .discoveringServices
        peripheral.discoverServices(nil)

        return self.inquireServicesPromise
    }

    func inquireCharacteristics(_ device: XYBluetoothDevice, service: CBService) -> Promise<[CBCharacteristic]> {
        guard
            self.status != .timedOut,
            let peripheral = device.peripheral,
            peripheral.state == .connected
            else {
                self.inquireCharacteristicsPromise.reject(XYBluetoothError.notConnected)
                return self.inquireCharacteristicsPromise
            }

        self.status = .discoveringCharacteristics
        peripheral.discoverCharacteristics(nil, for: service)

        return self.inquireCharacteristicsPromise
    }

}

extension GattInquisitor: CBPeripheralDelegate {

    private func serviceCharacteristicDelegateValidation(_ peripheral: CBPeripheral, error: Error?) -> Bool {
        guard self.status != .disconnected || self.status != .timedOut else { return false }

        guard error == nil else {
            self.inquireCharacteristicsPromise.reject(XYBluetoothError.cbPeripheralDelegateError(error!))
            return false
        }

        guard
            self.device?.peripheral == peripheral
            else {
                self.inquireCharacteristicsPromise.reject(XYBluetoothError.mismatchedPeripheral)
                return false
        }

        return true
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        workQueue.async {
            guard self.serviceCharacteristicDelegateValidation(peripheral, error: error) else { return }

            guard let services = peripheral.services else {
                self.inquireServicesPromise.reject(XYBluetoothError.serviceNotFound)
                return
            }

            self.inquireServicesPromise.fulfill(services)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            let characteristics = service.characteristics
            else {
                self.inquireCharacteristicsPromise.reject(XYBluetoothError.characteristicNotFound)
                return
        }

        self.inquireCharacteristicsPromise.fulfill(characteristics)
    }

}
