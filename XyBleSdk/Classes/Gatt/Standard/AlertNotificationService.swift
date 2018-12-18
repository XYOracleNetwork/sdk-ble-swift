//
//  AlertNotificationService.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/14/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
//

import CoreBluetooth

public enum AlertNotificationService: String, XYServiceCharacteristic {

    public var serviceDisplayName: String { return "Alert Notification" }
    public var serviceUuid: CBUUID { return AlertNotificationService.serviceUuid }

    case controlPoint
    case unreadAlertStatus
    case newAlert
    case supportedNewAlertCategory
    case supportedUnreadAlertCategory

    public var characteristicUuid: CBUUID {
        return AlertNotificationService.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        switch self {
        case .controlPoint: return "Control Point"
        case .unreadAlertStatus: return "Unread Alert Status"
        case .newAlert: return "New Alert"
        case .supportedNewAlertCategory: return "Supported New Alert Category"
        case .supportedUnreadAlertCategory: return "Supported Unread Alert Category"
        }
    }

    private static let serviceUuid = CBUUID(string: "00001811-0000-1000-8000-00805F9B34FB")

    private static let uuids: [AlertNotificationService: CBUUID] = [
        controlPoint: CBUUID(string: "00002a44-0000-1000-8000-00805f9b34fb"),
        unreadAlertStatus: CBUUID(string: "00002a45-0000-1000-8000-00805f9b34fb"),
        newAlert: CBUUID(string: "00002a46-0000-1000-8000-00805f9b34fb"),
        supportedNewAlertCategory: CBUUID(string: "00002a47-0000-1000-8000-00805f9b34fb"),
        supportedUnreadAlertCategory: CBUUID(string: "00002a48-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        controlPoint, unreadAlertStatus, newAlert, supportedNewAlertCategory, supportedUnreadAlertCategory
    ]
}
