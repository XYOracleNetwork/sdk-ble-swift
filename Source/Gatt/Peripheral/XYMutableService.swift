//
//  XYMutableService.swift
//  XyBleSdk
//
//  Created by Carter Harrison on 2/19/19.
//

import Foundation
import CoreBluetooth

open class XYMutableService {
    public var characteristics = [String : XYMutableCharacteristic]()
    public let cbService : CBMutableService
    
    public init (cbService: CBMutableService) {
        self.cbService = cbService
        cbService.characteristics = []
    }
    
    public func addCharacteristic (characteristic: XYMutableCharacteristic) {
        characteristics[characteristic.cbCharacteristic.uuid.uuidString] = characteristic
        cbService.characteristics?.append(characteristic.cbCharacteristic)
    }
    
    public func removeCharacteristic (characteristic : XYMutableCharacteristic) {
        characteristics.removeValue(forKey: characteristic.cbCharacteristic.uuid.uuidString)
        guard let i = cbService.characteristics?.lastIndex(where: { (n) -> Bool in
            n.uuid.uuidString == characteristic.cbCharacteristic.uuid.uuidString
        }) else {
            return
        }
        
        cbService.characteristics?.remove(at: i)
    }
  
    public func removeCharacteristics() {
      characteristics.removeAll()
      cbService.characteristics?.removeAll()
    }
    
    open func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        characteristics[request.characteristic.uuid.uuidString]?.handleReadRequest(request, peripheral: peripheral)
    }
    
    open func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        characteristics[request.characteristic.uuid.uuidString]?.handleWriteRequest(request, peripheral: peripheral)
    }
    
    open func handleSubscribeToCharacteristic(characteristic: CBMutableCharacteristic, peripheral: CBPeripheralManager) {
        characteristics[characteristic.uuid.uuidString]?.handleSubscribeToCharacteristic(peripheral: peripheral)
    }
}
