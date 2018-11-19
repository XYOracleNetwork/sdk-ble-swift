//
//  GenericServiceCharacteristicRegistry.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XyBleSdk

enum GenericServiceCharacteristicRegistry: String {
    case info = "Info"
    case alert = "Alert"
    case battery = "Battery"
    case time = "Time"
    case device = "Device"
    case gap = "GAP"
    case gatt = "GATT"
    case linkLoss = "LinkLoss"
    case tx = "Tx"

    var index: Int {
        return GenericServiceCharacteristicRegistry.values.index(of: self) ?? 0
    }

    static func fromIndex(_ index: Int) -> GenericServiceCharacteristicRegistry {
        return GenericServiceCharacteristicRegistry.values[safe: index] ?? .info
    }

    func characteristics(for deviceFamily: XYFinderDeviceFamily) -> [XYServiceCharacteristic] {
        switch self {
        case .info: return []
        case .alert:
            return [AlertNotificationService.controlPoint, AlertNotificationService.unreadAlertStatus, AlertNotificationService.newAlert,
                    AlertNotificationService.supportedNewAlertCategory, AlertNotificationService.supportedUnreadAlertCategory]
        case .battery:
            return [BatteryService.level]
        case .time:
            return [CurrentTimeService.currentTime, CurrentTimeService.localTimeInformation, CurrentTimeService.referenceTimeInformation]
        case .device:
            return [DeviceInformationService.systemId, DeviceInformationService.modelNumberString, DeviceInformationService.serialNumberString,
                    DeviceInformationService.firmwareRevisionString, DeviceInformationService.hardwareRevisionString, DeviceInformationService.softwareRevisionString,
                    DeviceInformationService.manufacturerNameString, DeviceInformationService.ieeeRegulatoryCertificationDataList, DeviceInformationService.pnpId]
        case .gap:
            return [GenericAccessService.deviceName, GenericAccessService.appearance, GenericAccessService.privacyFlag, GenericAccessService.reconnectionAddress,
                    GenericAccessService.peripheralPreferredConnectionParameters]
        case .gatt:
            return [GenericAttributeService.serviceChanged]
        case .linkLoss:
            return [LinkLossService.alertLevel]
        case .tx:
            return [TxPowerService.txPowerLevel]
        }
    }

    static let values = [info, alert, battery, time, device, gap, gatt, linkLoss, tx]
}
