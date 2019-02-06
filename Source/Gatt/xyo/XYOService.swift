//
//  XYOService.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/5/19.
//

import Foundation
import CoreBluetooth

public enum XYOSerive : XYServiceCharacteristic {
    case read
    
    public var serviceDisplayName: String { return "Primary" }
    
    public var serviceUuid: CBUUID { return CBUUID(string: "d684352e-df36-484e-bc98-2d5398c5593e") }
    
    public var characteristicUuid: CBUUID { return CBUUID(string: "727a3639-0eb4-4525-b1bc-7fa456490b2d")}
    
    public var characteristicType: XYServiceCharacteristicType { return XYServiceCharacteristicType.byte }
    
    public var displayName: String { return "XYO" }
    
    public static var values: [XYServiceCharacteristic] = [ XYOSerive.read ]
    
}
