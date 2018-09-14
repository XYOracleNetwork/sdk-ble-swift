//
//  Dispatch+extensions.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import Foundation

public extension DispatchSource {

    public class func singleTimer(
        interval: DispatchTimeInterval,
        leeway: DispatchTimeInterval = .nanoseconds(0),
        queue: DispatchQueue, handler: @escaping () -> Void) -> DispatchSourceTimer {

        // Use the specified queue
        let result = DispatchSource.makeTimerSource(queue: queue)
        result.setEventHandler(handler: handler)

        // Unlike previous example, no specialized scheduleOneshot required
        result.schedule(deadline: DispatchTime.now() + interval, leeway: leeway)
        result.resume()
        return result
    }
}
