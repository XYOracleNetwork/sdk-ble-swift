//
//  XYBluetoothError.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/24/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum XYBluetoothError: Error {
    case notConnected
    case mismatchedPeripheral
    case serviceNotFound
    case characteristicNotFound
    case dataNotPresent
    case timedOut
    case peripheralDisconected(state: CBPeripheralState?)
    case cbPeripheralDelegateError(Error)
}
