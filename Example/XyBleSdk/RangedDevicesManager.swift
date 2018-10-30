//
//  RangedDevicesManager.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import CoreBluetooth
import XyBleSdk

protocol RangedDevicesManagerDelegate: class {
    func reloadTableView()
    func showDetails()
    func buttonPressed(on device: XYFinderDevice)
}

class RangedDevicesManager: NSObject {

    fileprivate let central = XYCentral.instance
    fileprivate let scanner = XYSmartScan.instance

    fileprivate(set) var rangedDevices = [XYFinderDevice]()
    fileprivate(set) var selectedDevice: XYFinderDevice?

    fileprivate weak var delegate: RangedDevicesManagerDelegate?

    fileprivate(set) var subscriptionUuid: UUID?

    static let instance = RangedDevicesManager()

    private override init() {
        super.init()
        self.subscriptionUuid = XYFinderDeviceEventManager.subscribe(to: [.buttonPressed, .connected]) { event in
            switch event {
            case .buttonPressed(let device, _):
                guard let currentDevice = self.selectedDevice, currentDevice == device else { return }
                self.delegate?.buttonPressed(on: device)
            case .connected(let device):
                print("----- Connected to \(device.id)")
            default:
                break
            }
        }
    }

    func setDelegate(_ delegate: RangedDevicesManagerDelegate) {
        self.delegate = delegate
    }

    func startRanging() {
        if central.state != .poweredOn {
            central.setDelegate(self, key: "RangedDevicesManager")
            central.enable()
        } else {
            scanner.start(mode: .foreground)
        }
    }

    func stopRanging() {
        guard central.state == .poweredOn else { return }
        scanner.stop()
    }

func scan(for deviceIndex: NSInteger) {
        guard
            central.state == .poweredOn,
            let device = self.rangedDevices[safe: deviceIndex]
            else { return }

        self.selectedDevice = device
        print(self.selectedDevice?.id)
//        central.scan()
    }

    func disconnect() {
        guard let device = selectedDevice else { return }
        self.central.disconnect(from: device)
    }
}

extension RangedDevicesManager: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rangedDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rangedDeviceCell") as! RangedDeviceTableViewCell
        let device = rangedDevices[indexPath.row]

        let directive = RangedDeviceCellDirective(
            name:  device.family.familyName,
            major: device.iBeacon?.major ?? 0,
            rssi: device.rssi,
            uuid: device.uuid,
            connected: false,
            minor: device.iBeacon?.minor ?? 0,
            pulses: device.totalPulseCount)

        cell.populate(from: directive)
        cell.accessoryType = device.powerLevel == UInt(8) ? .checkmark : .none
        return cell
    }
}

extension RangedDevicesManager {

    func multiTest() {
        print("Starting MultiTest")

        // Build two devices from ids
        let blue = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
        let black = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.80.59060")

        blue?.connect()
//        black?.connect()
    }

}

extension RangedDevicesManager: XYCentralDelegate {
    func located(peripheral: XYPeripheral) {
        if self.selectedDevice?.attachPeripheral(peripheral) ?? false {
            central.stopScan()
            DispatchQueue.main.async {
                self.delegate?.showDetails()
            }
        }
    }

    func connected(peripheral: XYPeripheral) {}

    func timeout() {}

    func couldNotConnect(peripheral: XYPeripheral) {}

    func disconnected(periperhal: XYPeripheral) {}

    func stateChanged(newState: CBManagerState) {
        if newState == .poweredOn {
            self.scanner.start(mode: .foreground)
            self.scanner.setDelegate(self, key: "RangedDevicesManager")
        }
    }

}

extension RangedDevicesManager: XYSmartScanDelegate {
    func smartScan(status: XYSmartScanStatus) {}

    func smartScan(exiting device: XYBluetoothDevice) {}

    func smartScan(location: XYLocationCoordinate2D) {}

    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily) {}

    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily) {
        DispatchQueue.main.async {
            var rangedWithoutCurrent = self.rangedDevices.filter { $0.family != family }

            devices.forEach { device in
                // Only show those in range
                if device.rssi != 0 && device.rssi > -95 {
                    rangedWithoutCurrent.append(device)
                }
            }

            self.rangedDevices = rangedWithoutCurrent.sorted(by: { ($0.powerLevel, $0.rssi, $0.id) > ($1.powerLevel, $1.rssi, $1.id) } )
            self.delegate?.reloadTableView()
        }
    }

    func smartScan(entered device: XYFinderDevice) {}

    func smartScan(exited device: XYFinderDevice) {}
}
