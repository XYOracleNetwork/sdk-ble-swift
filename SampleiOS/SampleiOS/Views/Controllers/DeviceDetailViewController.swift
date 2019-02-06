//
//  DeviceDetailViewController.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk

protocol DeviceDetailDelegate: class {
    func refresh()
}

class DeviceDetailViewController: UIViewController {

    @IBOutlet weak var servicePicker: UIPickerView!
    @IBOutlet weak var panelContainerView: UIView!
    @IBOutlet weak var gattRequestSpinner: UIActivityIndicatorView!

    fileprivate var currentSelectionIndex: Int = 0
    fileprivate var currentPanelView: UIView?

    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    fileprivate weak var delegate: DeviceDetailDelegate?

    fileprivate var pickerValues = [String]()
    fileprivate var descriptor: GattDeviceDescriptor?

    fileprivate let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))
    fileprivate let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.servicePicker.delegate = self
        self.servicePicker.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        servicePicker.isHidden = true
        self.currentPanelView = InfoServicePanelView(
            frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
            parent: self)
        if let panel = self.currentPanelView {
            self.panelContainerView.addSubview(panel)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        self.inquire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParent {
            self.delegate = nil
            self.rangedDevicesManager.showAlerts = true
            self.currentPanelView?.removeFromSuperview()
            self.rangedDevicesManager.disconnect()
        }
    }

    @objc func refreshTapped() {
        self.delegate?.refresh()
    }

    func inquire() {
        guard  let device = rangedDevicesManager.selectedDevice else { return }
        gattRequestSpinner.startAnimating()
        device.connection {
            _ = device.inquire { result in
                self.descriptor = result
                self.pickerValues = ["Info"] + result.serviceCharacteristics.keys.map { $0.name ?? "Unknown Service" }
                self.servicePicker.reloadAllComponents()
                self.servicePicker.isHidden = false
            }
        }.always {
            self.gattRequestSpinner.stopAnimating()
        }
    }
}

extension DeviceDetailViewController {

    func showRefreshing() {
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
    }

    func showRefreshControl() {
        self.navigationItem.rightBarButtonItem = self.refreshButton
    }

    func showErrorAlert(for error: XYBluetoothError) {
        let alert = UIAlertController(title: "Error", message: error.toString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}

extension DeviceDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerValues.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerValues[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard self.currentSelectionIndex != row else { return }
        self.delegate = nil
        self.currentPanelView?.removeFromSuperview()
        if row == 0 {
            self.rangedDevicesManager.showAlerts = true
            self.currentPanelView = InfoServicePanelView(
                frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
                parent: self)
        } else {
            guard
                let service = self.descriptor?.services[safe: row - 1],
                let characteristics = self.descriptor?.serviceCharacteristics[service]
                else { return }

            self.rangedDevicesManager.showAlerts = false
            self.currentPanelView = GenericServiceCharacteristicView(
                for: characteristics,
                frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
                parent: self)
            
            self.delegate = self.currentPanelView as? DeviceDetailDelegate
        }

        if let panel = self.currentPanelView {
            self.currentSelectionIndex = row
            self.panelContainerView.addSubview(panel)
        }
    }
}
