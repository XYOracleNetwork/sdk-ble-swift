//
//  GattDescriptors.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/6/18.
//

import CoreBluetooth

// A descriptor for a service, used as the key value for a dictionary in GattDeviceDescriptor
public class GattServiceDescriptor: Hashable {
  public let
  uuid: CBUUID,
  name: String?
  
  init(_ service: CBService) {
    self.uuid = service.uuid
    self.name = GattDeviceDescriptor.definedServices.first(where: {$0.serviceUuid == service.uuid })?.serviceDisplayName
  }
  
  public func hash(into: inout Hasher) {
    return uuid.uuidString.hash(into: &into)
  }
  
  public static func == (lhs: GattServiceDescriptor, rhs: GattServiceDescriptor) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}

// A descriptor for a characteristic, holding the service enum, pointer to the parent and the properties
public struct GattCharacteristicDescriptor  {
  public let
  uuid: CBUUID,
  parent: GattServiceDescriptor,
  properties: CBCharacteristicProperties,
  service: XYServiceCharacteristic?
  
  init(_ characteristic: CBCharacteristic, service: GattServiceDescriptor) {
    self.uuid = characteristic.uuid
    self.parent = service
    self.properties = characteristic.properties
    self.service = GattDeviceDescriptor.definedServices.first(where: {$0.characteristicUuid == characteristic.uuid})
  }
}

// The dictionary container for all the services and respective characteristics that a device advertises
public struct GattDeviceDescriptor {
  
  public let serviceCharacteristics: [GattServiceDescriptor: [GattCharacteristicDescriptor]]
  
  init(_ characteristics: [CBCharacteristic]) {
    let services = characteristics.map { GattServiceDescriptor($0.service) }
    
    self.serviceCharacteristics = characteristics.reduce(into: [GattServiceDescriptor: [GattCharacteristicDescriptor]](), { initial, characteristic in
      let service = services.first(where: { service in service.uuid == characteristic.service.uuid })!
      let descriptor = GattCharacteristicDescriptor(characteristic, service: service)
      return initial[service] == nil ? initial[service] = [descriptor] : initial[service]!.append(descriptor)
    })
  }
  
  public var services: [GattServiceDescriptor] {
    return Array(self.serviceCharacteristics.keys)
  }
  
  // Array of all known services for easy building of the device descriptor
  internal static let definedServices: [XYServiceCharacteristic] =
    AlertNotificationService.values +
      BatteryService.values +
      CurrentTimeService.values +
      DeviceInformationService.values +
      GenericAccessService.values +
      GenericAttributeService.values +
      LinkLossService.values +
      OtaService.values +
      TxPowerService.values +
      BasicConfigService.values +
      ControlService.values +
      ExtendedConfigService.values +
      ExtendedControlService.values +
      XYFinderPrimaryService.values
}
