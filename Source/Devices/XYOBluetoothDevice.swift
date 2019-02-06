//
//  XYOBluetoothDevice.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/5/19.
//

import Foundation

public class XYOBluetoothDevice: XYBluetoothDeviceBase {
    public static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XYOBluetoothDevice.uuid)!,
                                                   prefix: XYOBluetoothDevice.prefix,
                                                   familyName: XYOBluetoothDevice.familyName,
                                                   id: XYOBluetoothDevice.id)
    
    public static let id = "XYO"
    public static let uuid : String = "d684352e-df36-484e-bc98-2d5398c5593e"
    public static let familyName : String = "XYO"
    public static let prefix : String = "xy:ibeacon"
    
    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(id, rssi: rssi, family: XYOBluetoothDevice.family, iBeacon: iBeacon)
    }
    
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XYOBluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }
    
    public func tryCreatePipe (catalogue : [UInt8]) -> XYBluetoothResult {
        let data = Data(bytes: catalogue)
        self.connect()
        return self.set(XYOSerive.read, value: XYBluetoothResult(data: data))
    }
    
    override public func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        for item in peripheral.advertisementData.unsafelyUnwrapped.values {
            print(item)
        }
        guard let serviceUuid = peripheral.beaconDefinitionFromAdData else {
            return false
        }
        
        return serviceUuid.uuid == UUID(uuidString: XYOBluetoothDevice.uuid)
        
    }
}
