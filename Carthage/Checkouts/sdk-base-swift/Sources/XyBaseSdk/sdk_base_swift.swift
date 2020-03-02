//
//  XYObject.swift
//  Xy
//
//  Created by Arie Trouw on 11/6/16.
//  Copyright © 2016 XY - The Findables Company. All rights reserved.
//

import Foundation

public class XYDateFormatter: DateFormatter {

    public class func sharedFormatter() -> DateFormatter {
        // current thread's hash
        let threadHash = Thread.current.hash
        // check if a date formatter has already been created for this thread
        if let existingFormatter = Thread.current.threadDictionary[threadHash] as? DateFormatter {
            // a date formatter has already been created, return that
            return existingFormatter
        } else {
            // otherwise, create a new date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSSS"
            // and store it in the threadDictionary (so that we can access it later on in the current thread)
            Thread.current.threadDictionary[threadHash] = dateFormatter
            return dateFormatter

        }

    }
}

open class XYBase: NSObject {

    open class func dump() -> [String: Any] {
        var dump = [String: Any]()
        dump["infoLoggingEnabled"] = infoLoggingEnabled
        dump["errorLoggingEnabled"] = errorLoggingEnabled
        dump["haltOnError"] = haltOnError
        dump["reportStatus"] = reportStatus
        return dump
    }

    open func dump() -> [String: Any] {
        var dump = [String: Any]()
        dump["Static"] = XYBase.dump()
        return dump
    }
    #if DEBUG
    internal static var extremeLoggingEnabled = false
    internal static var infoLoggingEnabled = true
    internal static var errorLoggingEnabled = true
    #else
    internal static var extremeLoggingEnabled = false
    internal static var infoLoggingEnabled = false
    internal static var errorLoggingEnabled = false
    #endif

    internal static var haltOnError = false

    internal static var logExtremeAttemptCount = 0
    internal static var logExtremeExecuteCount = 0
    internal static var logInfoAttemptCount = 0
    internal static var logInfoExecuteCount = 0
    internal static var logErrorAttemptCount = 0
    internal static var logErrorExecuteCount = 0
    internal static var reportStatus = [String]()

    internal static func now() -> String {
        return XYDateFormatter.sharedFormatter().string(from: Date())
    }

    open class func enableExtremeLogging(_ enable: Bool) {
        extremeLoggingEnabled = enable
    }

    public typealias ExternalLoggingClosure = (_ prefix: String, _ object: Any?, _ module: String, _ function: String, _ message: String, _ data: Data?) -> Void

    internal static var externalLoggingClosure: ExternalLoggingClosure?

    open class func setExternalLogging(closure: @escaping ExternalLoggingClosure) {
        externalLoggingClosure = closure
    }

    open func verifyMainThreadAsync(closure : @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            //logInfo(module: #file, function: #function, message: "verifyMainThreadAsync: Dispatching to Main Thread!");
            DispatchQueue.main.async(execute: closure)
        }
    }

    public static func verifyMainThreadAsync(closure : @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            //logInfo(nil, module: #file, function: #function, message: "verifyMainThreadAsync: Dispatching to Main Thread!");
            DispatchQueue.main.async(execute: closure)
        }
    }

    public static func log(_ prefix: String, object: Any?, module: String, function: String, message: String) {
        print("\(now()) \(prefix):\((module as NSString).lastPathComponent):\(String(describing: object)):\(function):\(message)")
    }

    public static func logInfo(_ object: Any?, module: String, function: String, message: String) {
        logInfoAttemptCount+=1
        if infoLoggingEnabled {
            logInfoExecuteCount+=1
            log("XY-Info", object: object, module: module, function: function, message: message)
        }
    }

    public static func logInfo(module: String, function: String, message: String) {
        logInfo(nil, module: module, function: function, message: message)
    }

    open func logInfo(module: String, function: String, message: String) {
        XYBase.logInfo(self, module: module, function: function, message: message)
    }

    public static func logExtreme(_ object: Any?, module: String, function: String, message: String) {
        logExtremeAttemptCount+=1
        if extremeLoggingEnabled {
            logExtremeExecuteCount+=1
            log("XY-Extreme", object: object, module: module, function: function, message: message)
        }
    }

    public static func logExtreme(module: String, function: String, message: String) {
        logExtreme(nil, module: module, function: function, message: message)
    }

    open func logExtreme(module: String, function: String, message: String) {
        XYBase.logExtreme(self, module: module, function: function, message: message)
    }

    public static func logException(_ object: Any?, module: String, function: String, exception: exception) {
        externalLoggingClosure?("XY-Exception", object, module, function, String(describing: exception), nil)
    }

    public static func logError(_ object: Any? = nil, module: String, function: String, message: String, data: Any? = nil, halt: Bool? = nil) {
        logErrorAttemptCount+=1
        if errorLoggingEnabled {
            logErrorExecuteCount+=1
        }
        externalLoggingClosure?("XY-Error", object, module, function, message, nil)
        log("XY-Error", object: object, module: module, function: function, message: message)
        if halt != nil {
            if halt! {
                fatalError()
            }
        } else if haltOnError {
            fatalError()
        }
    }

    public static func logError(_ object: Any? = nil, module: String, function: String, message: String, halt: Bool?) {
        logError(object, module: module, function: function, message: message, data: nil, halt: halt)
    }

    public static func logError(module: String, function: String, message: String, halt: Bool? = nil) {
        logError(nil, module: module, function: function, message: message, data: nil, halt: halt)
    }

    open func logError(module: String, function: String, message: String, data: Any? = nil, halt: Bool? = nil) {
        XYBase.logError(self, module: module, function: function, message: message, data: data, halt: halt)
    }

    open func logError(module: String, function: String, message: String, data: Any?) {
        XYBase.logError(self, module: module, function: function, message: message, data: data)
    }

    open class func reportStatus(_ status: String) {
        reportStatus.append(status)
        print("XY-Status:\(status)")
    }

    open func reportStatus(_ status: String) {
        XYBase.reportStatus(status)
    }
}

