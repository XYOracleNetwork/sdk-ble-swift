//
//  CommonLabel.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 10/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

@IBDesignable
class CommonLabel: UILabel {

    static let xyGray = UIColor(red: 162/255, green: 162/255, blue: 162/255, alpha: 1.0)

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
        color(UIColor.black).size(14.0)
    }

}

extension CommonLabel {

    @discardableResult func color(_ value: UIColor) -> Self {
        self.textColor = value
        return self
    }

    @discardableResult func size(_ value: CGFloat) -> Self {
        self.font = font.withSize(value)
        return self
    }
}
