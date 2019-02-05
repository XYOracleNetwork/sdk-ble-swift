//
//  XYIBeaconDefinition.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation
import CoreLocation

// A wrapper around the iBeacon advertisement data used by XY devices for ranging
public struct XYIBeaconDefinition: Equatable {
    public let
    uuid: UUID,
    major: UInt16?,
    minor: UInt16?

    public var hasMajor: Bool {
        return major != nil && major! > 0
    }

    public var hasMinor: Bool {
        return minor != nil && minor! > 0
    }

    // Filters out the power level to generate a consistent minor value
    public func mainMinor(for family: XYDeviceFamily, slot: UInt16? = nil) -> UInt16? {
        guard let minor = self.minor else { return nil }
        switch family.id {
        case XY4BluetoothDevice.id, XY3BluetoothDevice.id, XY2BluetoothDevice.id, XYGPSBluetoothDevice.id:
            return (minor & 0xfff0) | (slot ?? 0x0004)
        default:
            return minor
        }
    }

    public var toString: String {
        var val = self.uuid.uuidString
        if let major = self.major {
            val += ".\(major)"
        }

        if let minor = self.minor {
            val += ".\(minor)"
        }

        return val
    }

    // Builds the beacon definition based on the uuid, major and minor
    public func xyId(from family: XYDeviceFamily) -> String {
        var xyid = [family.prefix, family.uuid.uuidString.lowercased()].joined(separator: ":")
        if let minor = mainMinor(for: family), let major = self.major {
            xyid.append(String(format: ".%ld.%ld", major, minor))
        } else if let major = self.major {
            xyid.append(String(format: ".%ld", major))
        }

        return xyid.lowercased()
    }

    public static func beacon(from xyId: String) -> XYIBeaconDefinition? {
        let parts = xyId.components(separatedBy: ":")

        if parts[safe: 1] == "near" {
            guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000000") else { return nil }
            return XYIBeaconDefinition(uuid: uuid, major: 0, minor: 0)
        }

        guard
            parts.count == 3,
            parts[safe: 0] == "xy"
            else { return nil }

        if parts[safe: 1] == "ibeacon" || parts[safe: 1] == "gps" || parts[safe: 1] == "mobiledevice" || parts[safe: 1] == "mobile" {
            guard
                let ids = parts[safe: 2]?.components(separatedBy: "."),
                let first = ids[safe: 0], let second = ids[safe: 1], let third = ids[safe: 2],
                let uuid = UUID(uuidString: first),
                let major = UInt16(second, radix: 10),
                let minor = UInt16(third, radix:10)
                else { return nil }

            return XYIBeaconDefinition(uuid: uuid, major: major, minor: minor)
        }

        return nil
    }

    // Determines the power value from the minor, changed when a user presses the button on the finder
    public var powerLevel: UInt8 {
        guard
            let minor = self.minor
            else { return UInt8(4) }
        return UInt8(minor & 0xf)
    }

    public static func ==(lhs: XYIBeaconDefinition, rhs: XYIBeaconDefinition) -> Bool {
        return lhs.toString == rhs.toString
    }
}

#if os(iOS)
// MARK: CLBeacon Convenience
extension CLBeacon {
    var xyiBeaconDefinition: XYIBeaconDefinition {
        return XYIBeaconDefinition(
            uuid: self.proximityUUID,
            major: self.major as? UInt16,
            minor: self.minor as? UInt16)
    }

    var family: XYDeviceFamily? {
        return XYDeviceFamily.build(iBeacon: self.xyiBeaconDefinition)
    }
}

// MARK: CLBeaconRegion Convenience
extension CLBeaconRegion {
    var xyiBeaconDefinition: XYIBeaconDefinition {
        return XYIBeaconDefinition(
            uuid: self.proximityUUID,
            major: self.major as? UInt16,
            minor: self.minor as? UInt16)
    }

    var family: XYDeviceFamily? {
        return XYDeviceFamily.build(iBeacon: self.xyiBeaconDefinition)
    }
}
#endif

