//
//  XYCentral.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct XYPeripheral {
    public let
    peripheral: CBPeripheral,
    advertisementData: [String: Any]?

    var rssi: NSNumber?
}

public extension CBManagerState {

    public var toString: String {
        switch self {
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        case .resetting: return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unknown: return "Unknown"
        case .unsupported: return "Unsupported"
        }
    }
}

public protocol XYCentralDelegate: class {
    func located(peripheral: XYPeripheral)
    func connected(peripheral: XYPeripheral)
    func couldNotConnect(peripheral: XYPeripheral)
    func disconnected(periperhal: XYPeripheral)
    func stateChanged(newState: CBManagerState)
}

public class XYCentral: NSObject {

    // TODO weak refs
    fileprivate var delegates = [String: XYCentralDelegate?]()
    
    public static let instance = XYCentral()

    fileprivate var cbManager: CBCentralManager!
    fileprivate let scanOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: false, CBCentralManagerOptionShowPowerAlertKey: true]

    fileprivate let defaultScanTimeout = 10

    fileprivate var peripherals = [UUID: XYPeripheral]()

    fileprivate static let centralQueue = DispatchQueue(label:"com.xyfindables.sdk.XYLocateQueue")

    fileprivate var state: CBManagerState {
        return self.cbManager.state
    }

    private override init() {
        super.init()
    }

    deinit {
        self.cbManager.delegate = nil
    }

    public func enable() {
        XYCentral.centralQueue.sync {
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.peripherals.removeAll()
        }
    }

    public func reset() {
        XYCentral.centralQueue.sync {
            self.cbManager.delegate = nil
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.peripherals.removeAll()
        }
    }

    // Connect to an already discovered peripheral
    public func connect(to device: XYBluetoothDevice, options: [String: Any]? = nil) {
        guard let peripheral = device.getPeripheral() else { return }
        cbManager.connect(peripheral, options: options)
    }

    // Disconnect from a peripheral
    public func disconnect(from device: XYBluetoothDevice) {
        guard let peripheral = device.getPeripheral() else { return }
        cbManager.cancelPeripheralConnection(peripheral)
    }

    // Ask for devices with the requested/all services until requested to stop()
    public func scan(for services: [ServiceCharacteristic]? = nil, timeout: DispatchTimeInterval = .seconds(10)) {
        guard state == .poweredOn else { return }
        self.cbManager.scanForPeripherals(withServices: services?.map { $0.serviceUuid }, options: nil)
    }

    public func stop() {
        self.cbManager.stopScan()
    }

    // Connect to device
    public func connect(to device: XYBluetoothDevice) {
        guard let peripheral = device.getPeripheral() else { return }
        self.cbManager.connect(peripheral)
    }

    public func setDelegate(_ delegate: XYCentralDelegate, key: String) {
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

extension XYCentral: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.delegates.forEach { $1?.stateChanged(newState: self.state) }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var wrappedPeripheral: XYPeripheral
        if let alreadySeenPeripehral = peripherals[peripheral.identifier] {
            wrappedPeripheral = alreadySeenPeripehral
            guard alreadySeenPeripehral.peripheral == peripheral else { return }
            wrappedPeripheral.rssi = RSSI
        } else {
            wrappedPeripheral = XYPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
            self.peripherals[peripheral.identifier] = wrappedPeripheral
        }

        self.delegates.forEach { $1?.located(peripheral: wrappedPeripheral) }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegates.forEach { $1?.connected(peripheral: XYPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {

    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // TODO
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripherals.removeValue(forKey: peripheral.identifier)
        self.delegates.forEach { $1?.disconnected(periperhal: XYPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }
}
