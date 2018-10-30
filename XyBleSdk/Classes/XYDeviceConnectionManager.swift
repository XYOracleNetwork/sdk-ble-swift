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
    fileprivate var building = false

    public var connectedDevices: [XYBluetoothDevice] {
        return self.devices.map { $1 }
    }

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

    func buildDaemon() {
        self.managerQueue.asyncAfter(deadline: DispatchTime.now() + TimeInterval(XYConstants.DEVICE_TUNING_SECONDS_EXIT_CHECK_INTERVAL)) {
            guard self.devices.filter({ $1.peripheral?.state == .connected }).count > 0, self.building == false else { self.buildDaemon(); return }
            if let toBuild = self.devices.filter({ $1.peripheral?.state == .disconected }).first {
                self.building = true
                self.connect(for: toBuild)
            }
        }
    }
}

private extension XYDeviceConnectionManager {

    // Connect to the device using the connection agent, ensuring work is done on a BG queue
    func connect(for device: XYBluetoothDevice) {
        self.connectionLock.lock("XYDeviceConnectionManager: id \(device.id)")
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
