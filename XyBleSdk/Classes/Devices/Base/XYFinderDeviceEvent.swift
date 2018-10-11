//
//  XYFinderDeviceEvent.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/11/18.
//

import Foundation

public enum XYFinderEvent {
    case connected
    case disconnected
    case buttonPressed // type
    case buttonRecentlyPressed // type
    case detected // power signal distance
    case exiting
    case exited
    case updated

    internal var index: Int {
        return XYFinderEvent.values.index(of: self)!
    }

    private static let values = [connected, disconnected, buttonPressed, buttonRecentlyPressed, detected, exiting, exited, updated]
}
