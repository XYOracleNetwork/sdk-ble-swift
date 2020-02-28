//
//  XYRepeatingTimer.swift
//  XyCoreiOS
//
//  Created by Darren Sutherland on 4/23/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//
//  Adapted from: https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
//

import Foundation

public class XYRepeatingTimer {

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended
    private let timeInterval: TimeInterval
    private var eventHandler: (() -> Void)?

    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    public init(timeInterval: TimeInterval, eventHandler: (() -> Void)?) {
        self.eventHandler = eventHandler
        self.timeInterval = timeInterval
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    public func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    public func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
