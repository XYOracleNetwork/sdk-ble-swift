//
//  XYFinderDeviceManager.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/25/18.
//

import CoreBluetooth

class XYFinderDeviceManager {

    fileprivate var devices = [String: XYBluetoothDevice]()
    private let managerQueue = DispatchQueue(label:"com.xyfindables.sdk.XYFinderDeviceManagerQueue", attributes: .concurrent)
    fileprivate let connectionLock = DispatchSemaphore(value: 1)

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    func add(device: XYBluetoothDevice) {
        self.managerQueue.async(flags: .barrier) {
            guard self.devices[device.id] == nil else { return }
            self.devices[device.id] = device
            self.connect(for: device)
        }
    }

    // Connect to the device using the connection agent, ensuring work is done on a BG queue
    private func connect(for device: XYBluetoothDevice) {
        self.lock()
        XYConnectionAgent(for: device).connect().then(on: XYCentral.centralQueue) {
            self.unlock()
        }
    }


//    func remove(at index: String) {
//        self.accessQueue.async(flags: .barrier) {
//            self.devices.removeValue(forKey: index)
//        }
//    }


    // Threadsafe lookup for a tracked device
    subscript(index: String) -> XYBluetoothDevice? {
        get {
            var device: XYBluetoothDevice?
            self.managerQueue.sync {
                device = self.devices[index]
            }
            return device
        }
    }

}

// MARK: Use semaphore locks to ensure one at a time connection due to the central callbacks
private extension XYFinderDeviceManager {
    func lock() {
        if self.connectionLock.wait(timeout: .now() + GattRequest.waitTimeout) == .timedOut {
            unlock()
        }
    }

    func unlock() {
        self.connectionLock.signal()
    }
}
