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
    fileprivate let managerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceManagerQueue", attributes: .concurrent)

    fileprivate let connectionLock = GenericLock(0)

    public var connectedDevices: [XYBluetoothDevice] {
        return self.devices.map { $1 }
    }

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    func add(device: XYBluetoothDevice) {
        guard self.devices[device.id] == nil else {
            if let xyFound = self.devices[device.id] as? XYFinderDevice {
                if xyFound.state != .connected {
                    self.connect(for: xyFound)
                } else {
                    XYFinderDeviceEventManager.report(events: [.alreadyConnected(device: xyFound)])
                }
            }
            return
        }
        self.managerQueue.async(flags: .barrier) {
            guard self.devices[device.id] == nil else {
                if let xyFound = self.devices[device.id] as? XYFinderDevice {
                    if xyFound.state != .connected {
                        self.connect(for: xyFound)
                    } else {
                        XYFinderDeviceEventManager.report(events: [.alreadyConnected(device: xyFound)])
                    }
                }
                return
            }
            self.devices[device.id] = device
            self.connect(for: device)
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
}

// MARK: Connect and disconnection
private extension XYDeviceConnectionManager {

    func handleAlreadyConnected() {

    }

    // Connect to the device using the connection agent, then subscribe to the button press and
    // start the readRSSI recursive loop. Use a 0-based sempahore to ensure only once device
    // can be in the connection state at one time
    func connect(for device: XYBluetoothDevice) {
        XYConnectionAgent(for: device).connect().then(on: XYCentral.centralQueue) {
            // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceEventManager.report(events: [.connected(device: xyDevice)])
                if xyDevice.peripheral?.state == .connected {
                    xyDevice.subscribeToButtonPress()
                    xyDevice.peripheral?.readRSSI()
                }
            }
        }.always {
            self.connectionLock.unlock()
        }.catch { error in
            print(error.localizedDescription)
        }

        self.connectionLock.lock()
    }

    func disconnect(from device: XYBluetoothDevice) {
        XYCentral.instance.disconnect(from: device)
    }
}
