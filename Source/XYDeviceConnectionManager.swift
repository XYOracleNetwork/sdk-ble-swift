//
//  XYFinderDeviceManager.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/25/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public final class XYDeviceConnectionManager {

    public static let instance = XYDeviceConnectionManager()
    private init() {}

    fileprivate var devices = [String: XYBluetoothDevice]()
    fileprivate var waitingDeviceIds = [String]()
    fileprivate let managerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceManagerQueue", attributes: .concurrent)
    fileprivate let waitQueue = DispatchQueue(label: "com.xyfindables.sdk.XYDeviceConnectionManager.WaitQueue")

    fileprivate let
    reconnectLock = GenericLock(0)

    fileprivate lazy var disconnectSubKeys = [String: UUID]()

    public var connectedDevices: [XYBluetoothDevice] {
        return self.devices.map { $1 }
    }

    func invalidate() {
        devices.forEach { $0.value.disconnect() }
    }

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    public func add(device: XYBluetoothDevice) {
        // Quick escape if we already have the device and it is connected or it's already connecting
        guard !isConnectedOrConnecting(for: self.devices[device.id]) else { return }

        // Check and connect
        guard self.devices[device.id] == nil else { return }
        self.devices[device.id] = device
        self.connect(to: device)
    }

    // Remove the devices from the dictionary of tracked, connected devices, and let central know to disconnect
    func remove(for id: String, disconnect: Bool) {
        guard let device = self.devices[id] else { return }
        self.devices.removeValue(forKey: device.id)
        self.waitingDeviceIds.removeAll(where: { $0 == device.id })
        if disconnect && (device.state != .disconnected || device.state != .disconnecting) {
            self.disconnect(from: device)
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

            self.waitingDeviceIds.append(device.id)

            XYConnectionAgent(for: device).connect(.never).then(on: self.waitQueue) {
                guard let xyDevice = device as? XYFinderDevice else {
                    self.reconnectLock.unlock()
                    return
                }

                // Check to see if we still want to connect to this
                guard self.waitingDeviceIds.contains(xyDevice.id) else {
                    xyDevice.disconnect()
                    self.reconnectLock.unlock()
                    return
                }

                self.waitingDeviceIds.removeAll(where: { $0 == device.id })
                print("\(device.id) is found again!")

                // Lock and try for a reconnection
                xyDevice.connection {
                    // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
                    if let xyDevice = device as? XYFinderDevice {
                        if xyDevice.unlock().hasError {
                            throw XYBluetoothError.couldNotConnect
                        }

                        if xyDevice.subscribeToButtonPress().hasError {
                            throw XYBluetoothError.couldNotConnect
                        }

                        xyDevice.peripheral?.readRSSI()
                    }

                }.then(on: self.waitQueue) {
                    if let xyDevice = device as? XYFinderDevice {
                        XYFinderDeviceEventManager.report(events: [.reconnected(device: xyDevice)])
                    }
                    self.reconnectLock.unlock()

                }.always(on: self.waitQueue) {
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

        // If we disconnect at any point in the connection, we remove the device so it can be tried again and unlock the connection semaphore
        // We also try to run the disconnect call in case we are watching the notifications
        self.disconnectSubKeys[device.id] = XYFinderDeviceEventManager.subscribe(to: [.disconnected]) { [weak self] event in
            XYFinderDeviceEventManager.unsubscribe(to: [.disconnected], referenceKey: self?.disconnectSubKeys[device.id])
            guard let finder = device as? XYFinderDevice, finder == event.device else { return }
            self?.devices[finder.id] = nil
        }

        let connectionQueue = DispatchQueue(label: "com.xyfindables.sdk.ConnectionManagerQueueFor\(device.id)")

        device.connection {
            // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
            if let xyDevice = device as? XYFinderDevice {
                if xyDevice.unlock().hasError {
                    throw XYBluetoothError.couldNotConnect
                }

                if xyDevice.subscribeToButtonPress().hasError {
                    throw XYBluetoothError.couldNotConnect
                }

                xyDevice.peripheral?.readRSSI()
            }

        }.then(on: connectionQueue) {
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceEventManager.report(events: [.connected(device: xyDevice)])
            }

            if self.waitingDeviceIds.contains(device.id) {
                self.waitingDeviceIds.removeAll(where: { $0 == device.id })
            }

        }.catch(on: connectionQueue) { error in
            guard let xyError = error as? XYBluetoothError, let xyDevice = device as? XYFinderDevice else { return }
            switch xyError {
            case .timedOut:
                XYFinderDeviceEventManager.report(events: [.timedOut(device: xyDevice, type: .connection)])
            default:
                XYFinderDeviceEventManager.report(events: [.connectionError(device: xyDevice, error: xyError)])
            }

            print("STEP 6: ERROR for \((error as! XYBluetoothError).toString) for device \(device.id)")

            // Completely disconnect so we can retry if there is any connection issue
            XYCentral.instance.disconnect(from: device)
            XYFinderDeviceFactory.remove(device: xyDevice)
            self.devices.removeValue(forKey: device.id)
            self.waitingDeviceIds.removeAll(where: { $0 == device.id })

        }.always(on: connectionQueue) {
            XYFinderDeviceEventManager.unsubscribe(to: [.disconnected], referenceKey: self.disconnectSubKeys[device.id])
        }
    }

    func disconnect(from device: XYBluetoothDevice) {
        print("STEP 1: Trying to DISCONNECT from \(device.id.shortId)...")

        let disconnectQueue = DispatchQueue(label: "com.xyfindables.sdk.ConnectionManagerDisconnectQueueFor\(device.id)")

        device.connection {
            // If we have an XY Finder device of a particular family, we unsubscribe from the button press and disconnect
            if let xyDevice = device as? XYFinderDevice, (xyDevice.family == .xy3 || xyDevice.family == .xy4 || xyDevice.family == .xygps) {
                if xyDevice.unlock().hasError {
                    throw XYBluetoothError.couldNotConnect
                }

                if xyDevice.unsubscribeToButtonPress(for: nil).hasError {
                    throw XYBluetoothError.couldNotConnect
                }
            }
        }.always(on: disconnectQueue) {
            print("STEP 2: Always on DISCONNECT from \(device.id.shortId)")
            XYCentral.instance.disconnect(from: device)
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceFactory.remove(device: xyDevice)
            }
        }
    }
}
