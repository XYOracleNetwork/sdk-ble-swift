//
//  XYFirmwareUpdateManager.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

enum XYFirmwareUpdateStep {
    case unstarted
    case start
    case memoryType
}

enum XYFirmwareUpdateMemoryType: Int {
    case SUOTA_I2C = 0x12
    case SUOTA_SPI = 0x13
    case SPOTA_SYSTEM_RAM = 0x00
    case SPOTA_RETENTION_RAM = 0x01
    case SPOTA_I2C = 0x02
    case SPOTA_SPI = 0x03
}

class XYFirmwareUpdateManager {

    fileprivate var
    currentStep: Int = 1,
    nextStep: Int = 0,
    expectedValue: Int = 0,
    chunkSize: Int = 20,
    chunkStartByte: Int = 0

    func update() {

    }

}

private extension XYFirmwareUpdateManager {

    func doStep(_ step: XYFirmwareUpdateStep) {
        switch step {
        case .start:
            currentStep = 0
            expectedValue = 0x1
            nextStep = 2

            break
        case .memoryType:
            break
        default:
            break
        }
    }

}
