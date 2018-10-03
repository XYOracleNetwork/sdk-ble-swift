//
//  InfoServicePanelView.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk

final class InfoServicePanelView: UIView {
    @IBOutlet var contentView: InfoServicePanelView!

    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    @IBOutlet weak var familyLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var pulsesLabel: UILabel!

    fileprivate weak var parent: DeviceDetailViewController?

    convenience init(frame: CGRect, parent: DeviceDetailViewController) {
        self.init(frame: frame)
        self.parent = parent
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
        self.pulsesLabel.text = String(0)
    }

    @IBAction func disconnectTapped(_ sender: Any) {
        self.rangedDevicesManager.disconnect()
    }

}

extension InfoServicePanelView {

    @IBAction func findTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        self.parent?.showRefreshing()
        device.find()?.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
        }.always {
            self.parent?.showRefreshControl()
        }
    }

    @IBAction func stayAwakeTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        self.parent?.showRefreshing()
        device.stayAwake()?.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
        }.always {
            self.parent?.showRefreshControl()
        }
    }

    @IBAction func fallAsleep(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        self.parent?.showRefreshing()
        device.fallAsleep()?.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
        }.always {
            self.parent?.showRefreshControl()
        }
    }

    @IBAction func lockTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        self.parent?.showRefreshing()
        device.lock()?.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
        }.always {
            self.parent?.showRefreshControl()
        }
    }

    @IBAction func unlockTapped(_ sender: Any) {
        guard
            let device = self.rangedDevicesManager.selectedDevice
            else { return }
        self.parent?.showRefreshing()
        device.unlock()?.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
        }.always {
            self.parent?.showRefreshControl()
        }
    }

    @IBAction func enableNotifyTapped(_ sender: Any) {
    }

    @IBAction func disableNotifyTapped(_ sender: Any) {
    }

}
