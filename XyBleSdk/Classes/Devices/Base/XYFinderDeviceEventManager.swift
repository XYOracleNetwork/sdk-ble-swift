//
//  XYFinderDeviceEventManager.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/11/18.
//

import Foundation

public typealias XYFinderDeviceEventNotifier = (_ event: XYFinderEvent) -> Void

// TODO Make Threadsafe
public class XYFinderDeviceEventManager {

    fileprivate static var handlerRegistry = [Int: [(referenceKey: String, handler: XYFinderDeviceEventNotifier)]]()

    public static func report(event: XYFinderEvent) {
        handlerRegistry[event.index]?.forEach { key, handler in
            handler(event)
        }
    }

    public static func subscribe(to events: [XYFinderEvent], handler: @escaping XYFinderDeviceEventNotifier) -> String {
        let referenceKey = UUID.init().uuidString
        events.forEach { event in
            if handlerRegistry[event.index] == nil {
                handlerRegistry[event.index] = [(referenceKey, handler)]
            } else {
                handlerRegistry[event.index]?.append((referenceKey, handler))
            }
        }

        return referenceKey
    }

    public static func unsubscribe(to events: [XYFinderEvent], referenceKey: String) {
        events.forEach { event in
            let updatedArray = handlerRegistry[event.index]?.filter { $0.referenceKey != referenceKey }
            handlerRegistry[event.index] = updatedArray
        }
    }

}
