//
//  XYFinderDeviceEventManager.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 10/11/18.
//

import Foundation

public typealias XYFinderDeviceEventNotifier = (_ event: XYFinderEventNotification) -> Void

internal struct XYFinderDeviceEventDirective {
    let
    referenceKey: UUID = UUID.init(),
    handler: XYFinderDeviceEventNotifier,
    device: XYFinderDevice?
}

// TODO Make Threadsafe
public class XYFinderDeviceEventManager {

    fileprivate static var handlerRegistry = [XYFinderEvent: [XYFinderDeviceEventDirective]]()

    // Notify those directives that want all events and those that subscribe to the event's device
    public static func report(events: [XYFinderEventNotification]) {
        events.forEach { event in
            handlerRegistry[event.toEvent]?
                .filter { $0.device == nil || $0.device?.id == event.device.id }
                .forEach { $0.handler(event) }
        }
    }

    // Equivalent to subscribing to every device's events
    public static func subscribe(to events: [XYFinderEvent], handler: @escaping XYFinderDeviceEventNotifier) -> UUID {
        return subscribe(to: events, for: nil, handler: handler)
    }

    // Subscribe to a single device's events. This will simply filter when it comes to reporting to the handlers
    public static func subscribe(to events: [XYFinderEvent], for device: XYFinderDevice?, handler: @escaping XYFinderDeviceEventNotifier) -> UUID {
        let directive = XYFinderDeviceEventDirective(handler: handler, device: device)
        events.forEach { event in
            handlerRegistry[event] == nil ?
                handlerRegistry[event] = [directive] :
                handlerRegistry[event]?.append(directive)
        }

        return directive.referenceKey
    }

    public static func unsubscribe(to events: [XYFinderEvent], referenceKey: UUID?) {
        guard let key = referenceKey else { return }
        events.forEach { event in
            let updatedArray = handlerRegistry[event]?.filter { $0.referenceKey != key }
            handlerRegistry[event] = updatedArray
        }
    }

}
