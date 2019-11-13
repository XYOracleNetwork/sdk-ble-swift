//
//  XyoService.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/10/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import CoreBluetooth
import XyBleSdk

/// This acts as the primary service for all XYO related things (the pipe abstraction).
public enum XyoService : XYServiceCharacteristic {
    /// This is the pipe chararistic where the primary pipe notifactions live.
    case pipe
    
    /// This is the characteristic to change the password of a device
    case password
    
    /// This is the characteristic to change bound witness data of a device
    case boundWitnessData

    /// For reseting the device
    case factoryReset
    
    /// For getting the public key
    case publicKey

    /// For staying away
    case stayAwake
    
    /// The display name of the service.
    public var serviceDisplayName: String {
        return "Primary"
    }
    
    /// The CBUUID of the service.
    // d684352e-df36-484e-bc98-2d5398c5593e - Production UUID
    // e3955c8935d2-89cb-e484-63fd-e253486d - Reversed UUID
    // ffffffff-df36-484e-bc98-2d5398c5593e - Testnet UUID
    public var serviceUuid: CBUUID {
        return CBUUID(string: "d684352e-df36-484e-bc98-2d5398c5593e")
        
    }
    
    /// The uuid of any characteristic.
    public var characteristicUuid: CBUUID {
        switch self {
        case .pipe: return                  CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa456490b2d")
        case .password: return              CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa4564A0b2d")
        case .boundWitnessData: return      CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa4564B0b2d")
        case .factoryReset: return          CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa4564C0b2d")
        case .publicKey: return             CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa4564D0b2d")
        case .stayAwake: return             CBUUID(string: "a44eacf4-0104-0001-0001-5f784c9977b5")
        }
    }
    
    /// The type of the characteristic.
    public var characteristicType: XYServiceCharacteristicType { return XYServiceCharacteristicType.byte }
    
    /// The display name of the characteristic.
    public var displayName: String {
        switch self {
        case .pipe: return "XYO Pipe"
        case .password: return "Change Password"
        case .boundWitnessData: return "Change Bound Witness Data"
        case .factoryReset: return "Factory Reset"
        case .publicKey: return "Get public key"
        case .stayAwake: return "Stay Awake"
        }
    }
    
    /// All characteristic values under the service.
    public static var values: [XYServiceCharacteristic] = [ XyoService.pipe ]
    
}
