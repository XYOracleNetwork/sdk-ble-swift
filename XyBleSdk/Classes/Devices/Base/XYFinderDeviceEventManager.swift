//
//  XYFinderDeviceEventManager.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/11/18.
//

import Foundation

public typealias XYFinderDeviceEventNotifier = (_ event: XYFinderEventNotification) -> Void

// TODO Make Threadsafe
public class XYFinderDeviceEventManager {

    fileprivate static var handlerRegistry = [XYFinderEvent: [(referenceKey: String, handler: XYFinderDeviceEventNotifier)]]()

    public static func report(events: [XYFinderEventNotification]) {
        events.forEach { event in
            handlerRegistry[event.toEvent]?.forEach { $0.handler(event) }
        }
    }

    public static func subscribe(to events: [XYFinderEvent], handler: @escaping XYFinderDeviceEventNotifier) -> String {
        let referenceKey = UUID.init().uuidString
        events.forEach { event in
            if handlerRegistry[event] == nil {
                handlerRegistry[event] = [(referenceKey, handler)]
            } else {
                handlerRegistry[event]?.append((referenceKey, handler))
            }
        }

        return referenceKey
    }

    public static func unsubscribe(to events: [XYFinderEvent], referenceKey: String?) {
        guard let key = referenceKey else { return }
        events.forEach { event in
            let updatedArray = handlerRegistry[event]?.filter { $0.referenceKey != key }
            handlerRegistry[event] = updatedArray
        }
    }

}
