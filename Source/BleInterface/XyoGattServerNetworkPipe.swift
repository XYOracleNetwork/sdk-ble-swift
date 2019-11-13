//
//  XyoCharManager.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/19/19.
//

import Foundation
import CoreBluetooth
import sdk_core_swift
import Promises

/// A class to conform to the XyoNetworkPipe protocal, acting as a gatt server.
class XyoGattServerNetworkPipe : XyoNetworkPipe {
  func getNetworkHeuristics() -> [XyoObjectStructure] {
    return []
  }
  
    private var readPromise = Promise<[UInt8]?>.pending()
    private let inputStream = XyoInputStream()
    
    private let centrel : CBCentral
    private let char : CBMutableCharacteristic
    private let peripheral : CBPeripheralManager
    private let initiationData : XyoAdvertisePacket
    private let listener : XyoGattServerLisitener
    
    /// Creats a new instance of the object.
    /// - Parameter initiationData: The data that this pipe was created with, this can be retrived from getInitiationData()
    /// - Parameter peripheral: The peripheral object to make notifaction calls to.
    /// - Parameter centrel: The centrel that is at the other end of the pipe.
    /// - Parameter char: The gatt characteristic to make calls to, during the pipe. This should be the XYO chararistic.
    /// - Parameter listener: The lisistener to call back to when the pipe should be dicarded.
    init (initiationData : XyoAdvertisePacket,
          peripheral : CBPeripheralManager,
          centrel : CBCentral,
          char: CBMutableCharacteristic,
          listener: XyoGattServerLisitener) {
        
        self.initiationData = initiationData
        self.peripheral = peripheral
        self.centrel = centrel
        self.char = char
        self.listener = listener
    }
    
    /// This function gets the data that this pipe was created with. This is the first packet the the client sends to the server.
    /// - Returns: Returns the advertise packet (the first packet) that the client sent, this will be nil if nothing was sent.
    func getInitiationData() -> XyoAdvertisePacket? {
        return initiationData
    }
    
    

    /// This function is used to send a recive data through the XYO Pipe. It sends data by sending notifactions,
    /// and recives data via a write requests.
    /// - Warning: This function is blocking as it waits for write requests.
    /// - Parameter data: The data to send to the device at the end of the pipe.
    /// - Parameter waitForResponse: If the the device should wait after connecting for a response (XYO write requests.)
    /// - Returns: Will return the response of the party at the other end of the pipe, this will be nil if no data
    /// was recived or if waitForResponse was set to false
    func send(data: [UInt8], waitForResponse: Bool, completion: @escaping ([UInt8]?) -> ()) {
        chunkSend(data: data)
        
        if (waitForResponse) {
            let currentPacet = inputStream.getOldestPacket()
            if (currentPacet != nil) {
                completion(currentPacet)
                return
            }
            
            self.readPromise = Promise<[UInt8]?>.pending().timeout(20)
            
            do {
                return completion(try await(readPromise))
            } catch {
                // timeout has occured
                completion(nil)
                return
            }
        }
        
        completion(nil)
    }
    
    /// This function should be called whenever a device disconnects or is no longer in use. Not calling
    /// this function will not allow other XYO pipe based connections with this device.
    func close() {
        listener.onClose(device: centrel)
    }
    
    /// This function sends data through use of notifactions according to the XYO Network BLE protocal.
    /// The data passed through this function appends the size of the packet as a 4 byte int.
    ///
    /// - Parameter data: The Data to Send.
    /// - Parameter timeout: The timeout to wait in beetwen sending notifactions. Defualt is 1/10th of a second.
    private func chunkSend (data : [UInt8], timeout : UInt32 = 100000) {
        let sizeEncoded = XyoBuffer()
            .put(bits: UInt32(data.count + 4))
            .put(bytes: data)
            .toByteArray()
        
        
        print("Sending Entire:" + sizeEncoded.toHexString())
        let chunks = XyoOutputStream.chunk(bytes: sizeEncoded, maxChunkSize: centrel.maximumUpdateValueLength - 3)
        
        for chunk in chunks {
            char.value = Data(chunk)
            
            // introduce a deley so that packets do not arrive out of order TODO find way to wait for completion
            usleep(timeout)
            
            DispatchQueue.main.async {
                self.peripheral.updateValue(Data(chunk), for: self.char, onSubscribedCentrals: nil)
            }
        }
    }
    
    /// This function is used to handle write requests only coming to THIS device for XYO traffic.
    /// The function will automaticly manage the XyoInputStream handled under this manager, and will resume
    /// the readPromise if a new message has filled up.
    ///
    /// - Parameter request: The Gatt request to respond to
    /// - Parameter peripheral: The Gatt peripheral to call back to if sending notifactions.
    func handleWriteRequest(_ request: CBATTRequest, peripheral: CBPeripheralManager) {
        let value : [UInt8] = [UInt8](request.value ?? Data())
        
        inputStream.addChunk(packet: value)
        peripheral.respond(to: request, withResult: .success)
        
        let newPacket = inputStream.getOldestPacket()
        
        if (newPacket != nil) {
            readPromise.fulfill(newPacket)
        }
    }
    
    func getNetworkHuerestics() -> [XyoObjectStructure] {
        return []
    }
    
}

/// This protocal is a simple callback interface to listen in on the pipe.
protocol XyoGattServerLisitener {
    
    /// Call when the pipe should be closed and can be discarded.
    /// - Parameter device: The device of the pipe.
    func onClose (device : CBCentral)
}
