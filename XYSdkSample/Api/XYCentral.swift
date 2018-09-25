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

    var markedForDisconnect: Bool = false

    public init(_ peripheral: CBPeripheral, advertisementData: [String: Any]? = nil, rssi: NSNumber? = nil, markedForDisconnect: Bool = false) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.markedForDisconnect = markedForDisconnect
    }
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
    func timeout()
    func couldNotConnect(peripheral: XYPeripheral)
    func disconnected(periperhal: XYPeripheral)
    func stateChanged(newState: CBManagerState)
}

public class XYCentral: NSObject {

    // TODO weak refs
    fileprivate var delegates = [String: XYCentralDelegate?]()
    
    public static let instance = XYCentral()

    fileprivate var cbManager: CBCentralManager?
    fileprivate let scanOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: false, CBCentralManagerOptionShowPowerAlertKey: true]

    fileprivate let defaultScanTimeout = 10

    fileprivate var knownPeripherals = [UUID: XYPeripheral]()

    fileprivate static let centralQueue = DispatchQueue(label:"com.xyfindables.sdk.XYLocateQueue")

    private override init() {
        super.init()
    }

    fileprivate let timeoutQueue = DispatchQueue(label: "com.xyfindables.sdk.XYLocateTimeoutQueue")
    fileprivate var timeoutTimer: DispatchSourceTimer?
    fileprivate var isConnecting: Bool = false

    deinit {
        self.cbManager?.delegate = nil
    }

    public var state: CBManagerState {
        return self.cbManager?.state ?? .unknown
    }

    public func enable() {
        // TODO check if already enabled and ready
        XYCentral.centralQueue.sync {
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.knownPeripherals.removeAll()
        }
    }

    public func reset() {
        XYCentral.centralQueue.sync {
            self.cbManager?.delegate = nil
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.knownPeripherals.removeAll()
        }
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
    public func scan(for services: [XYServiceCharacteristic]? = nil) {
        guard state == .poweredOn else { return }
        self.cbManager?.scanForPeripherals(withServices: services?.map { $0.serviceUuid }, options: nil)
    }

    public func stop() {
        self.cbManager?.stopScan()
    }

    // Connect to device
    public func connect(to device: XYBluetoothDevice) {
        guard let peripheral = device.getPeripheral() else { return }
        self.cbManager?.connect(peripheral)
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
        self.delegates.forEach {
            $1?.stateChanged(newState: central.state)
        }

        guard central.state == .poweredOn else { return }

        // Destroy anything marked for removal from restore below
        self.knownPeripherals.filter { $1.markedForDisconnect }.forEach {
            self.cbManager?.cancelPeripheralConnection($1.peripheral)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var wrappedPeripheral: XYPeripheral
        if let alreadySeenPeripehral = knownPeripherals[peripheral.identifier] {
            wrappedPeripheral = alreadySeenPeripehral
            guard alreadySeenPeripehral.peripheral == peripheral else { return }
            wrappedPeripheral.rssi = RSSI
        } else {
            wrappedPeripheral = XYPeripheral(peripheral, advertisementData: advertisementData, rssi: RSSI)
            self.knownPeripherals[peripheral.identifier] = wrappedPeripheral
        }

        self.delegates.forEach { $1?.located(peripheral: wrappedPeripheral) }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegates.forEach { $1?.connected(peripheral: XYPeripheral(peripheral)) }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.delegates.forEach { $1?.couldNotConnect(peripheral: XYPeripheral(peripheral)) }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        // dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String : Any]

        // Disconnect anything that was here when the app got nuked when centralManagerDidUpdateState is called after this
        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
        knownPeripherals.removeAll()
        for peripheral in peripherals {
            self.knownPeripherals[peripheral.identifier] = XYPeripheral(peripheral, markedForDisconnect: true)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.knownPeripherals.removeValue(forKey: peripheral.identifier)
        self.delegates.forEach { $1?.disconnected(periperhal: XYPeripheral(peripheral)) }
    }
}
