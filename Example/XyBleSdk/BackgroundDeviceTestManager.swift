//
//  BackgroundDeviceTestManager.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XyBleSdk

class FirmwareTester {

    class func loadFirmware() {
        // Get the first one
        guard
            let firmwareUrl = XYFirmwareLoader.locateLocalFirmware().first,
            let firmwareData = XYFirmwareLoader.getFirmwareData(from: firmwareUrl),
            let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.80.59060")
            else { return }

        let manager = XYFirmwareUpdateManager(for: device, parameters: XYFirmwareUpdateParameters.xy4, firmwareData: firmwareData)
        manager.update({

        }, failure: { error in

        })

    }

}

/*

import CoreBluetooth

class BackgroundDeviceTestManager {

    fileprivate var subUuid: UUID?
    fileprivate var device: XYFinderDevice?

    fileprivate let central = XYCentral.instance
    fileprivate let smartScan = XYSmartScan.instance

    init() {
        smartScan.setDelegate(self, key: "BackgroundDeviceTestManager")
        self.subUuid = XYFinderDeviceEventManager.subscribe(to: [.connected, .alreadyConnected, .buttonPressed, .reconnected]) { event in
            switch event {
            case .connected, .alreadyConnected:
                self.device = event.device
                print("CONNECTED event:\(event.device.id.shortId)...")
                self.connected()
            case .reconnected:
                print(" ----- Reconnected to device \(event.device.id) -------- ")
            case .buttonPressed(let device, _):
                print("Button pressed!!! ------------ \(device.id) ------------ ")
            default:
                break
            }
        }
    }

    func prep() {
        XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")?.connect()
//        XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.80.59060")?.connect()
//        XYFinderDeviceFactory.build(from: "xy:ibeacon:08885dd0-111b-11e4-9191-0800200c9a66.9275.50660")?.connect()
//        XYFinderDeviceFactory.build(from: "xy:ibeacon:08885dd0-111b-11e4-9191-0800200c9a66.9291.35700")?.connect()
    }

    func connected() {
        guard let device = self.device, device.state == .connected else { return }
        smartScan.start(for: device, mode: .foreground)
        device.connection {
            if device.unlock().hasError == false {
                device.stayAwake()
                let result = device.version()
                if result.hasError {
                    print("Error is \(result.error?.toString)")
                } else {
                    print("+++++++++++++++++++++++++++++++++++ Version is \(result.asString ?? "unkniown")")
                }
            }
        }.catch { error in
            print("error: \((error as! XYBluetoothError).toString)")
        }
    }

}

extension BackgroundDeviceTestManager: XYSmartScanDelegate {
    func smartScan(status: XYSmartScanStatus) {}
    func smartScan(location: XYLocationCoordinate2D) {
//        print("LOCATION")
    }
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
*/
