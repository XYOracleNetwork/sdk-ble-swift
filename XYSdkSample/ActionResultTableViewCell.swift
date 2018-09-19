//
//  ActionResultTableViewCell.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/19/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import UIKit

class ActionResultTableViewCell: UITableViewCell {

    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func set(_ uuid: String, value: String) {
        self.uuidLabel.text = uuid
        self.valueLabel.text = value
    }
}
