//
//  XYConnectionAgent.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 11/1/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Promises
import CoreBluetooth

// A helper to allow for adding connecting to a peripheral to a connection() operation closure
internal final class XYConnectionAgent: XYCentralDelegate {
    private let
    central = XYCentral.instance,
    delegateKey: String,
    device: XYBluetoothDevice

    private static let callTimeout: DispatchTimeInterval = .seconds(30)
    private static let queue = DispatchQueue(label: "com.xyfindables.sdk.XYConnectionAgentTimeoutQueue")
    private let connectionQueue: DispatchQueue!
    private var timer: DispatchSourceTimer?

    private lazy var promise = Promise<Void>.pending()

    // 1. Called to set the device to connect to
    init(for device: XYBluetoothDevice) {
        self.device = device
        self.delegateKey = "XYConnectionAgent:\(device.id.shortId)"
        self.connectionQueue = DispatchQueue(label: "com.xyfindables.sdk.XYConnectionAgentConnectionQueueFor\(device.id.shortId)")
    }

    // 2. Create a connection, or fulfill the promise if the device already is connected
    @discardableResult func connect(_ timeout: DispatchTimeInterval? = nil) -> Promise<Void> {
        guard self.device.peripheral?.state != .connected && self.device.peripheral?.state != .connecting else {
            return Promise(())
        }

        self.central.setDelegate(self, key: self.delegateKey)

        // Timeout on connection to the peripheral
        let callTimeout = timeout ?? XYConnectionAgent.callTimeout
        self.timer = DispatchSource.singleTimer(interval: callTimeout, queue: XYConnectionAgent.queue) { [weak self] in
            guard let strong = self else { return }
            strong.timer = nil
            strong.promise.reject(XYBluetoothError.timedOut)
        }

        // If we have no peripheral, we'll need to scan for the device
        if device.peripheral == nil {
            self.central.scan(stopOnNoDelegates: true)
        // Otherwise we can just try to connect
        } else {
            self.central.connect(to: device)
        }

        // Ensure we always stop scanning and remove the delegate so this object can get cleaned up
        return promise.delay(0.04).always(on: connectionQueue) {
            self.central.removeDelegate(for: self.delegateKey)
            self.central.stopScan()
        }
    }

    // 4: Delegate from central.connect(), meaning we have connected and are ready to set/get characteristics
    func connected(peripheral: XYPeripheral) {
        connectionQueue.async {
            guard peripheral.peripheral == self.device.peripheral else { return }
            self.promise.fulfill(())
        }
    }

    // 3a. Delegate called from scan(), we found the device and now will connect
    func located(peripheral: XYPeripheral) {
        connectionQueue.async {
            if self.device.attachPeripheral(peripheral) {
                self.central.connect(to: self.device)
            }
        }
    }

    func couldNotConnect(peripheral: XYPeripheral) {
        promise.reject(XYBluetoothError.notConnected)
    }

    // Unused in this single connection case
    func timeout() {}
    func disconnected(periperhal: XYPeripheral) {}
    func stateChanged(newState: CBManagerState) {}
    func discovered(beacon: XYIBeaconDefinition) {}
}
