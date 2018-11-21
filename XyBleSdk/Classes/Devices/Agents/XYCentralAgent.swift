//
//  XYCentralAgent.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 11/1/18.
//

import Promises
import CoreBluetooth

// An agent that allows for adding connecting to the Central in an XYBluetoothDevice connection block
// or any other Promises chain
internal final class XYCentralAgent: XYCentralDelegate {
    private let
    central = XYCentral.instance,
    delegateKey: String

    private lazy var promise = Promise<Void>.pending()

    init() {
        self.delegateKey = "XYCentralAgent:\(UUID.init().uuidString)"
    }

    @discardableResult func powerOn() -> Promise<Void> {
        guard self.central.state != .poweredOn else { return Promise(()) }

        self.central.setDelegate(self, key: self.delegateKey)
        self.central.enable()

        return promise.always(on: XYCentral.centralQueue) {
            self.central.removeDelegate(for: self.delegateKey)
        }
    }

    func stateChanged(newState: CBManagerState) {
        newState == .poweredOn ?
            promise.fulfill(()) :
            promise.reject(XYBluetoothError.couldNotPowerOnCentral)
    }

    // Unused
    func located(peripheral: XYPeripheral) {}
    func connected(peripheral: XYPeripheral) {}
    func timeout() {}
    func couldNotConnect(peripheral: XYPeripheral) {}
    func disconnected(periperhal: XYPeripheral) {}
}
