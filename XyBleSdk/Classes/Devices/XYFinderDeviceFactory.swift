//
//  XYFinderDeviceFactory.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

// Factory to build a flavored XYFinderDevice based on the inputs
public class XYFinderDeviceFactory {

    class func build(from iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) -> XYFinderDevice? {
        guard let family = XYFinderDeviceFamily.get(from: iBeacon) else { return nil }

        var device: XYFinderDevice?
        if let foundDevice = XYDeviceCache.devices[iBeacon.xyId(from: family)] {
            XYDeviceCache.update(foundDevice, rssi: rssi, powerLevel: iBeacon.powerLevel)
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
                XYDeviceCache.add(device)
            }
        }

        return device
    }

    class func build(from family: XYFinderDeviceFamily) -> XYFinderDevice? {
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
