//
//  ViewController.swift
//  SampleMacOS
//
//  Created by Darren Sutherland on 12/28/18.
//  Copyright © 2018 XYO Network. All rights reserved.
//

import Cocoa
import XyBleSdk

class ViewController: NSViewController {

    let smartScan = XYSmartScan.instance

    @IBOutlet weak var tableView: NSTableView!

    fileprivate static let delegateKey = "ViewController"

    fileprivate var items = [XYFinderDevice]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.doubleAction = #selector(selectedDevice)
    }

    override var representedObject: Any? {
        didSet {}
    }

    @objc private func selectedDevice(sender: AnyObject) {
        guard
            self.tableView.selectedRow >= 0,
            let device = self.items[safe: tableView.selectedRow]
            else { return }

        let detailView = DetailViewController()
        self.presentAsModalWindow(detailView)
        detailView.connect(to: device)
    }

    @IBAction func startScanPressed(_ sender: NSButton) {
        self.items.removeAll()
        self.tableView.reloadData()
        self.smartScan.setDelegate(self, key: ViewController.delegateKey)
        self.smartScan.start(mode: .foreground)
    }

    @IBAction func stopScanPressed(_ sender: NSButton) {
        self.smartScan.removeDelegate(for: ViewController.delegateKey)
        self.smartScan.stop()
    }
}

extension ViewController: XYSmartScanDelegate {
    func smartScan(detected device: XYFinderDevice, signalStrength: Int, family: XYFinderDeviceFamily) {
        if self.items.contains(where: { $0 == device }) == false {
            self.items.append(device)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func smartScan(status: XYSmartScanStatus) {}
    func smartScan(location: XYLocationCoordinate2D) {}
    func smartScan(detected devices: [XYFinderDevice], family: XYFinderDeviceFamily) {}
    func smartScan(entered device: XYFinderDevice) {}
    func smartScan(exiting device: XYBluetoothDevice) {}
    func smartScan(exited device: XYFinderDevice) {}
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
}

extension ViewController: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let UUIDCell = "UUID"
        static let MajorCell = "Major"
        static let MinorCell = "Minor"
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard let beacon = items[row].iBeacon else { return nil }

        var text: String = ""
        var cellIdentifier: String = ""

        if tableColumn == tableView.tableColumns[0] {
            text = beacon.uuid.uuidString
            cellIdentifier = CellIdentifiers.UUIDCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = "\(beacon.major ?? 0)"
            cellIdentifier = CellIdentifiers.MajorCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = "\(beacon.minor ?? 0)"
            cellIdentifier = CellIdentifiers.MinorCell
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }

        return nil
    }

}
