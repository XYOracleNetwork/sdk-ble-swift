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

    fileprivate var currentSelection: GenericServiceCharacteristicRegistry = .info
    fileprivate var currentPanelView: UIView?

    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    fileprivate weak var delegate: DeviceDetailDelegate?

    fileprivate let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTapped))
    fileprivate let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.servicePicker.delegate = self
        self.servicePicker.dataSource = self
    }

    @IBAction func findTapped(_ sender: Any) {
        _ = self.rangedDevicesManager.selectedDevice?.find()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.currentPanelView = InfoServicePanelView(
            frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
            parent: self)
        if let panel = self.currentPanelView {
            self.panelContainerView.addSubview(panel)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if self.isMovingFromParentViewController {
            self.delegate = nil
            self.currentPanelView?.removeFromSuperview()
            self.rangedDevicesManager.disconnect()
        }
    }

    @objc func refreshTapped() {
        self.delegate?.refresh()
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
}

extension DeviceDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return GenericServiceCharacteristicRegistry.values.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return GenericServiceCharacteristicRegistry.values[row].rawValue
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard currentSelection.index != row else { return }
        self.delegate = nil
        self.currentPanelView?.removeFromSuperview()
        if row == 0 {
            self.currentPanelView = InfoServicePanelView(
                frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
                parent: self)
        } else {
            self.currentPanelView = GenericServiceCharacteristicView(
                for: GenericServiceCharacteristicRegistry.fromIndex(row),
                frame: CGRect(x: 0, y: 0, width: panelContainerView.frame.width, height: panelContainerView.frame.height),
                parent: self)
            self.delegate = self.currentPanelView as? DeviceDetailDelegate
        }

        if let panel = self.currentPanelView {
            currentSelection = GenericServiceCharacteristicRegistry.fromIndex(row)
            self.panelContainerView.addSubview(panel)
        }
    }
}
