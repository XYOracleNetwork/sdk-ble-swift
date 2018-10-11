//
//  XYFinderEvent.swift
//  Bolts
//
//  Created by Darren Sutherland on 10/10/18.
//

import Foundation

public enum XYFinderEvent {
    case connected
    case disconnected
    case buttonPressed
    case buttonRecentlyPressed // type:XYButtonType
    case detected // powerLevel:Int, signalStrength:Int, distance: Double
    case entered
    case exiting
    case exited
    case updated
}
