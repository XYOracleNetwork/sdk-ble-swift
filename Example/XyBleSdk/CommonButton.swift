//
//  CommonButton.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

@IBDesignable
class CommonButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForInterfaceBuilder() {
        sharedInit()
    }

    func sharedInit() {
        self.backgroundColor = ViewController.xyGreen
        self.setTitleColor(UIColor.white, for: .normal)
        self.setTitleColor(UIColor.gray, for: .disabled)
        self.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        self.layer.cornerRadius = 10
    }

}
