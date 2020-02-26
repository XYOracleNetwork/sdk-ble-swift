//
//  XYFinderDeviceEvent.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/11/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation

public enum XYFinderEvent: Int {
    case
    connected = 0,
    alreadyConnected,
    connectionError,
    reconnected,
    disconnected,
    buttonPressed,
    detected,
    entered,
    exiting,
    exited,
    updated,
    timedOut
}

public enum XYFinderTimeoutEvent: Int {
    case
    connection,
    getOperation,
    setOperation,
    notifyOperation
}

public enum XYFinderEventNotification {
    case connected(device: XYBluetoothDevice)
    case alreadyConnected(device: XYBluetoothDevice)
    case connectionError(device: XYBluetoothDevice, error: XYBluetoothError?)
    case reconnected(device: XYBluetoothDevice)
    case disconnected(device: XYBluetoothDevice)
    case buttonPressed(device: XYBluetoothDevice, type: XYButtonType2)
    case detected(device: XYBluetoothDevice, powerLevel: Int, rssi: Int, distance: Double)
    case entered(device: XYBluetoothDevice)
    case exiting(device: XYBluetoothDevice)
    case exited(device: XYBluetoothDevice)
    case updated(device: XYBluetoothDevice)
    case timedOut(device: XYBluetoothDevice, type: XYFinderTimeoutEvent)

    // Silly but allows for readble conditionals based on the event's reporting device, as well
    // as simplified switch case statements
    public var device: XYBluetoothDevice {
        switch self {
        case .connected(let device): return device
        case .alreadyConnected(let device): return device
        case .connectionError(let device, _): return device
        case .reconnected(let device): return device
        case .disconnected(let device): return device
        case .buttonPressed(let device, _): return device
        case .detected(let device, _, _ , _): return device
        case .entered(let device): return device
        case .exiting(let device): return device
        case .exited(let device): return device
        case .updated(let device): return device
        case .timedOut(let device, _): return device
        }
    }

    // Used by the manager to lookup events from dictionary
    internal var toEvent: XYFinderEvent {
        switch self {
        case .connected: return .connected
        case .alreadyConnected: return .alreadyConnected
        case .connectionError: return .connectionError
        case .reconnected: return .reconnected
        case .disconnected: return .disconnected
        case .buttonPressed: return .buttonPressed
        case .detected: return .detected
        case .entered: return .entered
        case .exiting: return .exiting
        case .exited: return .exited
        case .updated: return .updated
        case .timedOut: return .timedOut
        }
    }
}
