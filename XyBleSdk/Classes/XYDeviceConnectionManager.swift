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
    fileprivate let connectionLock = GenericLock()

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    func add(device: XYBluetoothDevice) {
        guard self.devices[device.id] == nil else { return }
        self.managerQueue.async(flags: .barrier) {
            guard self.devices[device.id] == nil else { return }
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

private extension XYDeviceConnectionManager {

    // Connect to the device using the connection agent, ensuring work is done on a BG queue
    func connect(for device: XYBluetoothDevice) {
        self.connectionLock.lock()
        XYConnectionAgent(for: device).connect().then(on: XYCentral.centralQueue) {
            self.connectionLock.unlock()

            // If we have an XY Finder device, we report this, subscribe to the button and kick off the RSSI read loop
            if let xyDevice = device as? XYFinderDevice {
                XYFinderDeviceEventManager.report(events: [.connected(device: xyDevice)])
                xyDevice.subscribeToButtonPress()
                if xyDevice.peripheral?.state == .connected {
                    xyDevice.peripheral?.readRSSI()
                }
            }
        }
    }

    func disconnect(from device: XYBluetoothDevice) {
        XYCentral.instance.disconnect(from: device)
    }

}
