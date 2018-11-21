//
//  XYFinderDeviceFactory.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation
import CoreBluetooth

// Factory to build a flavored XYFinderDevice based on the inputs
public class XYFinderDeviceFactory {

    internal static let deviceCache = XYDeviceCache()

    public static var devices: [XYFinderDevice] {
        return deviceCache.devices.map { $1 }
    }

    internal static func invalidateCache() {
        deviceCache.removeAll()
    }

    // Used to update all cached, in range device locations to the current user's location
    public static func updateDeviceLocations(_ newLocation: XYLocationCoordinate2D) {
        devices.filter { $0.inRange }.forEach { $0.updateLocation(newLocation) }
    }

    // Create a device from an iBeacon definition, or update a cached device with the latest iBeacon/rssi data
    public class func build(from iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.defaultProximity, updateRssiAndPower: Bool = false) -> XYFinderDevice? {
        guard let family = XYFinderDeviceFamily.get(from: iBeacon) else { return nil }

        // Build or update
        var device: XYFinderDevice?
        if let foundDevice = deviceCache[iBeacon.xyId(from: family)] {
            device = foundDevice
        } else {
            switch family {
            case .xygps:
                device = XYGPSBluetoothDevice(iBeacon, rssi: rssi)
            case .xy4:
                device = XY4BluetoothDevice(iBeacon, rssi: rssi)
            case .xy3:
                device = XY3BluetoothDevice(iBeacon, rssi: rssi)
            case .xy2:
                device = XY2BluetoothDevice(iBeacon, rssi: rssi)
            case .xymobile:
                device = XYMobileBluetoothDevice(iBeacon, rssi: rssi)
            default:
                device = nil
            }

            if let device = device {
                deviceCache[device.id] = device
            }
        }

        if updateRssiAndPower {
            // Update the device based on the read value if requested (typically when ranging beacons
            // to detect button presses and rssi changes)
            device?.update(rssi, powerLevel: iBeacon.powerLevel)
        }

        return device
    }

    public class func build(from xyId: String) -> XYFinderDevice? {
        guard let beacon = XYIBeaconDefinition.beacon(from: xyId) else { return nil }
        return self.build(from: beacon)
    }

    class func build(from peripheral: CBPeripheral) -> XYFinderDevice? {
        return devices.filter { $0.peripheral == peripheral }.first
    }

    public class func build(from family: XYFinderDeviceFamily) -> XYFinderDevice? {
        let id = [family.prefix, family.uuid.uuidString.lowercased()].joined(separator: ":")
        switch family {
        case .xygps:
            return XYGPSBluetoothDevice(id)
        case .xy4:
            return XY4BluetoothDevice(id)
        case .xy3:
            return XY3BluetoothDevice(id)
        case .xy2:
            return XY2BluetoothDevice(id)
        case .xymobile:
            return XYMobileBluetoothDevice(id)
        default:
            return nil
        }
    }

}
