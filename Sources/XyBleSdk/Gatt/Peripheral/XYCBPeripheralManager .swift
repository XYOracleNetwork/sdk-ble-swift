//
//  XYCBPeripheralManager .swift
//  XyBleSdk
//
//  Created by Carter Harrison on 2/18/19.
//

import Foundation
import CoreBluetooth
import CoreLocation
import Promises


open class XYCBPeripheralManager : NSObject, CBPeripheralManagerDelegate {
    private var services = [String : XYMutableService]()
    private var turnOnPromise : Promise<Bool>? = nil
    private var manager : CBPeripheralManager? = nil
    public static let instance = XYCBPeripheralManager()
    
    public func addService (service: XYMutableService) {
        services[service.cbService.uuid.uuidString] = service
        manager?.add(service.cbService)
    }
    
    public func removeService (service : XYMutableService) {
        guard let service = services[service.cbService.uuid.uuidString] else {
            return
        }
        
        manager?.remove(service.cbService)
        services.removeValue(forKey: service.cbService.uuid.uuidString)
    }
   
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        turnOnPromise?.fulfill(peripheral.state == .poweredOn)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard let service = services[request.characteristic.service?.uuid.uuidString ?? ""] else {
            return
        }
        
        service.handleReadRequest(request, peripheral: peripheral)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for i in 0...requests.count - 1 {
            guard let service = services[requests[i].characteristic.service?.uuid.uuidString ?? ""] else {
                return
            }
            
            service.handleWriteRequest(requests[i], peripheral: peripheral)
        }
    }

    public func turnOn () -> Promise<Bool> {
        manager = CBPeripheralManager(delegate: self, queue: XYCentral.centralQueue)
        let promise = Promise<Bool>.pending()
        turnOnPromise = promise
        return promise
    }
    
    public func turnOff () {
        manager?.stopAdvertising()
        manager = nil
    }

  @available(OSX 10.15, *)
  public func startAdvertiseing (advertisementUUIDs: [CBUUID]?, deviceName: String?, beacon : CLBeaconRegion?) {
        let peripheralData = beacon?.peripheralData(withMeasuredPower: nil)
        var adDataMap = ((peripheralData as? [String : Any]) ?? [String : Any]())

        adDataMap[CBAdvertisementDataServiceUUIDsKey] = advertisementUUIDs
        adDataMap[CBAdvertisementDataLocalNameKey] = deviceName
        self.manager?.startAdvertising(adDataMap)
    }
    
    public func stopAdvetrtising () {
        manager?.stopAdvertising()
    }
}
