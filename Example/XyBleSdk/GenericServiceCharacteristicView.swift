//
//  GenericServiceCharacteristicView.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk

class GenericServiceCharacteristicView: UIView {
    fileprivate lazy var serviceCharacteristics = [XYServiceCharacteristic]()
    fileprivate lazy var characteristicLabels = [CommonLabel]()
    
    fileprivate let rangedDevicesManager = RangedDevicesManager.instance
    fileprivate weak var parent: DeviceDetailViewController?

    convenience init(for service: GenericServiceCharacteristicRegistry, frame: CGRect, parent: DeviceDetailViewController) {
        self.init(frame: frame)
        guard let device = rangedDevicesManager.selectedDevice else { return }
        self.serviceCharacteristics = service.characteristics(for: device.family)
        self.parent = parent
        buildView()
        getValues()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func getValues() {
        guard let device = rangedDevicesManager.selectedDevice else { return }
        var values = [XYBluetoothResult]()
        self.parent?.showRefreshing()
        device.connection {
            values = self.serviceCharacteristics.map { device.get($0, timeout: .seconds(5)) }
        }.then {
            for (index, value) in values.enumerated() {
                guard
                    let label = self.characteristicLabels[safe: index],
                    let characteristic = self.serviceCharacteristics[safe: index]
                    else { continue }

                if let error = value.error {
                    label.text = error.toString
                } else {
                    label.text = value.display(for: characteristic)
                }
            }
        }.always {
            self.parent?.showRefreshControl()
        }.catch { error in
            print(error)
        }
    }

}

extension GenericServiceCharacteristicView: DeviceDetailDelegate {
    func refresh() {
        self.getValues()
    }
}

extension XYBluetoothResult {

    func display(for serviceCharacteristic: XYServiceCharacteristic) -> String? {
        switch serviceCharacteristic.characteristicType {
        case .string:
            return self.asString
        case .integer:
            guard let intVal = self.asInteger else { return "n/a" }
            return "\(intVal)"
        case .byte:
            guard let byteVal = self.asByteArray else { return "n/a" }
            return byteVal.hexa
        }
    }
}

private extension GenericServiceCharacteristicView {

    func buildView() {
        var labels = [UIStackView]()

        serviceCharacteristics.forEach { characteristic in
            labels.append(self.buildRow(for: characteristic))
        }

        let characteristicStack = UIStackView(arrangedSubviews: labels)
        characteristicStack.axis = .vertical
        characteristicStack.distribution = .equalCentering
        characteristicStack.alignment = .leading
        characteristicStack.spacing = 8
        characteristicStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(characteristicStack)

        let margins = self.layoutMarginsGuide
        characteristicStack.topAnchor.constraint(equalTo: margins.topAnchor, constant: 8).isActive = true
        characteristicStack.leftAnchor.constraint(equalTo: margins.leftAnchor, constant: 8).isActive = true
    }

    func buildRow(for characteristic: XYServiceCharacteristic) -> UIStackView {
        let label = CommonLabel()
        label.text = characteristic.displayName + ":"

        let value = CommonLabel().color(CommonLabel.xyGray)
        value.text = "n/a"
        self.characteristicLabels.append(value)

        let stack = UIStackView(arrangedSubviews: [label, value])

        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }

}
