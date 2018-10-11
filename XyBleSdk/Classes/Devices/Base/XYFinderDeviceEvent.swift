//
//  XYFinderDeviceEvent.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/11/18.
//

import Foundation

public enum XYFinderEvent: Int {
    case connected = 0
    case disconnected
    case buttonPressed
    case buttonRecentlyPressed
    case detected
    case exiting
    case exited
    case updated

//    var toString: String {
//        switch self {
//        case .connected: return "connected"
//        case .disconnected: return "disconnected"
//        case .buttonPressed: return "buttonPressed"
//        case .buttonRecentlyPressed: return "buttonRecentlyPressed"
//        case .detected: return "detected"
//        case .exiting: return "exiting"
//        case .exited: return "exited"
//        case .updated: return "updated"
//        }
//    }
}

public enum XYFinderEventNotification {
    case connected(device: XYFinderDevice)
    case disconnected(device: XYFinderDevice)
    case buttonPressed(device: XYFinderDevice) // type
    case buttonRecentlyPressed(device: XYFinderDevice) // type
    case detected(device: XYFinderDevice, powerLevel: Int, signalStrength: Int, distance: Double)
    case exiting(device: XYFinderDevice)
    case exited(device: XYFinderDevice)
    case updated(device: XYFinderDevice)

    var toEvent: XYFinderEvent {
        switch self {
        case .connected: return .connected
        case .disconnected: return .disconnected
        case .buttonPressed: return .buttonPressed
        case .buttonRecentlyPressed: return .buttonRecentlyPressed
        case .detected: return .detected
        case .exiting: return .exiting
        case .exited: return .exited
        case .updated: return .updated
        }
    }
}
