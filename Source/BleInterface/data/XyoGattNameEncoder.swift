//
//  XyoGattNameEncoder.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/22/19.
//

import Foundation

/// A simple struct to encode major and minor values into a string
struct XyoGattNameEncoder {
    
    /// Encodes the major and minor value into a base64 string.
    /// - Parameter major: The major to encode into the string.
    /// - Parameter minor: The minor to encode into the string.
    /// - Returns: Returns a Base64 string of the major and minor.
    static func encode (major : UInt16, minor: UInt16) -> String {
        let buffer = XyoBuffer()
            .put(bits: major)
            .put(bits: minor)
            .toByteArray()
        
        return Data(buffer).base64EncodedString()
    }
}
