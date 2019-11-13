
//
//  XyoIosXService.swift
//  sdk-xyobleinterface-swift
//
//  Created by Carter Harrison on 4/9/19.
//

import Foundation
import XyBleSdk
import CoreBluetooth

public enum XyoIosXService : XYServiceCharacteristic {
  case mutex
  case connect
  case status
  case scan
  case ip
  case ssid
  
  /// The display name of the service.
  public var serviceDisplayName: String {
    return "Primary"
  }
  
  public var serviceUuid: CBUUID {
    switch self {
    case .mutex:  return    CBUUID(string: "c9be9850-7a57-414a-b797-64c230d9ecb9")
    case .connect: return   CBUUID(string: "00010000-89BD-43C8-9231-40F6E305F96D")
    case .status: return    CBUUID(string: "00010000-89BD-43C8-9231-40F6E305F96D")
    case .scan: return      CBUUID(string: "00010000-89BD-43C8-9231-40F6E305F96D")
    case .ip: return        CBUUID(string: "00010000-89BD-43C8-9231-40F6E305F96D")
    case .ssid: return       CBUUID(string: "00010000-89BD-43C8-9231-40F6E305F96D")
    }
  }
  
  // 00010000-89BD-43C8-9231-40F6E305F96D
  
  public var characteristicUuid: CBUUID {
    switch self {
    case .mutex: return                  CBUUID(string: "e047295e-3df0-47cd-a841-be2d2a97dd21")
    case .connect: return                CBUUID(string: "00010001-89BD-43C8-9231-40F6E305F96D")
    case .status: return                 CBUUID(string: "00010030-89BD-43C8-9231-40F6E305F96D")
    case .scan: return                   CBUUID(string: "00010040-89BD-43C8-9231-40F6E305F96D")
    case .ip: return                     CBUUID(string: "00010020-89BD-43C8-9231-40F6E305F96D")
    case .ssid: return                   CBUUID(string: "00010010-89BD-43C8-9231-40F6E305F96D")
    }
  }
  
  public var characteristicType: XYServiceCharacteristicType { return XYServiceCharacteristicType.byte }
  
  public var displayName: String {
    switch self {
    case .mutex: return "Mutex"
    case .connect: return "Connect"
    case .status: return "Status"
    case .scan: return "Scan"
    case .ssid: return "Ssid"
    case .ip: return "Ip"
    }
  }
  
  public static var values: [XYServiceCharacteristic] = [ XyoIosXService.mutex ]
  
}

