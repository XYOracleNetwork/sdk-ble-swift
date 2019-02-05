
//
//  XYBluetoothDeviceFactort.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation
import CoreBluetooth

public class XYBluetoothDeviceFactory {
    private static var  uuidToCreators = [String : XYDeviceCreator]()
    internal static let deviceCache = XYDeviceCache()
    
    public static func addCreator (uuid : String, creator: XYDeviceCreator) {
        uuidToCreators[uuid] = creator
    }
    
    public static func removeCreator (uuid: String) {
        uuidToCreators.removeValue(forKey: uuid)
    }
    
    public static var devices: [XYBluetoothDevice] {
        return deviceCache.devices.map {
            $1
        }
    }
    
    internal static func invalidateCache() {
        deviceCache.removeAll()
    }
    
    internal static func remove(device: XYBluetoothDevice) {
        self.deviceCache.remove(at: device.id)
    }
    
    public class func build(from xyId: String) -> XYBluetoothDevice? {
        guard let beacon = XYIBeaconDefinition.beacon(from: xyId) else { return nil }
        return self.build(from: beacon)
    }
    
    class func build(from peripheral: CBPeripheral) -> XYBluetoothDevice? {
        return devices.filter {
            $0.peripheral == peripheral
        }.first
    }
    
    public static func updateDeviceLocations(_ newLocation: XYLocationCoordinate2D) {
        devices.filter { $0.inRange }.forEach {
            ($0 as? XYFinderDevice)?.updateLocation(newLocation)
        }
    }
    
    // Create a device from an iBeacon definition, or update a cached device with the latest iBeacon/rssi data
    public class func build(from iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.defaultProximity, updateRssiAndPower: Bool = false) -> XYBluetoothDevice? {
        guard let family = XYDeviceFamily.build(iBeacon: iBeacon) else {
            return nil
        }
        
        // Build or update
        var device: XYBluetoothDevice?
        if let foundDevice = deviceCache[iBeacon.xyId(from: family)] {
            device = foundDevice
        } else {
            device = uuidToCreators[iBeacon.uuid.uuidString]?.createFromIBeacon(iBeacon: iBeacon, rssi: rssi)
            
            if let device = device {
                deviceCache[device.id] = device
            }
        }
        
        if updateRssiAndPower {
            // Update the device based on the read value if requested (typically when ranging beacons
            // to detect button presses and rssi changes)
            device?.update(rssi, powerLevel: iBeacon.powerLevel)
        }
        
        return device
    }
    
    public class func build (from family: XYDeviceFamily) -> XYBluetoothDevice? {
        let id = [family.prefix, family.uuid.uuidString.lowercased()].joined(separator: ":")
        return uuidToCreators[family.uuid.uuidString]?.createFromId(id: id)
    }
}
