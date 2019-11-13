//
//  XyoSentinelXDevice.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 3/5/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import XyBleSdk
import CoreBluetooth

public class XyoSentinelXDevice : XyoDiffereniableDevice {
    private var lastButtonPressTime : Date? = nil
    
    
    public func isClaimed () -> Bool {
        guard let minor = self.iBeacon?.minor else {
            return true
        }
        
        let flags = XyoBuffer()
            .put(bits: minor)
            .getUInt8(offset: 1)
        
        return flags & 1 != 0
    }
    
    public func isButtonPressed () -> Bool {
        guard let minor = self.iBeacon?.minor else {
            return true
        }
        
        let flags = XyoBuffer()
            .put(bits: minor)
            .getUInt8(offset: 1)

        return flags & 2 != 0
    }
    
    private func isButtonPressTimeoutDone () -> Bool {
        guard let time = lastButtonPressTime else {
            return true
        }
        
        return time.timeIntervalSinceNow <= TimeInterval(exactly: -10)!
    }

    override public func getMtu() -> Int {
        return 22
    }

    public func cancelButtonPressTimer() {
        self.lastButtonPressTime = nil
    }
    
  public override func detected(_ rssi: Int) {
        if (isButtonPressed() && isButtonPressTimeoutDone()) {
            self.lastButtonPressTime = Date()
            XyoSentinelXManager.reportEvent(device: self, event: XyoSentinelXManager.Events.buttonpressed)
        }
    }

    public func reset (password: [UInt8]) -> Bool {
        let ecoded = XyoBuffer()
            .put(bits: UInt8(password.count + 2))
            .put(bits: UInt8(password.count + 1))
            .put(bytes: password)
            .toByteArray()
        
        let toSend = XYBluetoothResult(data: Data(ecoded))

        return self.set(XyoService.factoryReset, value: toSend).error == nil
    }
    
    /// This function changes the access password on the remove device
    /// - Warning: This function is blocking while it waits for bluetooth calls.
    /// - Parameter oldPassword: The old password of the device so that you can change the password.
    /// - Parameter newPassword: The new password to set if the oldPassword is correct.
    /// - Returns: If the changing of password was successfull
    public func changePassword (oldPassword: [UInt8], newPassword: [UInt8]) -> Bool {
        let encoded = XyoBuffer()
            .put(bits: UInt8(oldPassword.count + 1))
            .put(bytes: oldPassword)
            .put(bits: UInt8(newPassword.count + 1))
            .put(bytes: newPassword)
            .toByteArray()
        
        return chunkSend(bytes: encoded, characteristic: XyoService.password, sizeOfChunkSize: XyoObjectSize.ONE)
    }
    
    /// This function changes the the bound witness data on the remote device.
    /// - Warning: This function is blocking while it waits for bluetooth calls.
    /// - Parameter password: The password on the remote device so that you can change its bound witness data
    /// - Parameter boundWitnessData: The data to change on the remote device
    /// - Returns: If the changing of bound witness data was successfull
    public func changeBoundWitnessData (password: [UInt8], boundWitnessData: [UInt8]) -> Bool {
        let encoded = XyoBuffer()
            .put(bits: UInt8(password.count + 1))
            .put(bytes: password)
            .put(bits: UInt16(boundWitnessData.count + 1))
            .put(bytes: boundWitnessData)
            .toByteArray()
        
        return chunkSend(bytes: encoded, characteristic: XyoService.boundWitnessData, sizeOfChunkSize: XyoObjectSize.FOUR)
    }
    
    public func getBoundWitnessData () -> [UInt8]? {
        return self.get(XyoService.boundWitnessData).asByteArray
    }
    
    public func getPublicKey () -> [UInt8]? {
        return self.get(XyoService.publicKey).asByteArray
    }
}
