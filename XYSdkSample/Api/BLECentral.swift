//
//  BLECentral.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import PromiseKit

public struct BLEPeripheral {
    public let
    peripheral: CBPeripheral,
    advertisementData: [String: Any]?,
    rssi: NSNumber?
}

public protocol BLECentralDelegate: class {
    func located(peripheral: BLEPeripheral)
    func connected(peripheral: BLEPeripheral)
    func disconnected(periperhal: BLEPeripheral)
    func ableToConnect()
}

public typealias BLELocateCallback = ([BLEPeripheral]) -> Void

public class BLECentral: NSObject {

    // TODO weak refs
    fileprivate var delegates = [String: BLECentralDelegate?]()
    
    fileprivate var
    (poweredPromise, poweredSeal) = Promise<Void>.pending()
    
    public static let instance = BLECentral()

    fileprivate final var cbManager: CBCentralManager?

    fileprivate let scanOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: false, CBCentralManagerOptionShowPowerAlertKey: true]

    fileprivate var ableToConnect: Bool = false
    fileprivate let defaultScanTimeout = 10

    fileprivate var peripherals = [UUID: BLEPeripheral]()

    private static let dispatchQueue = DispatchQueue(label:"com.xyfindables.sdk.BLELocateQueue", attributes: .concurrent)

    private let timerQueue = DispatchQueue(label: "com.xyfindables.sdk.BLELocateTimeoutQueue")
    private var timeoutSource: DispatchSourceTimer?

    private override init() {
        super.init()
    }

    public var isAbleToConnect: Bool {
        return self.ableToConnect
    }
    
    public func enable() -> Promise<Void> {
        // Create central
        self.cbManager = CBCentralManager(
            delegate: self,
            queue: BLECentral.dispatchQueue,
            options: nil) // [CBCentralManagerOptionRestoreIdentifierKey : "com.xyfindables.sdk.BLELocateQueue"]

        (poweredPromise, poweredSeal) = Promise<Void>.pending()

        return poweredPromise
    }
    
    public func disable() {
        
    }

    // Connect to an already discovered peripheral
    public func connect(to device: XYBluetoothDevice, options: [String: Any]? = nil) {
        guard let peripheral = device.getPeripheral() else { return }
        cbManager?.connect(peripheral, options: options)
    }

    // Disconnect from a peripheral
    public func disconnect(from device: XYBluetoothDevice) {
        guard let peripheral = device.getPeripheral() else { return }
        cbManager?.cancelPeripheralConnection(peripheral)
    }

    // Ask for devices with the requested/all services until requested to stop()
    public func scan(for services: [ServiceCharacteristic]? = nil) {
        guard ableToConnect else { return }
        self.cbManager?.scanForPeripherals(withServices: services?.map { $0.serviceUuid }, options: nil)
    }

    // Ask for devices with the requested/all services with a specific timeout/default timeout, and callback with results if desired
    public func start(for services: [ServiceCharacteristic]? = nil, timeout: Int? = nil, complete: BLELocateCallback? = nil) {
        guard ableToConnect else { return }
        self.cbManager?.scanForPeripherals(withServices: services?.map { $0.serviceUuid }, options: scanOptions)
        self.timerQueue.sync {
            self.timeoutSource = DispatchSource.singleTimer(interval: .seconds(timeout ?? defaultScanTimeout), queue: self.timerQueue) { [weak self] in
                self?.stop()
                self?.timeoutSource = nil
                complete?(self?.peripherals.map { $1 } ?? [])
            }
        }
    }

    // Request to locate a specific device with timeout/default timeout and callback with either the device or empty array
    public func start(for peripheral: UUID, timeout: Int? = nil, complete: BLELocateCallback) {
        guard ableToConnect else { return }
    }

    // Poll for devices with the requested/all services, waiting an interval in between, and specifying a max interval
    public func start(for services: [ServiceCharacteristic]? = nil, interval: Int, timeout: Int? = nil, maxIntervals: Int? = nil) {
        guard ableToConnect else { return }
    }

    // Stop scanning. Useful for the polling start() above
    public func stop() {
        self.cbManager?.stopScan()
    }

    // Connect to device
    public func connect(to device: XYBluetoothDevice) {
        guard let peripheral = device.getPeripheral() else { return }
        self.cbManager?.connect(peripheral)
    }

    public func setDelegate(_ delegate: BLECentralDelegate, key: String) {
        self.delegates[key] = delegate
    }

    public func removeDelegate(for key: String) {
        self.delegates.removeValue(forKey: key)
    }
    
    func decodePeripheralState(peripheralState: CBPeripheralState) {
        switch peripheralState {
        case .disconnected:
            print("Peripheral state: disconnected")
        case .connected:
            print("Peripheral state: connected")
        case .connecting:
            print("Peripheral state: connecting")
        case .disconnecting:
            print("Peripheral state: disconnecting")
        }
    }
}

extension BLECentral: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // TODO Disconnect everything
        
        self.ableToConnect = central.state == .poweredOn
        if self.ableToConnect { self.delegates.forEach { $1?.ableToConnect() } }
        poweredSeal.fulfill(Void())
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripherals[peripheral.identifier] == nil else { return }
        let wrappedPeripheral = BLEPeripheral(
            peripheral: peripheral,
            advertisementData: advertisementData,
            rssi: RSSI)

        self.peripherals[peripheral.identifier] = wrappedPeripheral
        self.delegates.forEach { $1?.located(peripheral: wrappedPeripheral) }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegates.forEach { $1?.connected(peripheral: BLEPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // TODO
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripherals.removeValue(forKey: peripheral.identifier)
        self.delegates.forEach { $1?.disconnected(periperhal: BLEPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }
}
