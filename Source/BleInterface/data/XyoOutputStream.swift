//
//  XyoOutputStream.swift
//  mod-ble-swift
//
//  Created by Carter Harrison on 2/10/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Foundation

/// A simple struct to contain methods for outputing data over bluetooth
public struct XyoOutputStream {
    
    /// This function chunks data into a max chunk size, this used for cutting up packets over bluetooth.
    /// - Parameter bytes: The bytes to chunk up into the maxChunkSize
    /// - Parameter maxChunkSize: The max number of bytes per chunk
    /// - Returns: A collection of chunks made from the bytes.
    public static func chunk (bytes : [UInt8], maxChunkSize : Int) -> [[UInt8]] {
        var chunks = [[UInt8]]()
        var currentChunk = [UInt8]()
        
        for i in 0...bytes.count - 1 {
            currentChunk.append(bytes[i])
            
            if (currentChunk.count == maxChunkSize || i == bytes.count - 1) {
                chunks.append(currentChunk)
                currentChunk = [UInt8]()
            }
        }
        
        return chunks
    }
}
