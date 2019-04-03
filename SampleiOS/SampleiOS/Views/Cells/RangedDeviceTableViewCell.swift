//
//  RangedDeviceTableViewCell.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

struct RangedDeviceCellDirective {
    let
    name: String,
    major: UInt16,
    rssi: Int,
    uuid: UUID,
    connected: Bool,
    minor: UInt16,
    pulses: Int,
    minRssi: Int,
    maxRssi: Int
}

class RangedDeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var pulsesLabel: UILabel!
    @IBOutlet weak var minRssiLabel: UILabel!
    @IBOutlet weak var maxRssiLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func populate(from directive: RangedDeviceCellDirective) {
        self.nameLabel.text = directive.name
        self.connectedLabel.text = directive.connected ? "Yes" : "No"
//        self.majorLabel.text = String(format:"0x%02X", directive.major)
//        self.minorLabel.text = String(format:"0x%02X", directive.minor)
        self.majorLabel.text = String(directive.major)
        self.minorLabel.text = String(directive.minor)
        self.rssiLabel.text = String(directive.rssi)
        self.pulsesLabel.text = String(directive.pulses)
        self.minRssiLabel.text = String(directive.minRssi)
        self.maxRssiLabel.text = String(directive.maxRssi)
    }
}
