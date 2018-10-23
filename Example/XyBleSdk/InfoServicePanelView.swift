//
//  InfoServicePanelView.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk
import Promises

final class InfoServicePanelView: UIView {
    @IBOutlet var contentView: InfoServicePanelView!

    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    @IBOutlet weak var familyLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var pulsesLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!

    fileprivate weak var parent: DeviceDetailViewController?

    @IBOutlet weak var stayAwakeButton: CommonButton!
    @IBOutlet weak var fallAsleepButton: CommonButton!

    convenience init(frame: CGRect, parent: DeviceDetailViewController) {
        self.init(frame: frame)
        self.parent = parent
        self.parent?.showRefreshing()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("InfoServicePanelView", owner: self, options: [:])
        addSubview(contentView)
        populate()
    }

    private func populate() {
        guard let device = self.rangedDevicesManager.selectedDevice else { return }
        self.familyLabel.text = device.family.familyName
        self.majorLabel.text = String(format:"0x%02X", device.iBeacon?.major ?? 0)
        self.minorLabel.text = String(format:"0x%02X", device.iBeacon?.minor ?? 0)
        self.pulsesLabel.text = String(device.totalPulseCount)
        self.rssiLabel.text = String(device.rssi)
        updateStayAwakeButtonStates()
    }

    private func updateStayAwakeButtonStates() {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        self.stayAwakeButton.isEnabled = false
        self.fallAsleepButton.isEnabled = false

        device.connection {
            let data = device.get(PrimaryService.stayAwake)
            var value = 0
            if let intVal = data.asInteger {
                value = intVal
            }
            DispatchQueue.main.async {
                if value == 1 {
                    self.stayAwakeButton.isEnabled = false
                    self.fallAsleepButton.isEnabled = true
                } else {
                    self.stayAwakeButton.isEnabled = true
                    self.fallAsleepButton.isEnabled = false
                }
            }
        }.always {
            self.parent?.showRefreshControl()
        }
    }

}

extension InfoServicePanelView {

    private func wrapper(_ button: CommonButton, operation: @escaping () -> XYBluetoothResult, completion: (() -> Void)? = nil) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        self.parent?.showRefreshing()
        button.isEnabled = false

        var result: XYBluetoothResult?
        device.connection {
            result = operation()
        }.then {
            if let error = result?.error {
                self.parent?.showErrorAlert(for: error)
            }
        }.always {
            button.isEnabled = true
            self.parent?.showRefreshControl()
            completion?()
        }
    }

    @IBAction func findTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, operation: {
            device.find(.findIt)
        })
    }

    @IBAction func stayAwakeTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, operation: {
            device.stayAwake()
        }, completion: {
            self.updateStayAwakeButtonStates()
        })
    }

    @IBAction func fallAsleep(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, operation: {
            device.fallAsleep()
        }, completion: {
            self.updateStayAwakeButtonStates()
        })
    }

    @IBAction func lockTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, operation: {
            device.lock()
        })
    }

    @IBAction func unlockTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, operation: {
            device.unlock()
        })
    }

    @IBAction func enableNotifyTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        device.subscribeToButtonPress()
    }

    @IBAction func disableNotifyTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        device.unsubscribeToButtonPress(for: self.rangedDevicesManager.subscriptionUuid)
    }

}
