//
//  XyoAdvertiser.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/18/19.
//

import Foundation
import XyBleSdk
import CoreLocation
import CoreBluetooth
import Promises
import sdk_core_swift

/// A class to manage the creating of XYO pipes at a high level on the bluetooth peripheral side.
public struct XyoBluetoothServer {
    static let IPhoneBrodcastId: UInt8 = 0x02
    
    /// The IBeacon major that will be advertised.
    public let randomSeed: UInt32
    
    /// The instance of the ble server that will be used to make bluetooth calls, and advertise.
    private let server = XYCBPeripheralManager.instance
    
    /// The mutable service to use for the XYO pipes.
    private let service = XYMutableService(cbService: CBMutableService(type: XyoService.pipe.serviceUuid, primary: true))
    
    /// Creates a new instance of this class with a ranom major and a random minor.
    public init () {
        self.randomSeed = UInt32.random(in: 0...UInt32.max)
    }
    
    /// Creates a new instance of this class with a set major and a set minor.
    public init (randomSeed: UInt32) {
        self.randomSeed = randomSeed
    }
    
    /// Starts the bluetooth server, and advertising. Will call back the the provided callback when a pipe has
    /// been created.
    /// - Parameter listener: The callback to call when a pipe has been found, this can be called mutpile times.
    public func start (listener: XyoPipeCharacteristicListener) {
        service.addCharacteristic(characteristic: XyoPipeCharacteristic(listener: listener))
    
        server.turnOn().then { (result) in
            if (result) {
                
                let beacon = CLBeaconRegion(proximityUUID: UUID(uuidString: XyoService.pipe.serviceUuid.uuidString)!,
                                            major: XyoBluetoothServer.getMajor(randomSeed: self.randomSeed, id: XyoBluetoothServer.IPhoneBrodcastId),
                                            minor: self.getMinor(),
                                            identifier: "xyo")
                
                
                let name = XyoGattNameEncoder.encode(major: XyoBluetoothServer.getMajor(randomSeed: self.randomSeed, id: XyoBluetoothServer.IPhoneBrodcastId), minor: self.getMinor())
                
                //XyoService.pipe.serviceUuid
                self.server.startAdvertiseing(advertisementUUIDs: [XyoService.pipe.serviceUuid], deviceName: name, beacon: beacon)
                self.server.addService(service: self.service)
            }
            
        }
    }
    
    static func getMajor (randomSeed: UInt32, id: UInt8) -> UInt16 {
        let majorRandomMask: UInt32 =   0b1111_1111_1100_0000_0000_0000_0000_0000
        let majorWithRandom = (majorRandomMask & randomSeed)
        let majorWithId = (UInt32(id & 0b0011_1111) << 16)
        let majorWithRandomAndId = majorWithRandom | majorWithId
        
        return UInt16(majorWithRandomAndId >> 16)
        
    }
    
    private func getMinor () -> UInt16 {
        return 0
    }
    
    /// Turns off the server and advertising
    public func stop () {
        service.removeCharacteristics()
        server.stopAdvetrtising()
        server.turnOff()
    }
}
