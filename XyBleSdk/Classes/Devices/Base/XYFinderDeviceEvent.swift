//
//  XYFinderDeviceEvent.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/11/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import Foundation

public enum XYFinderEvent: Int {
    case connected = 0
    case alreadyConnected
    case reconnected
    case disconnected
    case buttonPressed
    case detected
    case entered
    case exiting
    case exited
    case updated
}

public enum XYFinderEventNotification {
    case connected(device: XYFinderDevice)
    case alreadyConnected(device: XYFinderDevice)
    case reconnected(device: XYFinderDevice)
    case disconnected(device: XYFinderDevice)
    case buttonPressed(device: XYFinderDevice, type: XYButtonType2)
    case detected(device: XYFinderDevice, powerLevel: Int, signalStrength: Int, distance: Double)
    case entered(device: XYFinderDevice)
    case exiting(device: XYFinderDevice)
    case exited(device: XYFinderDevice)
    case updated(device: XYFinderDevice)

    // Silly but allows for readble conditionals based on the event's reporting device, as well
    // as simplified switch case statements
    public var device: XYFinderDevice {
        switch self {
        case .connected(let device): return device
        case .alreadyConnected(let device): return device
        case .reconnected(let device): return device
        case .disconnected(let device): return device
        case .buttonPressed(let device, _): return device
        case .detected(let device, _, _ , _): return device
        case .entered(let device): return device
        case .exiting(let device): return device
        case .exited(let device): return device
        case .updated(let device): return device
        }
    }

    // Used by the manager to lookup events from dictionary
    internal var toEvent: XYFinderEvent {
        switch self {
        case .connected: return .connected
        case .alreadyConnected: return .alreadyConnected
        case .reconnected: return .reconnected
        case .disconnected: return .disconnected
        case .buttonPressed: return .buttonPressed
        case .detected: return .detected
        case .entered: return .entered
        case .exiting: return .exiting
        case .exited: return .exited
        case .updated: return .updated
        }
    }
}
