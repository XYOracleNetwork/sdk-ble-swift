//
//  XYFirmwareUpdateManager.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

//enum XYFirmwareUpdateStep {
//    case unstarted
//    case start
//    case memoryType
//}

enum XYFirmwareUpdateMemoryType: Int {
    case SUOTA_I2C = 0x12
    case SUOTA_SPI = 0x13
    case SPOTA_SYSTEM_RAM = 0x00
    case SPOTA_RETENTION_RAM = 0x01
    case SPOTA_I2C = 0x02
    case SPOTA_SPI = 0x03
}

enum XYFirmwareStatusValues: Int {
    case SPOTAR_SRV_STARTED       = 0x01     // Valid memory device has been configured by initiator. No sleep state while in this mode
    case SPOTAR_CMP_OK            = 0x02     // SPOTA process completed successfully.
    case SPOTAR_SRV_EXIT          = 0x03     // Forced exit of SPOTAR service.
    case SPOTAR_CRC_ERR           = 0x04     // Overall Patch Data CRC failed
    case SPOTAR_PATCH_LEN_ERR     = 0x05     // Received patch Length not equal to PATCH_LEN characteristic value
    case SPOTAR_EXT_MEM_WRITE_ERR = 0x06     // External Mem Error (Writing to external device failed)
    case SPOTAR_INT_MEM_ERR       = 0x07     // Internal Mem Error (not enough space for Patch)
    case SPOTAR_INVAL_MEM_TYPE    = 0x08     // Invalid memory device
    case SPOTAR_APP_ERROR         = 0x09     // Application error
}

class XYFirmwareUpdateManager {

    fileprivate let device: XYBluetoothDevice

    private let notifyKey = "XYFirmwareUpdateManager"

    fileprivate var
    currentStep: Int = 1,
    nextStep: Int = 0,
    expectedValue: Int = 0,
    chunkSize: Int = 20,
    chunkStartByte: Int = 0,
    patchBaseAddress: Int = 0

    fileprivate var
    success: (() -> Void)?,
    failure: ((_ error: XYBluetoothError) -> Void)?

    var memoryType: Int = XYFirmwareUpdateMemoryType.SPOTA_SPI.rawValue

    init(for device: XYBluetoothDevice) {
        self.device = device
    }

    func update(_ success: @escaping () -> Void, failure: @escaping (_ error: XYBluetoothError) -> Void) {
        self.success = success
        self.failure = failure

        // Set notifications on for the update service
        self.device.connection {
            if self.device.subscribe(to: OtaService.servStatus, delegate: (key: self.notifyKey, delegate: self)).hasError {
                self.failure?(XYBluetoothError.serviceNotFound)
            }
        }
    }

    deinit {
        _ = self.device.unsubscribe(from: OtaService.servStatus, key: notifyKey)
    }
}

private extension XYFirmwareUpdateManager {

    func doStep() {
        switch self.currentStep {
        case 1:
            currentStep = 0
            expectedValue = 0x1
            nextStep = 2

            // Set the memory type. This will write the value, which will trigger the notification in readValue() below
            let memDevData = (self.memoryType << 24) | (self.patchBaseAddress & 0xFFFFFF)
            let data = NSData(bytes: [memDevData] as [Int], length: MemoryLayout<Int>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))
            self.writeValue(parameter, service: OtaService.memDev)

        case 2:
            break
        default:
            break
        }
    }

}

private extension XYFirmwareUpdateManager {

    func writeValue(_ value: XYBluetoothResult, service: XYServiceCharacteristic) {
        self.device.connection {
            if self.device.set(service, value: value).hasError == false {
                self.doStep()
            }
        }
    }

    func readValue(for serviceCharacteristic: OtaService, value: XYBluetoothResult) {
        switch serviceCharacteristic {
        case .servStatus:
            guard let value = value.asInteger else { break }

            if self.expectedValue != 0, value == self.expectedValue {
                self.currentStep = self.nextStep
                self.doStep()
            } else {
                self.handleResponse(for: value)
            }

            expectedValue = 0

        case .memInfo:
            break
        default:
            break
        }
    }

}

private extension XYFirmwareUpdateManager {

    func handleResponse(for responseValue: Int) {
        var message: String

        guard let errorEnum = XYFirmwareStatusValues(rawValue: responseValue) else {
            message = "Unhandled status code \(responseValue)"
            return
        }

        switch errorEnum {
        case .SPOTAR_SRV_STARTED:
            message = "Valid memory device has been configured by initiator. No sleep state while in this mode"
        case .SPOTAR_CMP_OK:
            message = "SPOTA process completed successfully."
        case .SPOTAR_SRV_EXIT:
            message = "Forced exit of SPOTAR service."
        case .SPOTAR_CRC_ERR:
            message = "Overall Patch Data CRC failed"
        case .SPOTAR_PATCH_LEN_ERR:
            message = "Received patch Length not equal to PATCH_LEN characteristic value"
        case .SPOTAR_EXT_MEM_WRITE_ERR:
            message = "External Mem Error (Writing to external device failed)"
        case .SPOTAR_INT_MEM_ERR:
            message = "Internal Mem Error (not enough space for Patch)"
        case .SPOTAR_INVAL_MEM_TYPE:
            message = "Invalid memory device"
        case .SPOTAR_APP_ERROR:
            message = "Application error"
        }
    }

}

extension XYFirmwareUpdateManager: XYBluetoothDeviceNotifyDelegate {

    func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        guard let characteristic = serviceCharacteristic as? OtaService else { return }
        self.readValue(for: characteristic, value: value)
    }

}
