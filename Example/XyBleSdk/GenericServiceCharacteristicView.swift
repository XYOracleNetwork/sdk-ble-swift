//
//  GenericServiceCharacteristicView.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 9/28/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk
import CoreBluetooth

class GenericServiceCharacteristicView: UIView {
    fileprivate lazy var serviceCharacteristics = [GattCharacteristicDescriptor]()
    fileprivate lazy var characteristicLabels = [CommonLabel]()
    
    fileprivate let rangedDevicesManager = RangedDevicesManager.instance
    fileprivate weak var parent: DeviceDetailViewController?

    let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    convenience init(for characteristics: [GattCharacteristicDescriptor], frame: CGRect, parent: DeviceDetailViewController) {
        self.init(frame: frame)
        self.serviceCharacteristics = characteristics
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
            values = self.serviceCharacteristics
                .filter { $0.properties.contains([.read]) }
                .compactMap { $0.service }
                .map { device.get($0, timeout: .seconds(5)) }
        }.then {
            for (index, value) in values.enumerated() {
                guard
                    let label = self.characteristicLabels[safe: index],
                    let characteristic = self.serviceCharacteristics[safe: index]
                    else { continue }

                if let error = value.error {
                    label.text = error.toString
                } else {
                    label.text = value.display(for: characteristic.service!)
                }
            }
        }.always {
            self.parent?.showRefreshControl()
        }.catch { error in
            guard let error = error as? XYBluetoothError else { return }
            self.parent?.showErrorAlert(for: error)
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
            guard let strVal = self.asString else { return "n/a" }
            return "\(strVal)"
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
        self.addSubview(scrollView)
        scrollView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8.0).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8.0).isActive = true
        scrollView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8.0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8.0).isActive = true

        var labels = [UIStackView]()

        serviceCharacteristics
            .forEach { labels.append(self.buildRow(for: $0)) }

        let characteristicStack = UIStackView(arrangedSubviews: labels)
        characteristicStack.axis = .vertical
        characteristicStack.distribution = .equalCentering
        characteristicStack.alignment = .leading
        characteristicStack.spacing = 8
        characteristicStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(characteristicStack)

        characteristicStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8).isActive = true
        characteristicStack.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 8).isActive = true
        characteristicStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -8).isActive = true
        characteristicStack.rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: -8).isActive = true
    }

    func buildRow(for characteristic: GattCharacteristicDescriptor) -> UIStackView {
        let label = CommonLabel()
        label.text = characteristic.service?.displayName ?? "<unknown>" + ":"

        let value = CommonLabel().color(CommonLabel.xyGray)
        value.text = "n/a"
        self.characteristicLabels.append(value)

        let keyValueStack = UIStackView(arrangedSubviews: [label, value])
        keyValueStack.axis = .vertical
        keyValueStack.distribution = .equalSpacing
        keyValueStack.spacing = 8
        keyValueStack.alignment = .leading
        keyValueStack.translatesAutoresizingMaskIntoConstraints = false

        let propertyStack = UIStackView(arrangedSubviews: characteristic.labels)
        propertyStack.axis = .horizontal
        propertyStack.distribution = .fillEqually
        propertyStack.spacing = 12
        propertyStack.alignment = .center
        propertyStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [keyValueStack, propertyStack])
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.spacing = 12
        stack.alignment = .top
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }

}

private extension GattCharacteristicDescriptor {

    var labels: [CharacteristicPropertyLabel] {
        var labels = [CharacteristicPropertyLabel]()
        if self.properties.contains(.read) { labels.append(CharacteristicPropertyLabel().text("R")) }
        if self.properties.contains(.write) { labels.append(CharacteristicPropertyLabel().text("W")) }
        if self.properties.contains(.writeWithoutResponse) { labels.append(CharacteristicPropertyLabel().text("M")) }
        if self.properties.contains(.notify) { labels.append(CharacteristicPropertyLabel().text("N")) }
        return labels
    }

}
