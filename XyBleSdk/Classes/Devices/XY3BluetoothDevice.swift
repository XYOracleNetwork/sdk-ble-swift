//
//  XY3BluetoothDevice.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/25/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import CoreBluetooth
import Promises

// The XY3-specific implementation
public class XY3BluetoothDevice: XYBluetoothDeviceBase {
    public let
    iBeacon: XYIBeaconDefinition?

    public fileprivate(set) var
    powerLevel: UInt8 = 4

    public let family: XYFinderDeviceFamily = .xy3

    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.iBeacon = iBeacon
        super.init(id, rssi: rssi)
    }

    public convenience init(_ iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: .xy3), iBeacon: iBeacon, rssi: rssi)
    }

}

extension XY3BluetoothDevice: XYFinderDevice {
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
            resultValue = self.set(ControlService.buzzerSelect, value: XYBluetoothResult(data: song))
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
            resultValue = self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x01])))
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
            resultValue = self.set(ExtendedConfigService.registration, value: XYBluetoothResult(data: Data([0x00])))
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
            resultValue = self.set(BasicConfigService.lock, value: XYBluetoothResult(data: self.family.lockCode))
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
            resultValue = self.set(BasicConfigService.unlock, value: XYBluetoothResult(data: self.family.lockCode))
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
