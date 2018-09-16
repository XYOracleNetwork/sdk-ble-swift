//
//  ViewController.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import UIKit
import CoreBluetooth
import PromiseKit

class ViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!

    fileprivate let scanner = XYSmartScan.instance
    fileprivate var connect: BLEConnect?
    fileprivate var xy4Device: XYBluetoothDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.spinner.stopAnimating()
        xy4Device = XYFinderDeviceFactory.build(from:
            XYIBeaconDefinition(
                uuid: UUID(uuidString: "a44eacf4-0104-0000-0000-5f784c9977b5")!,
                major: UInt16(80),
                minor: UInt16(59060))
        )
    }

    @IBAction func connectTapped(_ sender: Any) {
        guard let myDevice = xy4Device else { return }
        self.spinner.startAnimating()
        connect = BLEConnect(device: myDevice, delegate: self)
    }

    @IBAction func disconnectTapped(_ sender: Any) {
        connect?.disconnect()
    }

    @IBAction func writeTapped(_ sender: Any) {
//        guard let device = xy4Device else { return }
//
//        self.spinner.startAnimating()
//        let buzzData = Data([UInt8(0x0b), 0x03])
//        device.write(to: PrimaryService.buzzer, value: XYBluetoothValue(PrimaryService.buzzer, data: buzzData)) { _ in
//            self.spinner.stopAnimating()
//        }
    }

    @IBAction func actionTapped(_ sender: Any) {
        guard let device = xy4Device else { return }

        let buzzData = Data([UInt8(0x0b), 0x03])
        
        let calls: Set<SerivceCharacteristicDirective> = [
            DeviceInformationService.firmwareRevisionString.read,
            DeviceInformationService.manufacturerNameString.read,
            BatteryService.level.read,
            PrimaryService.buzzer.write(XYBluetoothValue(PrimaryService.buzzer, data: buzzData))
        ]

        self.spinner.startAnimating()
        device.connectAndProcess(for: calls, complete: self.processResult)
    }

    func processResult(_ results: [XYBluetoothValue]) -> Void {
        self.spinner.stopAnimating()
        results.forEach { result in
            switch result.type {
            case .string: print(result.asString ?? "?")
            case .integer: print(result.asInteger ?? "?")
            default: print("?")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
//        scanner.start()
//        guard let myDevice = xy4Device else { return }
//        scanner.startTracking(for: myDevice)
    }

    override func viewDidDisappear(_ animated: Bool) {
        connect?.stop()
    }
}

extension ViewController: BLELocateDelegate {
    func connected(peripheral: BLEPeripheral) {
        spinner.stopAnimating()
    }

    func located(peripheral: BLEPeripheral) {
        print(peripheral.peripheral.name ?? "don't know")
    }

    func ableToConnect() {}
}
