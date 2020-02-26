//
//  XYMutableCharacteristic.swift
//  XyBleSdk
//
//  Created by Carter Harrison on 2/19/19.
//

import Foundation
import CoreBluetooth

public protocol XYMutableCharacteristic {
    var cbCharacteristic : CBMutableCharacteristic { get }
    
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager)
    func handleSubscribeToCharacteristic(peripheral: CBPeripheralManager)
}
