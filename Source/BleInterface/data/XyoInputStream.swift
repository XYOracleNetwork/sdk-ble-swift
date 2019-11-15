//
//  XyoInputStream.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/10/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation
import sdk_objectmodel_swift

/// This class manages an input stream where chunks of data are added, and they can be reconstructed
/// into their original packet.
public class XyoInputStream {
    /// All of the packets that have been completed [INDEX OF PACKET][BYTE]
    private var donePackets = [[UInt8]]()
    
    /// The next size of the next packet, this size included itself.
    private var nextWaitingSize : UInt32?
    
    /// The buffer of the current packet, this buffer will grow to the size nextWaitingSize, then will be added to donePackets.
    private var currentBuffer : XyoBuffer? = nil
    
    /// This function adds a chunk to largerpacket buffer, and will add to the donePackets if completed.
    public func addChunk (packet : [UInt8]) {
        if (currentBuffer == nil && nextWaitingSize == nil) {
            currentBuffer = XyoBuffer(data: packet)
        } else {
            currentBuffer?.put(bytes: packet)
        }
        
        checkSize()
        checkDone()
    }
    
    /// Gets the oldest packet in donePackets (all of the completed packets) and will remove it from donePackets
    /// after returned.
    /// - Returns: Will return the oldest packet in the queue, if none exists, will return nil
    public func getOldestPacket () -> [UInt8]? {
        if (donePackets.count > 0) {
            let returnValue = donePackets.first
            nextWaitingSize = nil
            currentBuffer = nil
            return returnValue
        }
        
        return nil
    }
    
    public func removePacket () {
        donePackets.removeFirst()
    }
    
    /// Sets the next waiting size in a safe maner.
    private func checkSize () {
        if (currentBuffer?.getSize() ?? 0 >= 4) {
            nextWaitingSize = currentBuffer?.getUInt32(offset: 0)
        }
    }
    
    /// Checks to see if the currentBuffer is ready to to be added to the donePackets queue.
    private func checkDone () {
        if (nextWaitingSize ?? 0 <= currentBuffer?.getSize() ?? 4) {
            let donePacket = currentBuffer?.copyRangeOf(from: 4, to: (Int(nextWaitingSize ?? 4))).toByteArray() ?? []
            donePackets.append(donePacket)
        }
    }
}
