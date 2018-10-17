//
//  XYFinderDeviceFactory.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

// Factory to build a flavored XYFinderDevice based on the inputs
public class XYFinderDeviceFactory {

    internal static let deviceCache = XYDeviceCache()

    public static var devices: [XYFinderDevice] {
        return deviceCache.devices.map { $1 }
    }

    // Create a device from an iBeacon definition, or update a cached device with the latest iBeacon/rssi data
    public class func build(from iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) -> XYFinderDevice? {
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
            default:
                device = nil
            }

            if let device = device {
                deviceCache[device.id] = device
            }
        }

        // Update the device based on the read value
        device?.update(rssi, powerLevel: iBeacon.powerLevel)

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
        default:
            return nil
        }
    }

}
