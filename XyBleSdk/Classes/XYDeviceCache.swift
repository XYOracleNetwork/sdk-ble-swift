//
//  XYDeviceCache.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth

// Holds a cache for devices that have been found via the XYLocation manager
class XYDeviceCache {

    internal private(set) var devices = [String: XYFinderDevice]()
    private let accessQueue = DispatchQueue(label:"com.xyfindables.sdk.XYDeviceCacheQueue", attributes: .concurrent)

    func removeAll() {
        self.accessQueue.async(flags: .barrier) {
            self.devices.removeAll()
        }
    }

    func remove(at index: String) {
        self.accessQueue.async(flags: .barrier) {
            self.devices.removeValue(forKey: index)
        }
    }

    var count: Int {
        var count = 0
        self.accessQueue.sync { count = self.devices.count }
        return count
    }

    subscript(index: String) -> XYFinderDevice? {
        set {
            self.accessQueue.async(flags: .barrier) {
                self.devices[index] = newValue
            }
        }
        get {
            var device: XYFinderDevice?
            self.accessQueue.sync {
                device = self.devices[index]
            }
            return device
        }
    }
}
