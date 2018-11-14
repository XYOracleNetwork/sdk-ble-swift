//
//  XYCentral.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import Promises

// A wrapper around CBPeripheral, used also to mark any devices for restore or delete if the app is killed in the background
public struct XYPeripheral: Hashable, Equatable {
    public let
    peripheral: CBPeripheral,
    advertisementData: [String: Any]?,
    rssi: NSNumber?

    let markedForDisconnect: Bool

    public init(_ peripheral: CBPeripheral, advertisementData: [String: Any]? = nil, rssi: NSNumber? = nil, markedForDisconnect: Bool = false) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
        self.markedForDisconnect = markedForDisconnect
    }

    public static func == (lhs: XYPeripheral, rhs: XYPeripheral) -> Bool {
        return lhs.peripheral == rhs.peripheral
    }

    public var hashValue: Int {
        return self.peripheral.hashValue
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

// Singleton wrapper around CBCentral.
public class XYCentral: NSObject {

    fileprivate var delegates = [String: XYCentralDelegate?]()
    
    public static let instance = XYCentral()

    fileprivate var cbManager: CBCentralManager?

    fileprivate var restoredPeripherals = Set<XYPeripheral>()

    // All BLE operations should be done on this queue
    internal static let centralQueue = DispatchQueue(label:"com.xyfindables.sdk.XYCentralWorkQueue")

    private override init() {
        super.init()
    }

    public var state: CBManagerState {
        return self.cbManager?.state ?? .unknown
    }

    public func enable() {
        guard cbManager == nil || self.state != .poweredOn else { return }

        XYCentral.centralQueue.sync {
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.restoredPeripherals.removeAll()
        }
    }

    public func reset() {
        XYCentral.centralQueue.sync {
            self.cbManager?.delegate = nil
            self.cbManager = CBCentralManager(
                delegate: self,
                queue: XYCentral.centralQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.xyfindables.sdk.XYLocate"])
            self.restoredPeripherals.removeAll()
        }
    }

    // Connect to an already discovered peripheral
    public func connect(to device: XYBluetoothDevice, options: [String: Any]? = nil) {
        guard let peripheral = device.peripheral else { return }
        cbManager?.connect(peripheral, options: options)
    }

    // Disconnect from a peripheral
    public func disconnect(from device: XYBluetoothDevice) {
        guard let peripheral = device.peripheral else { return }
        cbManager?.cancelPeripheralConnection(peripheral)
    }

    // Ask for devices with the requested/all services until requested to stop()
    public func scan(for services: [XYServiceCharacteristic]? = nil) {
        guard state == .poweredOn else { return }
        self.cbManager?.scanForPeripherals(withServices: services?.map { $0.serviceUuid }, options: nil)
    }

    // Cancel a scan request from scan() above
    public func stopScan() {
        self.cbManager?.stopScan()
    }

    public func setDelegate(_ delegate: XYCentralDelegate, key: String) {
        self.delegates[key] = delegate
    }

    public func removeDelegate(for key: String) {
        self.delegates.removeValue(forKey: key)
    }
}

extension XYCentral: CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.delegates.forEach {
            $1?.stateChanged(newState: central.state)
        }

        guard central.state == .poweredOn else { return }

        self.restoredPeripherals.filter { $0.markedForDisconnect }.forEach {
            self.cbManager?.cancelPeripheralConnection($0.peripheral)
        }
    }

    // Central delegate method called when scanForPeripherals() locates a device. The peripheral will be cached if it is not already and
    // the associated located() delegate method is called
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let wrappedPeripheral = XYPeripheral(peripheral, advertisementData: advertisementData, rssi: RSSI)
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

        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }

        peripherals.forEach { peripheral in
            self.restoredPeripherals.insert(XYPeripheral(peripheral, markedForDisconnect: true))
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let device = XYFinderDeviceFactory.build(from: peripheral) {
            if let marked = device.markedForDeletion, marked == true { return }
            device.resetRssi()
            XYDeviceConnectionManager.instance.remove(for: device.id, disconnect: false)
            self.delegates.forEach { $1?.disconnected(periperhal: XYPeripheral(peripheral)) }
            XYFinderDeviceEventManager.report(events: [.disconnected(device: device)])
        }
    }
}
