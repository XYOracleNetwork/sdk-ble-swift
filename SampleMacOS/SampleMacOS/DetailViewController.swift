//
//  DetailViewController.swift
//  SampleMacOS
//
//  Created by Darren Sutherland on 1/2/19.
//  Copyright © 2019 XYO Network. All rights reserved.
//

import Cocoa
import XyBleSdk

class DetailViewController: NSViewController {

    fileprivate var device: XYFinderDevice?
    fileprivate var subscribeKey: UUID?

    fileprivate var currentSelectionIndex: Int = 0

    fileprivate var pickerValues = [String]()
    fileprivate var descriptor: GattDeviceDescriptor?

    fileprivate lazy var serviceCharacteristics = [GattCharacteristicDescriptor]()
    fileprivate lazy var characteristicValues = [String?]()

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var deviceIdLabel: NSTextField!
    @IBOutlet weak var gattSpinner: NSProgressIndicator!
    @IBOutlet weak var servicePicker: NSPopUpButton!
    @IBOutlet weak var playSongButton: NSButton!
    @IBOutlet weak var stopPlayingSongButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.servicePicker.target = self
        self.servicePicker.action = #selector(selectedService)
    }

    override func awakeFromNib() {
        self.gattSpinner.isHidden = false
        self.gattSpinner.isIndeterminate = true
        self.gattSpinner.usesThreadedAnimation = true
        self.gattSpinner.startAnimation(self)
    }

    override func viewWillAppear() {
        self.servicePicker.removeAllItems()
    }

    override func viewDidDisappear() {
        self.serviceCharacteristics.removeAll()
        self.characteristicValues.removeAll()
        XYFinderDeviceEventManager.unsubscribe(to: [.connected, .disconnected, .timedOut], referenceKey: self.subscribeKey)
        self.device?.disconnect()
    }

    @objc func selectedService(sender: AnyObject) {
        guard
            let menuItem = sender as? NSButton,
            let mindex = self.pickerValues.firstIndex(where: { $0 == menuItem.title }),
            let service = self.descriptor?.services[safe: mindex],
            let characteristics = self.descriptor?.serviceCharacteristics[service]
            else { return }

        self.serviceCharacteristics = characteristics
        self.getValues()
    }

    func connect(to device: XYFinderDevice) {
        self.device = device
        self.deviceIdLabel.stringValue = device.id
        self.device?.connect()
        self.subscribeKey = XYFinderDeviceEventManager.subscribe(to: [.connected, .disconnected, .timedOut]) { event in
            switch event {
            case .connected:
                self.inquire()
            case .disconnected:
                DispatchQueue.main.async {
                    self.gattSpinner.stopAnimation(self)
                    self.showAlert(for: "Disconnected", title: "Error")
                }
            case .timedOut(_, let type):
                DispatchQueue.main.async {
                    self.gattSpinner.stopAnimation(self)
                    self.showAlert(for: "Timed out: \(type.rawValue)", title: "Error")
                }
            default:
                break
            }
        }
    }

    @IBAction func playSongPressed(_ sender: NSButton) {
        guard
            let device = self.device
            else { return }
        wrapper(for: sender, operation: {
            device.find(.findIt)
        })
    }

    @IBAction func stopPlayingSongPressed(_ sender: NSButton) {
        guard
            let device = self.device
            else { return }
        wrapper(for: sender, operation: {
            device.find(.off)
        })
    }
}

fileprivate extension DetailViewController {

    func wrapper(for button: NSButton, operation: @escaping () -> XYBluetoothResult) {
        guard
            let device = self.device
            else { return }

        self.gattSpinner.startAnimation(self)
        button.isEnabled = false

        var result: XYBluetoothResult?
        device.connection {
            if device.unlock().hasError == false {
                result = operation()
            }
        }.then {
            DispatchQueue.main.async {
                if let error = result?.error {
                    self.showAlert(for: error.toString, title: "Error")
                }
            }
        }.always {
            DispatchQueue.main.async {
                button.isEnabled = true
                self.gattSpinner.stopAnimation(self)
            }
        }
    }

}

fileprivate extension DetailViewController {

    func inquire() {
        guard  let device = self.device else { return }
        device.connection {
            _ = device.inquire { result in
                self.descriptor = result
                self.pickerValues = result.serviceCharacteristics.keys.map { $0.name ?? "Unknown Service" }
                self.servicePicker.addItems(withTitles: self.pickerValues)
            }
        }.always {
            self.gattSpinner.stopAnimation(self)
        }
    }

    func getValues() {
        guard let device = self.device else { return }
        self.characteristicValues.removeAll()
        var values = [XYBluetoothResult]()
        self.gattSpinner.startAnimation(self)
        device.connection {
            values = self.serviceCharacteristics
                .filter { $0.properties.contains([.read]) }
                .compactMap { $0.service }
                .map { device.get($0, timeout: .seconds(5)) }
        }.then {
            for (index, value) in values.enumerated() {
                guard
                    let characteristic = self.serviceCharacteristics[safe: index]
                    else { continue }

                if let error = value.error {
                    self.characteristicValues.insert(error.toString, at: index)
                } else {
                    self.characteristicValues.insert(value.display(for: characteristic.service!), at: index)
                }
            }
        }.always {
            DispatchQueue.main.async {
                self.gattSpinner.stopAnimation(self)
                self.tableView.reloadData()
            }
        }.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.showAlert(for: error.toString, title: "Error")
        }
    }

    func showAlert(for message: String, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}

extension XYBluetoothResult {

    func display(for serviceCharacteristic: XYServiceCharacteristic) -> String? {
        switch serviceCharacteristic.characteristicType {
        case .string:
            guard let strVal = self.asString else { return "n/a" }
            return "\(strVal)"
        case .integer:
            guard let intVal = self.asInteger else { return "n/a" }
            return "\(intVal)"
        case .byte:
            guard let byteVal = self.asByteArray else { return "n/a" }
            return byteVal.hexa
        }
    }
}

extension DetailViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return serviceCharacteristics.count
    }
}

extension DetailViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let CharacteristicCellId = "CharacteristicCell"
        static let ValueCellId = "ValueCell"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard
            let characteristic = self.serviceCharacteristics[safe: row],
            let value = self.characteristicValues[safe: row]
            else { return nil }

        var text: String = ""
        var cellIdentifier: String = ""

        if tableColumn == tableView.tableColumns[0] {
            text = characteristic.service?.displayName ?? "<unknown>"
            cellIdentifier = CellIdentifiers.CharacteristicCellId
        } else if tableColumn == tableView.tableColumns[1] {
            text = value ?? "<unknown>"
            cellIdentifier = CellIdentifiers.ValueCellId
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }

        return nil
    }

}
