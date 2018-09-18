//
//  BLEConnect.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/11/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import Promises

enum BLEConnectError: Error {
    case noServicesFound
    case requestedDeviceNotFound
    case couldNotConnect
}

public enum BLEConnectState {
    case connected
    case disconnected
}

// Creates a connection to one device, loading it and all the services
class BLEConnect {
    fileprivate let central = XYCentral.instance
    fileprivate let device: XYBluetoothDevice

    fileprivate weak var delegate: XYCentralDelegate?

    fileprivate(set) var state: BLEConnectState = .disconnected

//    fileprivate let connectPromise = Promise<Void>.pending()
//    fileprivate lazy var di
//
////    fileprivate let
////    (connectPromise, connectSeal) = Promise<Void>.pending()
////
////    fileprivate let
////    (disconnectPromise, disconnectSeal) = Promise<Void>.pending()

    init(device: XYBluetoothDevice, delegate: XYCentralDelegate? = nil) {
        self.device = device
        self.delegate = delegate

        self.central.setDelegate(self, key: "BLEConnect")
    }

    private func connect() {
        central.scan()
    }

    public func stop() {
        central.stop()
    }

//    public func disconnect() -> Promise<Void> {
//        central.disconnect(from: self.device)
//        return disconnectPromise
//    }

    deinit {
        print("I am one")
    }
}

extension BLEConnect {
//    func connect(to device: XYBluetoothDevice) -> Promise<Void> {
//        // Ensure central can use ble
//        _ = firstly {
//            central.enable()
//        }.done {
//            self.central.scan()
//        }
//
//        return connectPromise
//    }
}

extension BLEConnect: XYCentralDelegate {
    func couldNotConnect(peripheral: XYPeripheral) {
        
    }

    func stateChanged(newState: CBManagerState) {
        
    }

    func connected(peripheral: XYPeripheral) {
//        guard peripheral.peripheral == self.device.getPeripheral()
//            else { self.connectSeal.reject(BLEConnectError.couldNotConnect); return }
//
//        print("Connected to \(device.id)")
//
//        DispatchQueue.main.async {
//            self.delegate?.connected(peripheral: peripheral)
//        }
//
//        self.connectSeal.fulfill(Void())
    }

    func located(peripheral: XYPeripheral) {
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return }

        // TODO barf
        guard
            let connectableServices = (self.device as? XYFinderDevice)?.connectableServices,
            services.contains(connectableServices[0]) || services.contains(connectableServices[1])
            else { return }
        
        self.device.setPeripheral(peripheral.peripheral)
        self.delegate?.located(peripheral: peripheral)

        central.stop()
        central.connect(to: self.device)
    }


    func disconnected(periperhal: XYPeripheral) {
//        disconnectSeal.fulfill(())
    }
}
