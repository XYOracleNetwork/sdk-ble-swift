//
//  XYOBluetoothDeviceCreator.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/5/19.
//

import Foundation
import XyBleSdk

/// A struct to manage the creation of XYO Devices to create pipes with.
public struct XyoBluetoothDeviceCreator : XYDeviceCreator {
    /// This is a mapping of xyo manufactor IDs (first 8 bits of iBeacon minor) to a sepcial type of device.
    public static var manufactorMap = [UInt8 : XyoManufactorDeviceCreator]()
    
    private init () {}
    
    /// The UUID that should be used when creating an XYO device.
    public static let uuid : String = XyoBluetoothDevice.uuid
    
    /// The device family deffinition.
    public var family: XYDeviceFamily = XyoBluetoothDevice.family
    
    /// A function to create an XYO device from an iBeacon deffinition.
    /// - Parameter iBeacon: The IBeacon deffinion of the device.
    /// - Parameter rssi: The rssi to create the device with.
    public func createFromIBeacon (iBeacon: XYIBeaconDefinition, rssi: Int) -> XYBluetoothDevice? {
        guard let manufactorId = getXyoManufactorIdFromIbeacon(iBeacon: iBeacon) else {
            return XyoBluetoothDevice(iBeacon: iBeacon, rssi: rssi)
        }
        
        guard let creator = XyoBluetoothDeviceCreator.manufactorMap[manufactorId] else {
            return XyoBluetoothDevice(iBeacon: iBeacon, rssi: rssi)
        }
        
        return creator.createFromIBeacon(iBeacon: iBeacon, rssi: rssi)
    }
    
    /// Creae an XyoBluetoothDevice from its repected peripheral ID.
    /// - Parameter id: The peripheral ID of the device.
    public func createFromId(id: String) -> XYBluetoothDevice {
        return XyoBluetoothDevice(id)
    }
    
    /// Enable the creater to be active in XYBluetoothDeviceFactory so that it can be created from bluetooth scan results.
    /// - Parameter enable: If true, will enable. If false, will disbale.
    public static func enable (enable : Bool) {
        if (enable) {
            XYBluetoothDeviceFactory.addCreator(uuid: XyoBluetoothDevice.uuid.lowercased(), creator: XyoBluetoothDeviceCreator())
        } else {
            XYBluetoothDeviceFactory.removeCreator(uuid: XyoBluetoothDevice.uuid.lowercased())
        }
    }
    
    private func getXyoManufactorIdFromIbeacon (iBeacon: XYIBeaconDefinition) -> UInt8? {
        guard let major = iBeacon.major else {
            return nil
        }
        
        let byte = XyoBuffer()
            .put(bits: major)
            .getUInt8(offset: 1)
        
        // masks the byte with 00111111
        return byte & 0x3f
    }
}
