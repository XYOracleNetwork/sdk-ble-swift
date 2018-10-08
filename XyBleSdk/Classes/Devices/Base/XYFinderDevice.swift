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
    @discardableResult func find() -> Promise<XYBluetoothResult>
    @discardableResult func stayAwake() -> Promise<XYBluetoothResult>
    @discardableResult func fallAsleep() -> Promise<XYBluetoothResult>
    @discardableResult func lock() -> Promise<XYBluetoothResult>
    @discardableResult func unlock() -> Promise<XYBluetoothResult>

    func update(_ rssi: Int, powerLevel: UInt8)
}

// MARK: Default implementations of protocol methods and variables
public extension XYFinderDevice {

    var uuid: UUID {
        return self.family.uuid
    }

    var name: String {
        return self.family.familyName
    }

    var prefix: String {
        return self.family.prefix
    }

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid() -> CBUUID {
            let uuidSource = family.connectableSourceUuid
            let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uuidSource?.getBytes(uuidBytes)
            for i in (0...11) {
                uuidBytes[i] = uuidBytes[i + 4];
            }
            uuidBytes[13] = UInt8(major & 0x00ff)
            uuidBytes[12] = UInt8((major & 0xff00) >> 8)
            uuidBytes[15] = UInt8(minor & 0x00f0) | 0x04
            uuidBytes[14] = UInt8((minor & 0xff00) >> 8)

            return CBUUID(data: Data(bytes:uuidBytes, count:16))
        }

        return [XYFinderDeviceFamily.powerLow, XYFinderDeviceFamily.powerHigh].map { _ in getServiceUuid() }
    }

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

    @discardableResult func find() -> Promise<XYBluetoothResult> {
        let result = XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        return Promise<XYBluetoothResult>(result)
    }

    @discardableResult func stayAwake() -> Promise<XYBluetoothResult> {
        let result = XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        return Promise<XYBluetoothResult>(result)
    }

    @discardableResult func fallAsleep() -> Promise<XYBluetoothResult> {
        let result = XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        return Promise<XYBluetoothResult>(result)
    }

    @discardableResult func lock() -> Promise<XYBluetoothResult> {
        let result = XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        return Promise<XYBluetoothResult>(result)
    }

    @discardableResult func unlock() -> Promise<XYBluetoothResult> {
        let result = XYBluetoothResult(error: XYBluetoothError.actionNotSupported)
        return Promise<XYBluetoothResult>(result)
    }
}
