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
}

class RangedDevicesManager: NSObject {

    fileprivate let central = XYCentral.instance
    fileprivate let scanner = XYSmartScan2.instance

    fileprivate(set) var rangedDevices = [XYFinderDevice]()
    fileprivate(set) var selectedDevice: XYFinderDevice?

    fileprivate weak var delegate: RangedDevicesManagerDelegate?

    static let instance = RangedDevicesManager()

    private override init() {
        super.init()
    }

    func setDelegate(_ delegate: RangedDevicesManagerDelegate) {
        self.delegate = delegate
    }

    func startRanging() {
        if central.state != .poweredOn {
            central.setDelegate(self, key: "RangedDevicesManager")
            central.enable()
        } else {
            scanner.start(for: [.xy3], mode: .foreground)
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
        central.scan()
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
            self.scanner.start(for: [.xy3], mode: .foreground)
            self.scanner.setDelegate(self, key: "RangedDevicesManager")
        }
    }

}

extension RangedDevicesManager: XYSmartScan2Delegate {
    func smartScan(status: XYSmartScanStatus2) {}

    func smartScan(exiting device: XYBluetoothDevice) {}

    func smartScan(location: XYLocationCoordinate2D2) {}

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
