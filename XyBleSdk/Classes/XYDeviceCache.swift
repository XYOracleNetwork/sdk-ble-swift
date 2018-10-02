//
//  XYDeviceCache.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth

class XYDeviceCache {

    public fileprivate(set) static var devices = [String: XYFinderDevice]()

    class func add(_ device: XYFinderDevice) {
        guard self.devices[device.id] == nil else { return }
        self.devices[device.id] = device
    }

    class func add(_ devices: [XYFinderDevice]) {
        devices.forEach { self.add($0) }
    }

    class func update(_ device: XYFinderDevice, rssi: Int, powerLevel: UInt8) -> XYFinderDevice? {
        self.devices[device.id]?.update(rssi, powerLevel: powerLevel)
        return self.devices[device.id]
    }

}
