//
//  XYFirmwareUpdateManager.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//
//  Ported from Dialog SPOTA Demo

public  struct XYFirmwareUpdateParameters {
    let
    spiMISOAddress: Int32,
    spiMOSIAddress: Int32,
    spiCSAddress: Int32,
    spiSCKAddress: Int32

    public static var xy4: XYFirmwareUpdateParameters {
        return XYFirmwareUpdateParameters(spiMISOAddress: 0x05, spiMOSIAddress: 0x06, spiCSAddress: 0x07, spiSCKAddress: 0x00)
    }
}

public class XYFirmwareUpdateManager {

    enum XYFirmwareUpdateMemoryType: Int32 {
        case SUOTA_I2C = 0x12
        case SUOTA_SPI = 0x13
        case SPOTA_SYSTEM_RAM = 0x00
        case SPOTA_RETENTION_RAM = 0x01
        case SPOTA_I2C = 0x02
        case SPOTA_SPI = 0x03
    }

    fileprivate let
    device: XYBluetoothDevice,
    firmwareData: Data

    private let notifyKey = "XYFirmwareUpdateManager"

    fileprivate var
    currentStep: XYFirmwareUpdateStep = .unstarted,
    nextStep: XYFirmwareUpdateStep = .unstarted

    fileprivate var
    expectedValue: Int = 0,
    chunkSize: Int = 20,
    chunkStartByte: Int = 0,
    patchBaseAddress: Int32 = 0

    fileprivate let parameters: XYFirmwareUpdateParameters

    fileprivate var
    success: (() -> Void)?,
    failure: ((_ error: XYBluetoothError) -> Void)?

    var memoryType: XYFirmwareUpdateMemoryType = XYFirmwareUpdateMemoryType.SUOTA_SPI

    public init(for device: XYBluetoothDevice, parameters: XYFirmwareUpdateParameters, firmwareData: Data) {
        self.device = device
        self.parameters = parameters
        self.firmwareData = firmwareData
    }

    public func update(_ success: @escaping () -> Void, failure: @escaping (_ error: XYBluetoothError) -> Void) {
        self.success = success
        self.failure = failure

        // Set notifications on for the update service
        self.device.connection {
            if self.device.subscribe(to: OtaService.servStatus, delegate: (key: self.notifyKey, delegate: self)).hasError {
                self.failure?(XYBluetoothError.serviceNotFound)
            } else {
                self.currentStep = .setMemoryType
                self.doStep()
            }
        }
    }
}

// MARK: Multi-step updater
private extension XYFirmwareUpdateManager {

    enum XYFirmwareUpdateStep: String {
        case unstarted
        case setMemoryType
        case setMemoryParameters
        case validateMemoryType
        case validatePatchData
        case setPatchLength
        case sendPatch
        case validatePatchComplete
        case completed
    }

    func doStep() {
        switch self.currentStep {
        case .unstarted:
            break
        case .setMemoryType:
            currentStep = .unstarted
            expectedValue = 0x10
            nextStep = .setMemoryParameters

            // Set the memory type. This will write the value, which will trigger the notification in readValue() below
            var memDevData: Int32 = (self.memoryType.rawValue << 24) | (self.patchBaseAddress & 0xFF)
            let data = NSData(bytes: &memDevData, length: MemoryLayout<Int32>.size) // MemoryLayout.size(ofValue: memDevData))
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            print("- FIRMWARE Step: \(self.currentStep.rawValue) - Value is \(parameter.asInteger ?? -1)")

            self.writeValue(to: .memDev, value: parameter)

        case .setMemoryParameters:
            if self.memoryType == XYFirmwareUpdateMemoryType.SPOTA_SPI {
                var memInfoData: Int32 =
                    (self.parameters.spiMISOAddress << 24) |
                    (self.parameters.spiMOSIAddress << 16) |
                    (self.parameters.spiCSAddress << 8) |
                    self.parameters.spiSCKAddress
                let data = NSData(bytes: &memInfoData, length: MemoryLayout<Int32>.size)
                let parameter = XYBluetoothResult(data: Data(referencing: data))

                self.currentStep = .validateMemoryType
                self.writeValue(to: .gpioMap, value: parameter)

            } else {
                self.currentStep = .validateMemoryType
                doStep()
            }

        case .validateMemoryType:
            self.currentStep = .validatePatchData
            self.readValue(from: .memInfo)

        case .validatePatchData:
            // TODO Data validate? We already have it at this point

            self.currentStep = .setPatchLength
            self.doStep()

        case .setPatchLength:
            let dataLength = firmwareData.count
            let data = NSData(bytes: [dataLength] as [Int], length: MemoryLayout<Int>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            self.currentStep = .sendPatch

            self.writeValue(to: .patchLen, value: parameter)

        case .sendPatch:
            self.currentStep = .unstarted
            self.expectedValue = 0x02
            self.nextStep = .validatePatchComplete

            let dataLength = firmwareData.count
            var bytesRemaining = dataLength

            while bytesRemaining > 0 {
                // Check if we have less than current block-size bytes remaining
                if bytesRemaining < chunkSize {
                    chunkSize = bytesRemaining
                }

                let payload = UnsafeMutableBufferPointer<[Int]>.allocate(capacity: dataLength)
                let range = NSMakeRange(self.chunkStartByte, self.chunkSize)
                _ = self.firmwareData.copyBytes(to: payload, from: Range(range))
                let parameter = XYBluetoothResult(data: Data(buffer: payload))

                self.chunkStartByte += self.chunkSize
                bytesRemaining = dataLength - self.chunkStartByte

                self.writeValue(to: .patchData, value: parameter)
            }

        case .validatePatchComplete:
            self.currentStep = .completed
            self.readValue(from: .memInfo)

        case .completed:
            self.device.connection {
                _ = self.device.unsubscribe(from: OtaService.servStatus, key: self.notifyKey)
            }.always {
                self.device.disconnect()
                self.success?()
            }

        }
    }

}

// MARK: Read and write values to the device, as well as process any response
private extension XYFirmwareUpdateManager {

    func writeValue(to service: OtaService, value: XYBluetoothResult) {
        self.device.connection {
            let result = self.device.set(service, value: value)
            if result.hasError == false {
                self.doStep()
            } else {
                print(result.error?.toString ?? "<unknown>")
            }
        }
    }

    func readValue(from service: OtaService) {
        self.device.connection {
            let result = self.device.get(service)
            if result.hasError == false {
                self.processValue(for: service, value: result)
            } else {
                print(result.error?.toString ?? "<unknown>")
            }
        }
    }

    func processValue(for serviceCharacteristic: OtaService, value: XYBluetoothResult) {
        switch serviceCharacteristic {
        case .servStatus:
            guard let data = value.asInteger else { break }

            // Debug output
            self.handleResponse(for: data)

            if self.expectedValue != 0, data == self.expectedValue {
                self.currentStep = self.nextStep
                self.doStep()
            }

            expectedValue = 0

        case .memInfo:
            guard let data = value.asInteger else {
                // TODO error
                return
            }

            let patches = (data >> 16) & 0xff
            let patchsize = data & 0xff

            print("Patch Memory Info:\n  Number of patches: \(patches)\n  Size of patches: \(ceil(Double(patchsize)/4)) (\(patchsize))")

            if self.currentStep != .unstarted {
                self.doStep()
            }

        default:
            break
        }
    }

}

// MARK: Handle firmware responses
private extension XYFirmwareUpdateManager {

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

        case SPOTAR_IMG_STARTED       = 0x10     // SPOTA started for downloading image (SUOTA application)
        case SPOTAR_INVAL_IMG_BANK    = 0x11     // Invalid image bank
        case SPOTAR_INVAL_IMG_HDR     = 0x12     // Invalid image header
        case SPOTAR_INVAL_IMG_SIZE    = 0x13     // Invalid image size
        case SPOTAR_INVAL_PRODUCT_HDR = 0x14     // Invalid product header
        case SPOTAR_SAME_IMG_ERR      = 0x15     // Same Image Error
        case SPOTAR_EXT_MEM_READ_ERR  = 0x16     // Failed to read from external memory device
    }

    func handleResponse(for responseValue: Int) {
        var message: String

        guard let errorEnum = XYFirmwareStatusValues(rawValue: responseValue) else {
            print("Unhandled status code \(responseValue)")
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
        case .SPOTAR_IMG_STARTED:
            message = "SPOTA started for downloading image"
        case .SPOTAR_INVAL_IMG_BANK:
            message = "Invalid image bank"
        case .SPOTAR_INVAL_IMG_HDR:
            message = "Invalid image header"
        case .SPOTAR_INVAL_IMG_SIZE:
            message = "Invalid image size"
        case .SPOTAR_INVAL_PRODUCT_HDR:
            message = "Invalid product header"
        case .SPOTAR_SAME_IMG_ERR:
            message = "Same Image Error"
        case .SPOTAR_EXT_MEM_READ_ERR:
            message = "Failed to read from external memory device"

        }

        print(message)
    }

}

// MARK: XYBluetoothDeviceNotifyDelegate
extension XYFirmwareUpdateManager: XYBluetoothDeviceNotifyDelegate {

    public func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        guard let characteristic = serviceCharacteristic as? OtaService else { return }
        self.processValue(for: characteristic, value: value)
    }

}
