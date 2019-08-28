//
//  XYCentralAgent.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 11/1/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth
import Promises

// An agent that allows for adding connecting to the Central in an XYBluetoothDevice connection block
// or any other Promises chain
public final class XYCentralAgent: XYCentralDelegate {
    private let
    central = XYCentral.instance,
    delegateKey: String

    private lazy var promise = Promise<Void>.pending()

    public init() {
        self.delegateKey = "XYCentralAgent:\(UUID.init().uuidString)"
    }

    @discardableResult public func powerOn() -> Promise<Void> {
        guard self.central.state != .poweredOn else { return Promise(()) }

        self.central.setDelegate(self, key: self.delegateKey)
        self.central.enable()

        return promise.always(on: XYCentral.centralQueue) {
            self.central.removeDelegate(for: self.delegateKey)
        }
    }

    public func stateChanged(newState: CBManagerState) {
        newState == .poweredOn ?
            promise.fulfill(()) :
            promise.reject(XYBluetoothError.couldNotPowerOnCentral)
    }

    // Unused
    public func located(peripheral: XYPeripheral) {}
    public func discovered(beacon: XYIBeaconDefinition) {}
    public func connected(peripheral: XYPeripheral) {}
    public func timeout() {}
    public func couldNotConnect(peripheral: XYPeripheral) {}
    public func disconnected(periperhal: XYPeripheral) {}
}
