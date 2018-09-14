//
//  BLEConnect.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/11/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

// Creates a connection to one device, loading it and all the services
class BLEConnect {
    fileprivate let central = BLECentral.instance
    fileprivate let device: XYBluetoothDevice

    fileprivate weak var delegate: BLELocateDelegate?

    init(device: XYBluetoothDevice, delegate: BLELocateDelegate) {
        self.device = device
        self.delegate = delegate

        self.central.setDelegate(self, key: "BLEConnect")
        if central.isAbleToConnect {
            connect()
        }
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

extension BLEConnect: BLELocateDelegate {
    func connected(peripheral: BLEPeripheral) {
        guard peripheral.peripheral == self.device.getPeripheral() else { return }
        print("Connected to \(device.id)")

        DispatchQueue.main.async {
            self.delegate?.connected(peripheral: peripheral)
        }
    }

    func located(peripheral: BLEPeripheral) {
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

    func ableToConnect() {
        connect()
    }
}
