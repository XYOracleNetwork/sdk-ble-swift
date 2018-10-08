//
//  XY4BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY4-specific implementation
public class XY4BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public fileprivate(set) var
    powerLevel: UInt8 = 4

    public let family: XYFinderDeviceFamily = .xy4

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy4), iBeacon: iBeacon, rssi: rssi)
    }

    public var connectableServices: [CBUUID] {
        guard let major = iBeacon?.major, let minor = iBeacon?.minor else { return [] }

        func getServiceUuid(_ connectablePowerLevel: UInt8) -> CBUUID {
            let uuidSource = family.connectableSourceUuid
            let uuidBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
            uuidSource?.getBytes(uuidBytes)

            uuidBytes[2] = UInt8(major & 0x00ff)
            uuidBytes[3] = UInt8((major & 0xff00) >> 8)
            uuidBytes[0] = UInt8(minor & 0x00f0) | connectablePowerLevel
            uuidBytes[1] = UInt8((minor & 0xff00) >> 8)

            return CBUUID(data: Data(bytes:uuidBytes, count:16))
        }

        return [XYFinderDeviceFamily.powerLow, XYFinderDeviceFamily.powerHigh].map { getServiceUuid($0) }
    }

}

extension XY4BluetoothDevice: XYFinderDevice {
    public func update(_ rssi: Int, powerLevel: UInt8) {
        super.detected()
        self.powerLevel = powerLevel
        self.rssi = rssi
    }

    @discardableResult public func find() -> Promise<XYBluetoothResult> {
        let song = Data(XYFinderSong.findIt.values(for: self.family))
        let resultPromise = Promise<XYBluetoothResult>.pending()
        var resultValue: XYBluetoothResult?
        self.connection {
            resultValue = self.set(PrimaryService.buzzer, value: XYBluetoothResult(data: song))
            }.then {
                if let result = resultValue {
                    if let error = result.error {
                        resultPromise.reject(error)
                    } else {
                        resultPromise.fulfill(result)
                    }
                } else {
                    resultPromise.reject(XYBluetoothError.dataNotPresent)
                }
        }

        return resultPromise
    }

    @discardableResult public func stayAwake() -> Promise<XYBluetoothResult> {
        let resultPromise = Promise<XYBluetoothResult>.pending()
        var resultValue: XYBluetoothResult?
        self.connection {
            resultValue = self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x01])))
        }.then {
            if let result = resultValue {
                if let error = result.error {
                    resultPromise.reject(error)
                } else {
                    resultPromise.fulfill(result)
                }
            } else {
                resultPromise.reject(XYBluetoothError.dataNotPresent)
            }
        }

        return resultPromise
    }

    @discardableResult public func fallAsleep() -> Promise<XYBluetoothResult> {
        let resultPromise = Promise<XYBluetoothResult>.pending()
        var resultValue: XYBluetoothResult?
        self.connection {
            resultValue = self.set(PrimaryService.stayAwake, value: XYBluetoothResult(data: Data([0x00])))
            }.then {
                if let result = resultValue {
                    if let error = result.error {
                        resultPromise.reject(error)
                    } else {
                        resultPromise.fulfill(result)
                    }
                } else {
                    resultPromise.reject(XYBluetoothError.dataNotPresent)
                }
        }

        return resultPromise
    }

    @discardableResult public func lock() -> Promise<XYBluetoothResult> {
        let resultPromise = Promise<XYBluetoothResult>.pending()
        var resultValue: XYBluetoothResult?
        self.connection {
            resultValue = self.set(PrimaryService.lock, value: XYBluetoothResult(data: self.family.lockCode))
            }.then {
                if let result = resultValue {
                    if let error = result.error {
                        resultPromise.reject(error)
                    } else {
                        resultPromise.fulfill(result)
                    }
                } else {
                    resultPromise.reject(XYBluetoothError.dataNotPresent)
                }
        }

        return resultPromise
    }

    @discardableResult public func unlock() -> Promise<XYBluetoothResult> {
        let resultPromise = Promise<XYBluetoothResult>.pending()
        var resultValue: XYBluetoothResult?
        self.connection {
            resultValue = self.set(PrimaryService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
            }.then {
                if let result = resultValue {
                    if let error = result.error {
                        resultPromise.reject(error)
                    } else {
                        resultPromise.fulfill(result)
                    }
                } else {
                    resultPromise.reject(XYBluetoothError.dataNotPresent)
                }
        }

        return resultPromise
    }
}
