//
//  XYIBeaconDefinition.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreLocation

public struct XYIBeaconDefinition {
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

    public func mainMinor(for family: XYFinderDeviceFamily, slot: UInt16? = nil) -> UInt16? {
        guard let minor = self.minor else { return nil }
        switch family {
        case .xy4, .xy3, .xy2, .xygps:
            return (minor & 0xfff0) | (slot ?? 0x0004)
        default:
            return minor
        }
    }

    public func xyId(from family: XYFinderDeviceFamily) -> String {
        var xyid = [family.prefix, family.uuid.uuidString.lowercased()].joined(separator: ":")
        if let minor = mainMinor(for: family), let major = self.major {
            xyid.append(String(format: ".%ld.%ld", major, minor))
        } else if let major = self.major {
            xyid.append(String(format: ".%ld", major))
        }

        return xyid
    }
}

extension CLBeacon {
    var xyiBeaconDefinition: XYIBeaconDefinition {
        return XYIBeaconDefinition(
            uuid: self.proximityUUID,
            major: self.major as? UInt16,
            minor: self.minor as? UInt16)
    }
}

// MARK: Convenience
extension CLBeaconRegion {
    var xyiBeaconDefinition: XYIBeaconDefinition {
        return XYIBeaconDefinition(
            uuid: self.proximityUUID,
            major: self.major as? UInt16,
            minor: self.minor as? UInt16)
    }
}
