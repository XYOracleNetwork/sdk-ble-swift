//
//  BLEConnect.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/11/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth
import PromiseKit

enum BLEConnectError: Error {
    case noServicesFound
    case requestedDeviceNotFound
    case couldNotConnect
}

// Creates a connection to one device, loading it and all the services
class BLEConnect {
    fileprivate let central = BLECentral.instance
    fileprivate let device: XYBluetoothDevice

    fileprivate weak var delegate: BLELocateDelegate?

    fileprivate let
    (connectPromise, connectSeal) = Promise<Void>.pending()
    
    init(device: XYBluetoothDevice, delegate: BLELocateDelegate? = nil) {
        self.device = device
        self.delegate = delegate

        self.central.setDelegate(self, key: "BLEConnect")
//        if central.isAbleToConnect {
//            connect()
//        }
    }

    private func connect() {
        central.scan()
    }

    public func stop() {
        central.stop()
    }

    public func disconnect() {
        central.disconnect(from: self.device)
    }
}

extension BLEConnect {
    func connect(to device: XYBluetoothDevice) -> Promise<Void> {
        central.scan()
        // TODO need timeout
        return connectPromise
    }
}
extension BLEConnect: BLELocateDelegate {
    func connected(peripheral: BLEPeripheral) {
        guard peripheral.peripheral == self.device.getPeripheral()
            else { self.connectSeal.reject(BLEConnectError.couldNotConnect); return }
        
        print("Connected to \(device.id)")

        DispatchQueue.main.async {
            self.delegate?.connected(peripheral: peripheral)
        }
        
        self.connectSeal.fulfill(Void())
    }

    func located(peripheral: BLEPeripheral) {
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { self.connectSeal.reject(BLEConnectError.noServicesFound); return }

        // TODO barf
        guard
            let connectableServices = (self.device as? XYFinderDevice)?.connectableServices,
            services.contains(connectableServices[0]) || services.contains(connectableServices[1])
            else { self.connectSeal.reject(BLEConnectError.requestedDeviceNotFound); return }

        self.device.setPeripheral(peripheral.peripheral)
        self.delegate?.located(peripheral: peripheral)

        central.stop()
        central.connect(to: self.device)
    }

    func ableToConnect() {
        connect()
    }
}
