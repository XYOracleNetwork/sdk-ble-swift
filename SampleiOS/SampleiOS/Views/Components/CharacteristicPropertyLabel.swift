//
//  CharacteristicPropertyLabel.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/6/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

@IBDesignable
class CharacteristicPropertyLabel: UILabel {

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
        self.translatesAutoresizingMaskIntoConstraints = false
        color(ViewController.xyGreen).bold(14.0).alignment(.center)
    }

    // Ensures the circle is painted properly when used with auto-layout
    override func layoutSubviews() {
        self.addCircle(22.0, border: 2.0)
    }

}

extension UILabel {

    @discardableResult func text(_ text: String) -> Self {
        self.text = text
        return self
    }

    @discardableResult func color(_ value: UIColor) -> Self {
        self.textColor = value
        return self
    }

    @discardableResult func alignment(_ value: NSTextAlignment) -> Self {
        self.textAlignment = value
        return self
    }

    @discardableResult func size(_ value: CGFloat) -> Self {
        self.font = font.withSize(value)
        return self
    }

    @discardableResult func bold(_ value: CGFloat) -> Self {
        self.font = UIFont.boldSystemFont(ofSize: value)
        return self
    }

    @discardableResult func addCircle(_ size: CGFloat, border: CGFloat) -> Self {
        self.bounds = CGRect(x: 0.0, y: 0.0, width: size, height: size)
        self.layer.cornerRadius = size / 2
        self.layer.borderWidth = border
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.borderColor = self.textColor.cgColor
        return self
    }

}
