//
//  XyoBluetoothDevice.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/10/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import Promises
import CoreBluetooth
import sdk_core_swift

/// A class that gets created with XYO pipe enabled devices arround the world. Each device complies to the
/// XyoNetworkPipe interface, meaning that data can be send and recived beetwen them. Please note that
/// one chould not use an instance of this class as a pipe, but tryCreatePipe() to get an instance of
/// a pipe.
open class XyoBluetoothDevice: XYBluetoothDeviceBase, XYBluetoothDeviceNotifyDelegate, XyoNetworkPipe {
  public func getNetworkHeuristics() -> [XyoObjectStructure] {
    return []
  }
  
    /// The defining family for a XyoBluetoothDevice, this helps the process of creatig a device, and making
    /// sure that it complies to the XYO pipe spec.
    public static let family = XYDeviceFamily.init(uuid: UUID(uuidString: XyoBluetoothDevice.uuid)!,
                                                   prefix: XyoBluetoothDevice.prefix,
                                                   familyName: XyoBluetoothDevice.familyName,
                                                   id: XyoBluetoothDevice.id)
    
    /// The ID of an XyoBluetoothDevice
    public static let id = "XYO"
    
    /// The primary service UUID of a XyoBluetoothDevice
    public static let uuid : String = XyoService.pipe.serviceUuid.uuidString
    
    /// The faimly name of a XyoBluetoothDevice
    public static let familyName : String = "XYO"
    
    /// The prefix of a XyoBluetoothDevice
    public static let prefix : String = "xy:ibeacon"
    
    /// The input stream of the device at the other end of the pipe.
    private var inputStream = XyoInputStream()
    
    /// The promise to wait when waiting for a new packed to be completed in the inputStream.
    private var recivePromise : Promise<[UInt8]?>? = nil
    
    /// Creates a new instance of XyoBluetoothDevice using an id and rssi.
    /// - Parameter id: The peripheral id of the device to create.
    /// - Parameter iBeacon: The IBeacon of the device.
    /// - Parameter rssi: The rssi of the device when scaned, will defualt to XYDeviceProximity.none.rawValue.
    public init(_ id: String, iBeacon: XYIBeaconDefinition? = nil, rssi: Int = XYDeviceProximity.none.rawValue) {
        super.init(id, rssi: rssi, family: XyoBluetoothDevice.family, iBeacon: iBeacon)
    }
    
    /// A convenience init that does not need an id.
    /// - Parameter iBeacon: The IBeacon of the device.
    /// - Parameter rssi: The rssi of the device when scaned, will defualt to XYDeviceProximity.none.rawValue.
    public convenience init(iBeacon: XYIBeaconDefinition, rssi: Int = XYDeviceProximity.none.rawValue) {
        self.init(iBeacon.xyId(from: XyoBluetoothDevice.family), iBeacon: iBeacon, rssi: rssi)
    }

    open func getMtu () -> Int {
        return peripheral?.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse) ?? 22
    }
    
    /// A function to try and create a pipe. This should be the function used to create a pipe, not using this instance
    /// as a pipe, even though it may work, it will not work consistsnatly.
    /// - Warning: This function is blocking while waiting to subscribe to the device, and this function should be called
    /// withen a connection block
    public func tryCreatePipe () -> XyoNetworkPipe? {
        /// make sure to clear the input stream for a new pipe
        self.inputStream = XyoInputStream()
        
        /// we use a unique name as the delegate key to prevent overriding keys
        let result = self.subscribe(to: XyoService.pipe, delegate: (key: "notify [DBG: \(#function)]: \(Unmanaged.passUnretained(self).toOpaque())", delegate: self))
        if (result.error == nil) {
            print("Created PIPE")
            return self
        }
        
        return nil
    }
    
    /// This function tries to attatch a XYPeripheral as the peripheral for this device model, this will work if the
    /// device has a XYO UUID in the advertisement
    /// - Parameter peripheral: The XYO pipe enabled peripheral to try and attatch
    /// - Returns: If the attatchment of the peripheral was sucessfull.
    override open func attachPeripheral(_ peripheral: XYPeripheral) -> Bool {
        guard
            self.peripheral == nil
            else { return false }
        
        if (checkForName(peripheral) || checkForXyoUuid(peripheral)) {
            // Set the peripheral and delegate to self
            self.peripheral = peripheral.peripheral
            self.peripheral?.delegate = self
            
            return true
        }
        
        return false
    }
    
    /// Checks to see if an advertisement contains the XYO service UUID
    /// - Parameter peripheral: The device to check for the XYO service UUID.
    /// - Returns: If the device is advertising the XYO service UUID.
    private func checkForXyoUuid (_ peripheral: XYPeripheral) -> Bool {
        guard
            let services = peripheral.advertisementData?[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
            else { return false }
        
        guard
            services.contains(CBUUID(string: XyoBluetoothDevice.uuid))
            else { return false }
        
        return true
    }
    
    /// Checks to see if an advertisement contains the major and minor of this iBeacon device in the name.
    /// - Parameter peripheral: The device to check for name.
    /// - Returns: If the device contains the proper name.
    private func checkForName (_ peripheral: XYPeripheral) -> Bool {
        guard
            let major = self.iBeacon?.major,
            let minor = self.iBeacon?.minor,
            let deviceName = peripheral.advertisementData?[CBAdvertisementDataLocalNameKey] as? String
            else {
                return false
        }
        
        let majorMinorName = XyoGattNameEncoder.encode(major: major, minor: minor)
        return deviceName == majorMinorName
    }
    
    /// Gets the first data that was sent to this device, since the client is allways the one initing, this will
    /// allways return nil
    /// - Returns: Returns the first data srecived through the pipe if not initing.
    public func getInitiationData() -> XyoAdvertisePacket? {
        // this is because we are allways a client
        return nil
    }
    
    /// Sends data to the peripheral and waits for a response if the waitForResponse flag is set.
    /// - Warning: This function is blocking while it waits for bluetooth calls.
    /// - Parameter data: The data to send to the other device at the end of the pipe
    /// - Parameter waitForResponse: Weather or not to wait for a response after sending
    /// - Returns: Will return the response from the other party, will return nil if there was an error or if
    /// waitForResponse was set to false.
    public func send(data: [UInt8], waitForResponse: Bool, completion: @escaping ([UInt8]?) -> ()) {
        print("SENDING: \(data.toHexString())")
        if (!chunkSend(bytes: data, characteristic: XyoService.pipe, sizeOfChunkSize: XyoObjectSize.FOUR)) {
            completion(nil)
            return
        }
        
        if (waitForResponse) {
            completion(waitForRead())
            return
        }
        
        completion(nil)
    }
    
    /// Sends data to the peripheral at the other end of the pipe, via the XYO pipe protocol.
    /// - Parameter bytes: The bytes to send to the other end of the pipe
    /// - Parameter characteristic: The charistic to chunk write to
    /// - Parameter sizeOfChunkSize: The number of bytes to prepend the size with when sening chunks
    /// - Warning: This function is blocking while it waits for bluetooth calls.
    /// - Returns: This function returns the success of the chunk send
    func chunkSend (bytes : [UInt8], characteristic: XYServiceCharacteristic, sizeOfChunkSize: XyoObjectSize) -> Bool {
        let sizeEncodedBytes = XyoBuffer()
        
        switch sizeOfChunkSize {
        case .ONE: sizeEncodedBytes.put(bits: UInt8(bytes.count + 1))
        case .TWO: sizeEncodedBytes.put(bits: UInt16(bytes.count + 2))
        case.FOUR: sizeEncodedBytes.put(bits: UInt32(bytes.count + 4))
        case.EIGHT: sizeEncodedBytes.put(bits: UInt64(bytes.count + 8))
        }
        
        sizeEncodedBytes.put(bytes: bytes)

        let chunks = XyoOutputStream.chunk(bytes: sizeEncodedBytes.toByteArray(), maxChunkSize: getMtu() - 3)
        
        for chunk in chunks {
            print("SENDING CHUNK \(chunk.toHexString())")
            let status = self.set(characteristic, value: XYBluetoothResult(data: Data(chunk)), withResponse: true)
            
            print("DONE SENDING CHUNK")
            
            // break the loop if there was an error
            if (status.error != nil) {
                return false
            }
        }
        
        return true
    }
    
    /// Waits for the next read request to come in, if one has allready come in before calling this function,
    /// it will return it.
    /// - Warning: This function is blocking while it waits for bluetooth calls.
    /// - Returns: This function returns what the divice on the other end of the pipe just sent.
    private func waitForRead () -> [UInt8]? {
        print("WAITING FOR READ")
        var latestPacket : [UInt8]? = inputStream.getOldestPacket()
        if (latestPacket == nil) {
            recivePromise = Promise<[UInt8]?>.pending().timeout(20)
            do {
                latestPacket = try await(recivePromise.unsafelyUnwrapped)
            } catch {
                print("TIMEOUT")
                // timeout has occored
                return nil
            }
        }
        
        inputStream.removePacket()
        
        print("READ ENTIRE \(latestPacket?.toHexString() ?? "--")")
        return latestPacket
    }
    
    /// This function terminates the bluetooth connection and should be called beetwen creating pipes.
    public func close() {
        disconnect()
    }
    
    public func getNetworkHuerestics() -> [XyoObjectStructure] {
        var toReturn = [XyoObjectStructure]()

        let pwr = self.iBeacon?.powerLevel

        if pwr != nil {
            let pwrTag = XyoObjectStructure.newInstance(schema: XyoSchemas.BLE_POWER_LEVEL, bytes: XyoBuffer().put(bits: pwr!))
            toReturn.append(pwrTag)
        }

        let unsignedRssi = UInt8(bitPattern: Int8(self.rssi))
        let rssiTag = XyoObjectStructure.newInstance(schema: XyoSchemas.RSSI, bytes: XyoBuffer().put(bits: (unsignedRssi)))

        toReturn.append(rssiTag)

        return toReturn
    }
    
    /// This function is called whenever a charisteristic is updated, and is how the XYO pipe recives data.
    /// This function will also add to the input stream, and resume a read promise if there is one existing.
    /// - Parameter serviceCharacteristic: The characteristic that is being updated, this should be the XYO serivce
    /// - Parameter value: The value that characteristic has been changed to (or notifyed of)
    public func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        if (!value.hasError && value.asByteArray != nil) {
            print("GOT NOTIFACTION \(value.asByteArray!.toHexString())")
            inputStream.addChunk(packet: value.asByteArray!)
            
            guard let donePacket = inputStream.getOldestPacket() else {
                return
            }
            
            recivePromise?.fulfill(donePacket)
        }
    }
}

