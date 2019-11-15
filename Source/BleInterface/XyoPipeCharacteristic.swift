//
//  XyoChar.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/19/19.
//

import Foundation
import CoreBluetooth
import sdk_core_swift
import sdk_objectmodel_swift

/// A class for managing the creation of pipes, the destructon of pipes, and the routing of write requests to pipes.
class XyoPipeCharacteristic : XYMutableCharacteristic, XyoGattServerLisitener {
    
    /// The CBMutableCharacteristic that complies with the XYO pipe protocal.
    internal var cbCharacteristic: CBMutableCharacteristic = CBMutableCharacteristic(type: XyoService.pipe.characteristicUuid,
                                                                                    properties: CBCharacteristicProperties(rawValue:
                                                                                        CBCharacteristicProperties.writeWithoutResponse.rawValue |
                                                                                        CBCharacteristicProperties.read.rawValue |
                                                                                        CBCharacteristicProperties.notify.rawValue |
                                                                                        CBCharacteristicProperties.indicate.rawValue |
                                                                                        CBCharacteristicProperties.write.rawValue),
                                                                                    value: nil,
                                                                                    permissions: CBAttributePermissions(rawValue:
                                                                                        CBAttributePermissions.readable.rawValue |
                                                                                        CBAttributePermissions.writeable.rawValue))
    
    /// A mapping of CBCentral ID UUID strings to their respected pipe.
    private var pipes = [String : XyoGattServerNetworkPipe] ()
    
    /// The listener to call back to after a pipe is created.
  private weak var listener : XyoPipeCharacteristicListener?
    
    /// Creats a new instance of XyoPipeCharacteristic
    /// - Parameter listener: The listener to call back to when a new pipe is created.
    init (listener : XyoPipeCharacteristicListener) {
        self.listener = listener
    }
    
    /// We do nothing in this function, it acts as a stub. According to the XYO pipe protocal, no reading
    /// is done on this characteristic.
    func handleReadRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {}
    
    /// We do nothing in this function, it acts as a stub. According to the XYO pipe protocal, no state changes
    /// need to happen when somone does or does not subscribe since it is neccacry.
    func handleSubscribeToCharacteristic(peripheral: CBPeripheralManager) {}
    
    /// This function manages the creation of pipes, routing of pipes, and will create a new pipe if none
    /// has been created for an induivudal pipe.
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        
        guard let manager = pipes[request.central.identifier.uuidString] else {
            // If you are here, there is no pipe created for the device, and the following code will create
            // a pipe for the device.
            print("new pipe")
            _ = createPipeWithWriteRequest(request, peripheral: peripheral)
            return
        }
        
        // this call routes the write request to the peoper pipe
        print("old pipe")
        manager.handleWriteRequest(request, peripheral: peripheral)
    }
    
    /// This function creates a new pipe with the write request, the value is expected to be an advertising packet.
    /// - Parameter request: The request to respond to after when creating the pipe.
    /// - Parameter peripheral: The peripheral create calls to when creating the pipe.
    /// - Returns: If the pipe creation was sucessfull or not.
    private func createPipeWithWriteRequest (_ request: CBATTRequest, peripheral: CBPeripheralManager) -> Bool {
        peripheral.respond(to: request, withResult: .success)
        let value : [UInt8] = [UInt8](request.value ?? Data())
        
        if (value.count > 4) {
            let buffer = XyoBuffer(data: value)
            let sizeOfCat = buffer.getUInt8(offset: 4)
            
            print(value.toHexString())
            if (sizeOfCat != value.count - 5) {
                return false
            }
            
            let catData = buffer.copyRangeOf(from: 4, to: buffer.getSize())
            let advPacket = XyoAdvertisePacket(data: catData.toByteArray())
            let pipe = XyoGattServerNetworkPipe(initiationData: advPacket,peripheral: peripheral,centrel: request.central, char: cbCharacteristic, listener: self)
            
            pipes[request.central.identifier.uuidString] = pipe
            listener?.onPipe(pipe: pipe)
            
            return true
        }
        
        return false
    }
    
    /// A callback used to manage the close function of a pipe, so that a new pipe can be created with the same device.
    /// This function will remove the pipe from the pipes map.
    /// - Parameter device: The device to remove the pipe from.
    func onClose(device : CBCentral) {
        pipes.removeValue(forKey: device.identifier.uuidString)
    }
}

/// A simple protocol to call back to when a new pipe has been created.
public protocol XyoPipeCharacteristicListener: class{
    
    /// This function will be called whenever a new pipe is created.
    /// - Warning: Calls off of this pipe will be blocking
    /// - Parameter pipe: The pipe that was just created with a centrel.
    func onPipe (pipe: XyoNetworkPipe)
}
