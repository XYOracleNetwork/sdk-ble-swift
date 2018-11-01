//
//  BackgroundDeviceTestManager.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XyBleSdk
import CoreBluetooth

class BackgroundDeviceTestManager {

    fileprivate var subUuid: UUID?
    fileprivate var device: XYFinderDevice?

    fileprivate let central = XYCentral.instance
    fileprivate let smartScan = XYSmartScan.instance

    init() {
        smartScan.setDelegate(self, key: "BackgroundDeviceTestManager")
        self.subUuid = XYFinderDeviceEventManager.subscribe(to: [.connected, .alreadyConnected]) { event in
            switch event {
            case .connected, .alreadyConnected:
                self.device = event.device
                self.connected()
            default:
                break
            }
        }
    }

    func prep() {
        XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")?.connect()
    }

    func connected() {
        guard let device = self.device, device.state == .connected else { return }
        smartScan.start(for: device, mode: .foreground)
        device.connection {
            if device.unlock().hasError == false {
                let result = device.find(.findIt)
                if result.hasError {
                    print("Error is \(result.error?.toString)")
                }
            }
        }.catch { error in
            print("error: \((error as! XYBluetoothError).toString)")
        }
    }

}

extension BackgroundDeviceTestManager: XYSmartScanDelegate {
    func smartScan(status: XYSmartScanStatus) {}
    func smartScan(location: XYLocationCoordinate2D) {}
    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily) {
        guard let device = self.device else { return }
//        print("poopasdasD")
    }
    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily) {}
    func smartScan(entered device: XYFinderDevice) {
        guard let device = self.device else { return }
        print("--- ENTERED")
    }
    func smartScan(exiting device: XYBluetoothDevice) {}
    func smartScan(exited device: XYFinderDevice) {
        guard let device = self.device else { return }
        print("--- EXITED")
    }
}
