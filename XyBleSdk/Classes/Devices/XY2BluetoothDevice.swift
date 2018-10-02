//
//  XY2BluetoothDevice.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

import CoreBluetooth
import Promises

// The XY2-specific implementation
public class XY2BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public let family: XYFinderDeviceFamily = .xy2

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy2), iBeacon: iBeacon, rssi: rssi)
    }

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid(_ connectablePowerLevel: UInt8) -> CBUUID {
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

        return [XYFinderDeviceFamily.powerLow, XYFinderDeviceFamily.powerHigh].map { getServiceUuid($0) }
    }

}

extension XY2BluetoothDevice: XYFinderDevice {
    @discardableResult public func find() -> Promise<Void>? {
        guard let peripheral = self.peripheral, peripheral.state == .connected else { return nil }
        let song = Data(XYFinderSong.findIt.values(for: self.family))
        return ControlService.buzzerSelect.set(to: self, value: XYBluetoothResult(data: song))
    }

    @discardableResult public func stayAwake() -> Promise<Void>? {
        return Promise<Void>(XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func fallAsleep() -> Promise<Void>? {
        return Promise<Void>(XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func lock() -> Promise<Void>? {
        return Promise<Void>(XYBluetoothError.actionNotSupported)
    }

    @discardableResult public func unlock() -> Promise<Void>? {
        return Promise<Void>(XYBluetoothError.actionNotSupported)
    }
}
