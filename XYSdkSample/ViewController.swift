//
//  ViewController.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import UIKit
import CoreBluetooth
import Promises

class ViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var notifyLabel: UILabel!
    @IBOutlet weak var deviceStatus: UILabel!

    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var notifyButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!

    fileprivate let scanner = XYSmartScan.instance
    fileprivate var central = XYCentral.instance

    @IBOutlet weak var rangedDevicesTableView: UITableView!
    @IBOutlet weak var connectedDevicesTableView: UITableView!

    fileprivate var rangedDevices = [XYFinderDevice]()
    fileprivate var connectedDevices = [XYFinderDevice]()
    fileprivate var selectedDevice: XYFinderDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.spinner.stopAnimating()
        self.notifyLabel.alpha = 0.0

        rangedDevicesTableView.tag = 1
        rangedDevicesTableView.dataSource = self
        rangedDevicesTableView.delegate = self
        rangedDevicesTableView.layer.borderWidth = 1.0
        rangedDevicesTableView.layer.borderColor = UIColor.blue.cgColor

        connectedDevicesTableView.tag = 2
        connectedDevicesTableView.dataSource = self
        connectedDevicesTableView.delegate = self
        connectedDevicesTableView.layer.borderWidth = 1.0
        connectedDevicesTableView.layer.borderColor = UIColor.orange.cgColor
    }

    @IBAction func centralSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            if central.state != .poweredOn {
                self.spinner.startAnimating()
                central.setDelegate(self, key: "ViewController")
                central.enable()
            } else {
                scanner.start()
            }
        } else {
            scanner.stop()
            rangedDevices.removeAll()
            self.countLabel.text = nil
            rangedDevicesTableView.reloadData()
        }
    }

    @IBAction func notifyTapped(_ sender: Any) {
        guard let device = self.selectedDevice else { return }
        device.subscribe(to: PrimaryService.buttonState, delegate: ("ViewController-\(device.id)", self))
    }
    
    @IBAction func disconnectTapped(_ sender: Any) {
        guard let device = self.selectedDevice else { return }
        device.disconnect()
    }

    @IBAction func actionTapped(_ sender: Any) {
        guard let device = self.selectedDevice else { return }
        self.spinner.startAnimating()

        var level, revision, model: XYBluetoothResult?

        var values = [CBUUID: XYBluetoothResult]()
        let request = device.connection {
            level = device.get(BatteryService.level)
            revision = device.get(DeviceInformationService.firmwareRevisionString)
            model = device.get(DeviceInformationService.modelNumberString)
//            device.set(PrimaryService.buzzer, value: XYBluetoothResult(Data([UInt8(0x0b), 0x03])))
        }

        request.then { _ in
            values[BatteryService.level.characteristicUuid] = level
            values[DeviceInformationService.firmwareRevisionString.characteristicUuid] = revision
            values[DeviceInformationService.modelNumberString.characteristicUuid] = model

            self.processResult(values)
        }
    }

    func processResult(_ results: [CBUUID: XYBluetoothResult]) -> Void {
        self.spinner.stopAnimating()

        let modalViewController = ActionResultViewController()
        modalViewController.set(results: results)
        modalViewController.modalPresentationStyle = .overCurrentContext
        present(modalViewController, animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
//        guard let myDevice = xy4Device else { return }
//        scanner.startTracking(for: myDevice)
    }
}

extension ViewController: XYBluetoothDeviceNotifyDelegate {
    func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        DispatchQueue.main.async {
            self.notifyLabel.alpha = 1.0
            UIView.animate(withDuration: 2.0) {
                self.notifyLabel.alpha = 0.0
            }
        }
    }
}

extension ViewController: XYSmartScanDelegate {
    func smartScan(location: XYLocationCoordinate2D) {

    }

    func smartScan(entered device: XYFinderDevice) {

    }

    func smartScan(exited device: XYFinderDevice) {

    }

    func smartScan(detected devices: [XYFinderDevice]) {
        // TODO throttle this display a bit?
        DispatchQueue.main.async {
            self.rangedDevices.removeAll()
            var filteredDevices = [XYFinderDevice]()

            devices.forEach { device in
                // Only show those in range
                if device.rssi != 0 && device.rssi > -95 {
                    filteredDevices.append(device)
                }
            }

            self.rangedDevices = filteredDevices.sorted(by: { ($0.powerLevel, $0.id) > ($1.powerLevel, $1.id) } )
            self.countLabel.text = "\(self.rangedDevices.count)"
            self.rangedDevicesTableView.reloadData()
        }
    }

    func smartScan(detected device: XYFinderDevice, signalStrength: Int) {}
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            return rangedDevices.count
        } else {
            return connectedDevices.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rangedDevicesCell")!
            let device = rangedDevices[indexPath.row]
            cell.textLabel?.text = "\(device.iBeacon?.major ?? 0) + \(device.iBeacon?.minor ?? 0)"
            cell.accessoryType = device.powerLevel == UInt(8) ? .checkmark : .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "connectedDeviceCell")!
            let device = connectedDevices[indexPath.row]
            cell.textLabel?.text = "\(device.iBeacon?.major ?? 0) + \(device.iBeacon?.minor ?? 0)"
            let coreDevice = connectedDevices[indexPath.row]
            cell.detailTextLabel?.text = "\(coreDevice.peripheral?.identifier.uuidString ?? "Unknown ID")"
            return cell
        }
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 1 {
            guard
                central.state == .poweredOn,
                let device = self.rangedDevices[safe: indexPath.row]
                else { return }

            deviceStatus.text = "Scanning..."
            self.spinner.startAnimating()

            self.selectedDevice = device
            central.scan() // TOOD add timeout
        } else {
            if let device = self.connectedDevices[safe: indexPath.row] {
                self.selectedDevice = device
                print(device.id)
            }
        }
    }

}

extension ViewController: XYCentralDelegate {
    func timeout() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.statusLabel.text = "Central timeout"
        }
    }

    func couldNotConnect(peripheral: XYPeripheral) {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.deviceStatus.text = "Could not connect"
        }
    }

    func stateChanged(newState: CBManagerState) {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.statusLabel.text = newState.toString
            if newState == .poweredOn {
                self.scanner.start()
                self.scanner.setDelegate(self, key: "ViewController")
            }
        }
    }

    func connected(peripheral: XYPeripheral) {
        DispatchQueue.main.async {
            self.connectedDevices.append(self.selectedDevice!)
            self.selectedDevice = nil
            self.connectedDevicesTableView.reloadData()
            self.spinner.stopAnimating()
            self.deviceStatus.text = "Connected"
        }
    }

    func located(peripheral: XYPeripheral) {
        if self.selectedDevice?.attachPeripheral(peripheral) ?? false {
            central.stop()
            central.connect(to: self.selectedDevice!)
            DispatchQueue.main.async {
                self.deviceStatus.text = "Connecting..."
            }
        }
    }

    func disconnected(periperhal: XYPeripheral) {
        DispatchQueue.main.async {
            self.deviceStatus.text = "Disconnected"
            if
                let device = self.selectedDevice,
                let indexToRemove = self.connectedDevices.index(where: { $0.id == device.id }) {

                self.connectedDevices.remove(at: indexToRemove)
                self.selectedDevice = nil
                self.connectedDevicesTableView.reloadData()

                UIView.animate(withDuration: 1.0, animations: {
                    self.deviceStatus.alpha = 0.0
                }, completion: { _ in
                    self.deviceStatus.text = nil
                    self.deviceStatus.alpha = 1.0
                })
            }
        }
    }
}
