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
    fileprivate lazy var waitQueue = [String]()
    fileprivate let managerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceManagerQueue", attributes: .concurrent)

    fileprivate let connectionLock = GenericLock(0)
    fileprivate let reconnectLock = GenericLock(0)

    public var connectedDevices: [XYBluetoothDevice] {
        return self.devices.map { $1 }
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
    func remove(for id: String) {
        guard self.devices[id] != nil else { return }
        self.managerQueue.async(flags: .barrier) {
            guard let device = self.devices[id] else { return }
            self.devices.removeValue(forKey: device.id)
            self.disconnect(from: device)
        }
    }

    // If we lose connection to a device, we can put it in the wait queue and it will automatically reconnect
    // even if the user leaves the area (as long as the app is still running in the backgound)
    func wait(for device: XYBluetoothDevice) {
        // Quick escape if we already have the device and it is connected or it's already connecting
        guard !isConnectedOrConnecting(for: self.devices[device.id]) else { return }

        // We have lost contact with the device, so we'll do a non-expiring connectiong try
        guard !waitQueue.contains(where: { $0 == device.id }) else { return }
        self.managerQueue.async(flags: .barrier) {
            guard !self.waitQueue.contains(where: { $0 == device.id }) else { return }
            print("Adding \(device.id) to wait queue...")
            XYConnectionAgent(for: device).connect(.never).then(on: XYBluetoothDeviceBase.workQueue) {
                self.waitQueue.removeAll(where: { $0 == device.id })
                print("\(device.id) is found again!")
                if let xyDevice = device as? XYFinderDevice {
                    xyDevice.connection {
                        xyDevice.unlock()
                        xyDevice.subscribeToButtonPress()
                        xyDevice.peripheral?.readRSSI()
                        XYFinderDeviceEventManager.report(events: [.reconnected(device: xyDevice)])
                    }.always(on: XYBluetoothDeviceBase.workQueue) {
                        self.reconnectLock.unlock()
                    }

                    self.reconnectLock.lock()
                }
            }
        }
    }
}

// MARK: Connect and disconnection
private extension XYDeviceConnectionManager {

    func isConnectedOrConnecting(for device: XYBluetoothDevice?) -> Bool {
        if let xyDevice = device as? XYFinderDevice {
            guard xyDevice.state == .connecting else { return true }
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
                if xyDevice.peripheral?.state == .connected {
                    xyDevice.unlock()
                    xyDevice.subscribeToButtonPress()
                    xyDevice.peripheral?.readRSSI()
                }
            }
        }.then(on: XYBluetoothDeviceBase.workQueue) {
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceEventManager.report(events: [.connected(device: xyDevice)])
            }
        }.always(on: XYBluetoothDeviceBase.workQueue) {
            self.connectionLock.unlock()
        }.catch(on: XYBluetoothDeviceBase.workQueue) { error in
            guard let err = error as? XYBluetoothError else { return }
            switch err {
            case .timedOut:
                print("I've timed out trying to connect, so what should I do?")
                self.disconnect(from: device)
                if let xyDevice = device as? XYFinderDevice {
                    XYFinderDeviceEventManager.report(events: [.disconnected(device: xyDevice)])
                }
            default: break
            }
        }

        self.connectionLock.lock()
    }

    func disconnect(from device: XYBluetoothDevice) {
        XYCentral.instance.disconnect(from: device)
    }
}
