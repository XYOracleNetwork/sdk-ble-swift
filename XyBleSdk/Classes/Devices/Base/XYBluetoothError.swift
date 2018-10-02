//
//  XYBluetoothError.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/24/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

// Common general errors from across the set of XY BLE classes/components
public enum XYBluetoothError: Error {
    case notConnected
    case mismatchedPeripheral
    case serviceNotFound
    case characteristicNotFound
    case dataNotPresent
    case timedOut
    case peripheralDisconected(state: CBPeripheralState?)
    case cbPeripheralDelegateError(Error)
    case actionNotSupported

    public var toString: String {
        switch self {
        case .notConnected:
            return "Not Connected"
        case .mismatchedPeripheral:
            return "Mismatched Peripheral"
        case .serviceNotFound:
            return "Service Not Found"
        case .characteristicNotFound:
            return "Characteristic Not Found"
        case .dataNotPresent:
            return "Data Not Present"
        case .timedOut:
            return "Timed Out"
        case .peripheralDisconected(let state):
            return "Peripheral Disconnected: \(state.debugDescription)"
        case .cbPeripheralDelegateError(let error):
            return "Peripheral Delegate Error: \(error)"
        case .actionNotSupported:
            return "Requested Action Not Supported"
        }
    }
}
