//
//  XYFinderDeviceManager.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/25/18.
//

import CoreBluetooth

final class XYDeviceConnectionManager {

    static let instance = XYDeviceConnectionManager()
    private init() {}

    fileprivate var devices = [String: XYBluetoothDevice]()
    fileprivate lazy var waitingDeviceIds = [String]()
    fileprivate let managerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceManagerQueue", attributes: .concurrent)
    fileprivate let waitQueue = DispatchQueue(label: "com.xyfindables.sdk.XYDeviceConnectionManager.WaitQueue")

    fileprivate let
    connectionLock = GenericLock(0),
    reconnectLock = GenericLock(0)

    public var connectedDevices: [XYBluetoothDevice] {
        return self.devices.map { $1 }
    }

    func invalidate() {
        devices.forEach { $0.value.disconnect() }
    }

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    func add(device: XYBluetoothDevice) {
        // Quick escape if we already have the device and it is connected or it's already connecting
        guard !isConnectedOrConnecting(for: self.devices[device.id]) else { return }

        // Check and connect
        guard self.devices[device.id] == nil else { return }
        self.managerQueue.async(flags: .barrier) {
            guard self.devices[device.id] == nil else { return }
            self.devices[device.id] = device
            self.connect(to: device)
        }
    }

    // Remove the devices from the dictionary of tracked, connected devices, and let central know to disconnect
    func remove(for id: String, disconnect: Bool) {
        guard self.devices[id] != nil else { return }
        self.managerQueue.async(flags: .barrier) {
            guard let device = self.devices[id] else { return }
            self.devices.removeValue(forKey: device.id)
            if disconnect && device.state != .disconnected {
                self.disconnect(from: device)
            }
        }
    }

    // If we lose connection to a device, we can put it in the wait queue and it will automatically reconnect
    // even if the user leaves the area (as long as the app is still running in the backgound)
    func wait(for device: XYBluetoothDevice) {
        // Quick escape if we already have the device and it is connected or it's already connecting
        guard !isConnectedOrConnecting(for: device) else { return }

        // We have lost contact with the device, so we'll do a non-expiring connectiong try
        guard !waitingDeviceIds.contains(where: { $0 == device.id }) else { return }
        self.managerQueue.async(flags: .barrier) {
            guard !self.waitingDeviceIds.contains(where: { $0 == device.id }) else { return }
            print("Adding \(device.id) to wait queue...")

            XYConnectionAgent(for: device).connect(.never).then(on: self.waitQueue) {
                self.waitingDeviceIds.removeAll(where: { $0 == device.id })
                print("\(device.id) is found again!")

                if let xyDevice = device as? XYFinderDevice {
                    // Lock and try for a reconnection
                    xyDevice.connection {
                        // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
                        if let xyDevice = device as? XYFinderDevice {
                            if !xyDevice.unlock().hasError && !xyDevice.subscribeToButtonPress().hasError {
                                xyDevice.peripheral?.readRSSI()
                            } else {
                                throw XYBluetoothError.couldNotConnect
                            }
                        }

                    }.then(on: self.waitQueue) {
                        if let xyDevice = device as? XYFinderDevice {
                            XYFinderDeviceEventManager.report(events: [.reconnected(device: xyDevice)])
                        }
                        self.reconnectLock.unlock()

                    }.always(on: self.waitQueue) {
                        self.reconnectLock.unlock()
                    }
                } else {
                    self.reconnectLock.unlock()
                }
            }

            self.reconnectLock.lock()
        }
    }
}

// MARK: Connect and disconnection
private extension XYDeviceConnectionManager {

    func isConnectedOrConnecting(for device: XYBluetoothDevice?) -> Bool {
        if let xyDevice = device as? XYFinderDevice {
            if xyDevice.state == .connecting { return true }
            if xyDevice.state == .connected {
                XYFinderDeviceEventManager.report(events: [.alreadyConnected(device: xyDevice)])
                return true
            }
        }

        return false
    }

    // Connect to the device using the connection agent, then subscribe to the button press and
    // start the readRSSI recursive loop. Use a 0-based sempahore to ensure only once device
    // can be in the connection state at one time
    func connect(to device: XYBluetoothDevice) {
        print("STEP 1: Trying to connect to \(device.id.shortId)...")
        device.connection {
            // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
            if let xyDevice = device as? XYFinderDevice {
                if !xyDevice.unlock().hasError && !xyDevice.subscribeToButtonPress().hasError {
                    xyDevice.peripheral?.readRSSI()
                } else {
                    throw XYBluetoothError.couldNotConnect
                }
            }

        }.then(on: XYBluetoothDeviceBase.workQueue) {
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceEventManager.report(events: [.connected(device: xyDevice)])
            }
            self.connectionLock.unlock()

        }.always(on: XYBluetoothDeviceBase.workQueue) {
            self.connectionLock.unlock()
        }

        self.connectionLock.lock()
    }

    func disconnect(from device: XYBluetoothDevice) {
        XYCentral.instance.disconnect(from: device)
    }
}
