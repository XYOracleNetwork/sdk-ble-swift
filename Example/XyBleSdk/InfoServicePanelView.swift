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
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var beaconUuid: UILabel!

    fileprivate weak var parent: DeviceDetailViewController?

    @IBOutlet weak var stayAwakeButton: CommonButton!
    @IBOutlet weak var fallAsleepButton: CommonButton!

    @IBOutlet weak var connectionButton: CommonButton!
    @IBOutlet weak var disconnectionButton: CommonButton!

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
        self.idLabel.text = device.id.shortId
        self.beaconUuid.text = device.family.uuid.uuidString
        updateStayAwakeAndConnectionButtonStates()
    }

    private func updateStayAwakeAndConnectionButtonStates() {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        self.connectionButton.isEnabled = false
        self.disconnectionButton.isEnabled = false
        self.stayAwakeButton.isEnabled = false
        self.fallAsleepButton.isEnabled = false

        var isAwake: XYBluetoothResult?
        device.connection {
            let name = __dispatch_queue_get_label(nil)
            print(" Checking isAwake on queue \(String(cString: name, encoding: .utf8) ?? "<unknown>")")
            isAwake = device.isAwake()
        }.then {
            var value: [UInt8] = [0x00]
            if let byteVal = isAwake?.asByteArray {
                value = byteVal
            }
            DispatchQueue.main.async {
                if value.count > 0 && value[0] != 0x00 {
                    self.stayAwakeButton.isEnabled = false
                    self.fallAsleepButton.isEnabled = true
                    self.connectionButton.isEnabled = false
                    self.disconnectionButton.isEnabled = true
                } else {
                    self.stayAwakeButton.isEnabled = true
                    self.fallAsleepButton.isEnabled = false
                    self.connectionButton.isEnabled = true
                    self.disconnectionButton.isEnabled = false
                }
            }
        }.always {
            self.parent?.showRefreshControl()
        }

//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
//            let name = __dispatch_queue_get_label(nil)
//            print(" @ @ @ @ I'm tapping the button!!! on queue \(String(cString: name, encoding: .utf8) ?? "<unknown>")")
//            device.connection {
//                device.find(.findIt)
//            }
//        })
    }

}

extension InfoServicePanelView {

    private func wrapper(_ button: CommonButton, unlock: Bool, operation: @escaping () -> XYBluetoothResult, completion: (() -> Void)? = nil) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        self.parent?.showRefreshing()
        button.isEnabled = false

        var result: XYBluetoothResult?
        print(" -------------- BOOF" )
        device.connection {
            if unlock && device.unlock().hasError == false {
                result = operation()
            } else {
                result = operation()
            }
        }.then {
            if let error = result?.error {
                self.parent?.showErrorAlert(for: error)
            } else {
                self.parent?.showAlert(title: "Operation Successful", message: "No error")
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
        wrapper(sender, unlock: true, operation: {
            device.find(.findIt)
        })
    }

    @IBAction func stopFindTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, unlock: true, operation: {
            device.find(.off)
        })
    }

    @IBAction func stayAwakeTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, unlock: true, operation: {
            device.stayAwake()
        }, completion: {
            self.updateStayAwakeAndConnectionButtonStates()
        })
    }

    @IBAction func fallAsleep(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, unlock: true, operation: {
            device.fallAsleep()
        }, completion: {
            self.updateStayAwakeAndConnectionButtonStates()
        })
    }

    @IBAction func lockTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, unlock: true, operation: {
            device.lock()
        })
    }

    @IBAction func unlockTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        wrapper(sender, unlock: false, operation: {
            device.unlock()
        })
    }

    @IBAction func enableNotifyTapped(_ sender: CommonButton) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }


        device.subscribeToButtonPress()
    }

    @IBAction func disableNotifyTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        device.connection {
            _ = device.unsubscribeToButtonPress(for: nil)
        }
    }

    @IBAction func emulateConnectTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        device.connection {
            let unlock = device.unlock()
            let stayAwake = device.stayAwake()

            if unlock.hasError {
                self.parent?.showErrorAlert(for: unlock.error!)
            }

            if stayAwake.hasError {
                self.parent?.showErrorAlert(for: stayAwake.error!)
            }

            if (unlock.hasError && stayAwake.hasError) == false {
                self.parent?.showAlert(title: "Operation Successful", message: "No error")
            }
        }.always {
            self.updateStayAwakeAndConnectionButtonStates()
        }
    }

    @IBAction func emulateDisconnectTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }

        device.connection {
            let unlock = device.unlock()
            let fallAsleep = device.fallAsleep()

            if unlock.hasError {
                self.parent?.showErrorAlert(for: unlock.error!)
            }

            if fallAsleep.hasError {
                self.parent?.showErrorAlert(for: fallAsleep.error!)
            }

            if (unlock.hasError && fallAsleep.hasError) == false {
                self.parent?.showAlert(title: "Operation Successful", message: "No error")
            }

        }.always {
            self.updateStayAwakeAndConnectionButtonStates()
        }
    }

}
