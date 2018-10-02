//
//  XYDeviceCache.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth

class XYDeviceCache {

    public fileprivate(set) static var devices = [String: XYFinderDevice]()

    private static let lock = DispatchQueue(label:"com.xyfindables.sdk.XYDeviceCacheQueue")

    class func add(_ device: XYFinderDevice) {
        lock.sync {
            guard self.devices[device.id] == nil else { return }
            self.devices[device.id] = device
        }
    }

    class func add(_ devices: [XYFinderDevice]) {
        devices.forEach { self.add($0) }
    }

    class func update(_ device: XYFinderDevice, rssi: Int, powerLevel: UInt8) {
        lock.sync {
            self.devices[device.id]?.update(rssi, powerLevel: powerLevel)
        }
    }

}
