//
//  XYFinderDeviceBase.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/2/18.
//

//import Foundation
//
//class XYFinderDeviceBase: XYFinderDevice {
//    var iBeacon: XYIBeaconDefinition?
//
//    var family: XYFinderDeviceFamily
//
//    var connectableServices: [CBUUID]
//
//    func find() -> Promise<Void>? {
//        <#code#>
//    }
//
//    func stayAwake() -> Promise<Void>? {
//        <#code#>
//    }
//
//    func fallAsleep() -> Promise<Void>? {
//        <#code#>
//    }
//
//    func lock() -> Promise<Void>? {
//        <#code#>
//    }
//
//    func unlock() -> Promise<Void>? {
//        <#code#>
//    }
//
//    func detected(_ signalStrength: Int, powerLevel: UInt8) {
//        <#code#>
//    }
//
//    var peripheral: CBPeripheral?
//
//    var inRange: Bool
//
//    func subscribe(to serviceCharacteristic: XYServiceCharacteristic, delegate: (key: String, delegate: XYBluetoothDeviceNotifyDelegate)) {
//        <#code#>
//    }
//
//    func unsubscribe(from serviceCharacteristic: XYServiceCharacteristic, key: String) {
//        <#code#>
//    }
//
//    func subscribe(_ delegate: CBPeripheralDelegate, key: String) {
//        <#code#>
//    }
//
//    func unsubscribe(for key: String) {
//        <#code#>
//    }
//
//    func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
//        <#code#>
//    }
//
//    var rssi: Int
//
//    var id: String
//
//
//}
