//
//  XyoDifferentiableDevice.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 4/9/19.
//

import Foundation
import sdk_core_swift
import XyBleSdk
import sdk_objectmodel_swift
import CoreBluetooth

public class XyoDiffereniableDevice : XyoBluetoothDevice {
    override public func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        guard let major = self.iBeacon?.major else {
            return false
        }
        
        guard let minor = self.iBeacon?.minor else {
            return false
        }
        
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return false }
        
        
        for service in services {
            if (checkUuidWithMajorMinor(major: major, minor: minor, UUID: service)) {
                self.peripheral = peripheral.peripheral
                self.peripheral?.delegate = self
                return true
            }
        }
        
        return false
    }
    
    private func checkUuidWithMajorMinor (major: UInt16, minor: UInt16, UUID: CBUUID) -> Bool {
        let encodedMajor = XyoBuffer().put(bits: major).toByteArray()
        let encodedMinor = XyoBuffer().put(bits: minor).toByteArray()
        let uuidBytes: [UInt8] = UUID.data.map { $0 }
        
        if (uuidBytes.count < 4) {
            return false
        }
        
        let encodedMinorOfUuid = XyoBuffer(data: [uuidBytes[0], uuidBytes[1]]).toByteArray()
        let encodedMajorOfUuid = XyoBuffer(data: [uuidBytes[2], uuidBytes[3]]).toByteArray()
        
        return (encodedMajor == encodedMajorOfUuid) && (encodedMinor[0] == encodedMinorOfUuid[0])
    }

}
