//
//  XYFinderDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Promises

// A device from the XY family, has an iBeacon and other XY-specific identifiers
public protocol XYFinderDevice: XYBluetoothDevice {
    var uuid: UUID { get }
    var iBeacon: XYIBeaconDefinition? { get }
    var family: XYFinderDeviceFamily { get }
    var prefix: String { get }
    var connectableServices: [CBUUID] { get }
    var powerLevel: UInt8 { get }

    // Convenience methods for common operations
    @discardableResult func find() -> Promise<Void>?
    @discardableResult func stayAwake() -> Promise<Void>?
    @discardableResult func fallAsleep() -> Promise<Void>?
    @discardableResult func lock() -> Promise<Void>?
    @discardableResult func unlock() -> Promise<Void>?

    func update(_ rssi: Int, powerLevel: UInt8)
}

// MARK: Default implementations of protocol methods and variables
extension XYFinderDevice {

    public var uuid: UUID {
        return self.family.uuid
    }

    public var name: String {
        return self.family.familyName
    }

    public var prefix: String {
        return self.family.prefix
    }

//    public var powerLevel: UInt8 {
//        guard
//            let beacon = self.iBeacon,
//            let minor = beacon.minor
//            else { return UInt8(4) }
//        return UInt8(minor & 0xf)
//    }

    // Builds a beacon region for use in XYLocation based on the current XYIBeaconDefinition
    func beaconRegion(_ uuid: UUID, id: String, slot: UInt16? = nil) -> CLBeaconRegion {
        if iBeacon?.hasMinor ?? false, let major = iBeacon?.major, let minor = iBeacon?.minor {
            let computedMinor = slot == nil ? minor : ((minor & 0xfff0) | slot!)
            return CLBeaconRegion(
                proximityUUID: uuid,
                major: major,
                minor: computedMinor,
                identifier: String(format:"%@:4", id))
        }

        if iBeacon?.hasMajor ?? false, let major = iBeacon?.major {
            return CLBeaconRegion(
                proximityUUID: uuid,
                major: major,
                identifier: String(format:"%@:4", id))
        }

        return CLBeaconRegion(
            proximityUUID: uuid,
            identifier: String(format:"%@:4", id))
    }
    
}
