//
//  XYIBeaconDefinition.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreLocation

// A wrapper around the iBeacon advertisement data used by XY devices for ranging
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

//    public func xyId2(from family: XYFinderDeviceFamily) -> String {
//        var mainMinor : UInt16
//        var xyId : String
//
//        if (minor != nil) {
//            if family == .xy4 || family == .xy3 || family == .xy2 || family == .xygps {
//                mainMinor = (minor! & 0xfff0) | 0x0004
//            } else if (family == .xy1){
//                mainMinor = minor!
//            } else {
//                mainMinor = minor!
//            }
//            xyId = String(format:"%@:%@.%ld.%ld", family.prefix, uuid.uuidString, major!, mainMinor).lowercased()
//        } else if (major != nil){
//            xyId = String(format:"%@:%@.%ld", family.prefix, uuid.uuidString, major!).lowercased()
//        } else {
//            xyId = String(format:"%@:%@", family.prefix, uuid.uuidString).lowercased()
//        }
//
//        return xyId
//    }

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

// MARK: CLBeacon Convenience
extension CLBeacon {
    var xyiBeaconDefinition: XYIBeaconDefinition {
        return XYIBeaconDefinition(
            uuid: self.proximityUUID,
            major: self.major as? UInt16,
            minor: self.minor as? UInt16)
    }

    var family: XYFinderDeviceFamily? {
        return XYFinderDeviceFamily.get(from: self.xyiBeaconDefinition)
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

    var family: XYFinderDeviceFamily? {
        return XYFinderDeviceFamily.get(from: self.xyiBeaconDefinition)
    }
}
