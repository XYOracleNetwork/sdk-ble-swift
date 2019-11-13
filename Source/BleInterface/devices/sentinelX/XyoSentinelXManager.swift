//
//  XyoSentinelXEventManager.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 3/15/19.
//

import Foundation

public struct XyoSentinelXManager {
    private static var listeners : [String : (XyoSentinelXDevice, XyoSentinelXManager.Events) -> ()] = [:]
    
    public enum Events {
        case buttonpressed
    }
    
    public static func addListener (key: String, callback : @escaping (XyoSentinelXDevice, XyoSentinelXManager.Events) -> ()) {
        XyoSentinelXManager.listeners[key] = callback
    }
    
    public static func removeListener (key : String) {
        XyoSentinelXManager.listeners.removeValue(forKey: key)
    }
    
    static func reportEvent (device : XyoSentinelXDevice, event: XyoSentinelXManager.Events) {
        for callback in listeners.values {
            callback(device, event)
        }
    }
    
}

