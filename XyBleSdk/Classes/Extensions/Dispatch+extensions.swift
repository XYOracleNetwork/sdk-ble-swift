//
//  Dispatch+extensions.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//
//  From: https://www.cocoawithlove.com/blog/2016/07/30/timer-problems.html#a-single-queue-synchronized-timer

import Foundation

internal extension DispatchSource {
    // Similar to before but the scheduling queue is passed as a parameter
    class func singleTimer(interval: DispatchTimeInterval, leeway:
        DispatchTimeInterval = .nanoseconds(0), queue: DispatchQueue, handler: @escaping ()
        -> Void) -> DispatchSourceTimer {
        // Use the specified queue
        let result = DispatchSource.makeTimerSource(queue: queue)
        result.setEventHandler(handler: handler)

        // Unlike previous example, no specialized scheduleOneshot required
        result.schedule(deadline: DispatchTime.now() + interval, leeway: leeway)
        result.resume()
        return result
    }
}
