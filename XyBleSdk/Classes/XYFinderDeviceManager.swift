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
    fileprivate let connectionLock = GenericLock()

    // Add a tracked device and connect to it, ensuring we do not add the same device twice as this method
    // will be called multiple times over the course of a session from the location and peripheral delegates
    func add(device: XYBluetoothDevice) {
        guard self.devices[device.id] == nil else { return }
        self.managerQueue.async(flags: .barrier) {
            self.devices[device.id] = device
            self.connect(for: device)
        }
    }

    // Connect to the device using the connection agent, ensuring work is done on a BG queue
    private func connect(for device: XYBluetoothDevice) {
        self.connectionLock.lock()
        XYConnectionAgent(for: device).connect().then(on: XYCentral.centralQueue) {
            self.connectionLock.unlock()
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
