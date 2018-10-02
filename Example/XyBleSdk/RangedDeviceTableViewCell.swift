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
    pulses: Int
}

class RangedDeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var minorLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var pulsesLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func populate(from directive: RangedDeviceCellDirective) {
        self.nameLabel.text = directive.name
        self.connectedLabel.text = directive.connected ? "Yes" : "No"
        self.majorLabel.text = "\(directive.major)" //  String(format:"0x%02X", directive.major)
        self.minorLabel.text = "\(directive.minor)" // String(format:"0x%02X", directive.minor)
        self.rssiLabel.text = String(directive.rssi)
        self.pulsesLabel.text = String(directive.pulses)
    }
}
