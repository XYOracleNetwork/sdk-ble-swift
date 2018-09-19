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

    fileprivate var cbManager: CBCentralManager?
    fileprivate let scanOptions = [CBCentralManagerScanOptionAllowDuplicatesKey: false, CBCentralManagerOptionShowPowerAlertKey: true]

    fileprivate let defaultScanTimeout = 10

    fileprivate var knownPeripherals = [UUID: XYPeripheral]()

    fileprivate static let centralQueue = DispatchQueue(label:"com.xyfindables.sdk.XYLocateQueue")

    private override init() {
        super.init()
    }

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
    public func scan(for services: [ServiceCharacteristic]? = nil, timeout: DispatchTimeInterval = .seconds(10)) {
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
        self.delegates.forEach { $1?.stateChanged(newState: central.state) }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var wrappedPeripheral: XYPeripheral
        if let alreadySeenPeripehral = knownPeripherals[peripheral.identifier] {
            wrappedPeripheral = alreadySeenPeripehral
            guard alreadySeenPeripehral.peripheral == peripheral else { return }
            wrappedPeripheral.rssi = RSSI
        } else {
            wrappedPeripheral = XYPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
            self.knownPeripherals[peripheral.identifier] = wrappedPeripheral
        }

        self.delegates.forEach { $1?.located(peripheral: wrappedPeripheral) }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegates.forEach { $1?.connected(peripheral: XYPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {

    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let scanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            for service in scanServices {
                print(service)
            }
            //            if central.isScanning {
            //                if central.state == .poweredOn {
            //                    central.stopScan()
            //                }
            //            }
        }

        if let scanOptions = dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String : Any] {
            print("scanOptions : \(scanOptions)")
        }

        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            knownPeripherals.removeAll()
            for peripheral in peripherals {
                knownPeripherals[peripheral.identifier] = XYPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)
                print(peripheral.identifier.uuidString + " : " + String(describing: peripheral.state))
//                XYBase.logExtreme(module:#file, function: #function, message: String(format:"%@", (peripheral)))
                //peripheral.delegate = self
                if peripheral.state == .connected {
                    if self.cbManager?.state == .poweredOn {

                        //                        peripheral.discoverServices(nil);
                        //self.centralManager?.cancelPeripheralConnection(peripheral)
                        //self.centralManager?.connect(peripheral, options: [:])
                    }

                }
                if peripheral.state == .connecting && central.state == .poweredOn {
                    //                    peripheral.delegate = self
                    //                    central.cancelPeripheralConnection(peripheral)
                }
                //                if peripheral.state == .connected && central.state == .poweredOn {
                //                    peripheral.delegate = self
                //                    //central.cancelPeripheralConnection(peripheral)
                //                }
            }
        }
        //        for (_, value) in delegates {
        //            value.centralManager!(central, willRestoreState: dict)
        //        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.knownPeripherals.removeValue(forKey: peripheral.identifier)
        self.delegates.forEach { $1?.disconnected(periperhal: XYPeripheral(peripheral: peripheral, advertisementData: nil, rssi: nil)) }
    }
}
