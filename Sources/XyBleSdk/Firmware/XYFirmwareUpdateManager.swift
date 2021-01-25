//
//  XYFirmwareUpdateManager.swift
//  XYSdk
//
//  Created by Darren Sutherland on 9/6/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//
//  Ported from Dialog Obj-C SPOTA Demo

import Foundation

public struct XYFirmwareUpdateParameters {
    let
    spiMISOAddress: Int32,
    spiMOSIAddress: Int32,
    spiCSAddress: Int32,
    spiSCKAddress: Int32,
    patchBaseAddress: Int32,
    shouldReconnect: Bool,
    rebootNoConfirm: Bool,
    disconnectOnComplete: Bool

    public static var xy4: XYFirmwareUpdateParameters {
        return XYFirmwareUpdateParameters(
            spiMISOAddress: 0x05,
            spiMOSIAddress: 0x06,
            spiCSAddress: 0x07,
            spiSCKAddress: 0x00,
            patchBaseAddress: 0,
            shouldReconnect: true,
            rebootNoConfirm: false,
            disconnectOnComplete: false)
    }

    public static func convertXy4ToSentinel(bank: Int32) -> XYFirmwareUpdateParameters {
        return XYFirmwareUpdateParameters(
            spiMISOAddress: 0x05,
            spiMOSIAddress: 0x06,
            spiCSAddress: 0x07,
            spiSCKAddress: 0x00,
            patchBaseAddress: bank,
            shouldReconnect: false,
            rebootNoConfirm: false,
            disconnectOnComplete: false)
    }

    public static func updateSentinelX(bank: Int32) -> XYFirmwareUpdateParameters {
        return XYFirmwareUpdateParameters(
            spiMISOAddress: 0x05,
            spiMOSIAddress: 0x06,
            spiCSAddress: 0x07,
            spiSCKAddress: 0x00,
            patchBaseAddress: bank,
            shouldReconnect: false,
            rebootNoConfirm: true,
            disconnectOnComplete: false)
    }

    public static func fixSentinelX(bank: Int32) -> XYFirmwareUpdateParameters {
        return XYFirmwareUpdateParameters(
            spiMISOAddress: 0x05,
            spiMOSIAddress: 0x06,
            spiCSAddress: 0x07,
            spiSCKAddress: 0x00,
            patchBaseAddress: bank,
            shouldReconnect: false,
            rebootNoConfirm: true,
            disconnectOnComplete: true)
    }
}

public protocol XYFirmwareUpdateManagerProgressDelegate: class {
    func progressUpdated(value: Float, offset: Int32, count: Int32)
    func disconnected()
    func rebootStarted()
}

public class XYFirmwareUpdateManager {

    public enum UpdateMemoryType: Int32 {
        case SUOTA_I2C = 0x12
        case SUOTA_SPI = 0x13
        case SPOTA_SYSTEM_RAM = 0x00
        case SPOTA_RETENTION_RAM = 0x01
        case SPOTA_I2C = 0x02
        case SPOTA_SPI = 0x03
    }

    fileprivate let
    device: XYBluetoothDevice

    fileprivate var
    firmwareData: Data

    fileprivate let notifyKey = "XYFirmwareUpdateManager"

    fileprivate var subscribeKey: UUID?

    fileprivate var
    currentStep: XYFirmwareUpdateStep = .unstarted,
    nextStep: XYFirmwareUpdateStep = .unstarted

    fileprivate let
    chunkSize: Int32 = 20

    fileprivate var
    blockSize: Int32 = 128,
    blockStartByte: Int32 = 0,
    patchBaseAddress: Int32 = 0,
    expectedValue: Int = 0

    fileprivate let parameters: XYFirmwareUpdateParameters

    fileprivate weak var delegate: XYFirmwareUpdateManagerProgressDelegate?

    fileprivate var
    success: (() -> Void)?,
    failure: ((_ error: XYBluetoothError) -> Void)?

    let memoryType: XYFirmwareUpdateManager.UpdateMemoryType = .SUOTA_SPI

    public init(for device: XYBluetoothDevice, parameters: XYFirmwareUpdateParameters, firmwareData: Data, delegate: XYFirmwareUpdateManagerProgressDelegate? = nil) {
        self.device = device
        self.parameters = parameters
        self.firmwareData = firmwareData
        self.delegate = delegate
        self.patchBaseAddress = parameters.patchBaseAddress
    }

    public func cancel() {
        self.nextStep = .unstarted
        self.currentStep = .unstarted
    }

    private func disconnect() {
        XYCentral.instance.disconnect(from: self.device)
        self.device.detachPeripheral()
    }

    private func cleanup() {
        print("- FIRMWARE Step SUCCESS: \(XYFirmwareUpdateStep.completed.rawValue)")
        XYFinderDeviceEventManager.unsubscribe(to: [.disconnected, .connected], referenceKey: self.subscribeKey)
        if self.parameters.disconnectOnComplete {
//            self.disconnect()
        }
        self.success?()
    }

    public func update(_ success: @escaping () -> Void, failure: @escaping (_ error: XYBluetoothError) -> Void) {
        self.success = success
        self.failure = failure

        // Watch for various events to properly handle the OTA
        self.subscribeKey = XYFinderDeviceEventManager.subscribe(to: [.disconnected, .connected], for: self.device) { event in
            switch event {
            case .disconnected where self.currentStep == .completed:
                // The finder disconnects once it reboots, so we catch that and reconnect if requested
                if self.parameters.shouldReconnect {
                    self.completeUpdate()
                } else {
                    // We don't need to reconnect, so remove, cleanup and return success
                    self.disconnect()
                    self.cleanup()
                }
            case .disconnected where self.currentStep != .completed:
                // The update bombed out at some point, so remove the peripheral and let the user know to retry
                XYCentral.instance.disconnect(from: self.device)
                self.device.detachPeripheral()
                self.delegate?.disconnected()
            case .connected:
                // All done, so unsubscribe from the ota service and the events, and then return success
                self.device.connection {
                    _ = self.device.unsubscribe(from: OtaService.servStatus, key: self.notifyKey)

                    // If we're a finder, put us awake
                    if let device = self.device as? XYFinderDevice {
                        for _ in 1...10 {
                            if device.stayAwake().hasError == false {
                                break
                            }
                        }
                    }
                }.always {
                    self.cleanup()
                }

            default:
                break
            }
        }

        self.device.updatingFirmware(true)

        // Set notifications on for the update service
        self.device.connection {
            if self.device.subscribe(to: OtaService.servStatus, delegate: (key: self.notifyKey, delegate: self)).hasError {
                self.device.updatingFirmware(false)
                self.failure?(XYBluetoothError.unableToUpdateFirmware)
            } else {
                self.currentStep = .setMemoryType
                self.doStep()
            }
        }.catch { error in
            self.failure?(XYBluetoothError.timedOut)
        }
    }

    fileprivate func completeUpdate() {
        self.delegate?.rebootStarted()

        // Remove the device and the peripheral in order to reconnect
        XYDeviceConnectionManager.instance.remove(device: self.device)
        self.device.connect()
    }
}

// MARK: Multi-step updater
private extension XYFirmwareUpdateManager {

    enum XYFirmwareUpdateStep: String {
        case unstarted
        case setMemoryType
        case setMemoryParameters
        case processFirmwareData
        case setPatchLength
        case sendPatch
        case completePatch
        case rebootDevice
        case completed
    }

    func doStep() {
        switch self.currentStep {
        case .unstarted:
            break
        case .setMemoryType:
            currentStep = .unstarted
            expectedValue = XYFirmwareStatusValues.SPOTAR_IMG_STARTED.rawValue
            nextStep = .setMemoryParameters

            // Set the memory type. This will write the value, which will trigger the notification in readValue() below
            var memDevData: Int32 = (self.memoryType.rawValue << 24) | (self.patchBaseAddress & 0xFF)
            let data = NSData(bytes: &memDevData, length: MemoryLayout<Int32>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            print("- FIRMWARE Step: \(XYFirmwareUpdateStep.setMemoryType.rawValue) - Value is \(parameter.asInteger ?? -1)")

            self.writeValue(to: .memDev, value: parameter)

        case .setMemoryParameters:
            // NOTE: Only supporting SUOTA_SPI for now, and SPOTA_SYSTEM_RAM for upgrade
            if self.memoryType == UpdateMemoryType.SUOTA_SPI {
                var memInfoData: Int32 =
                    (self.parameters.spiMISOAddress << 24) |
                    (self.parameters.spiMOSIAddress << 16) |
                    (self.parameters.spiCSAddress << 8) |
                    self.parameters.spiSCKAddress

                let data = NSData(bytes: &memInfoData, length: MemoryLayout<Int32>.size)
                let parameter = XYBluetoothResult(data: Data(referencing: data))

                print("- FIRMWARE Step: \(XYFirmwareUpdateStep.setMemoryParameters.rawValue) - Value is \(parameter.asInteger ?? -1)")

                self.currentStep = .processFirmwareData
                self.writeValue(to: .gpioMap, value: parameter)
            }

        case .processFirmwareData:
            // Append checksum and move on as we have the chunk and block size preset for the XY4
            self.appendChecksum()
            self.currentStep = .setPatchLength
            self.doStep()

        case .setPatchLength:
            let data = NSData(bytes: &blockSize, length: MemoryLayout<UInt16>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            print("- FIRMWARE Step: \(XYFirmwareUpdateStep.setPatchLength.rawValue) - Value is \(blockSize)")

            self.currentStep = .sendPatch
            self.writeValue(to: .patchLen, value: parameter)

        case .sendPatch:
            if blockStartByte == 0 {
                print("- FIRMWARE Step: \(XYFirmwareUpdateStep.sendPatch.rawValue) - Starting...")
            }

            self.currentStep = .unstarted
            self.expectedValue = XYFirmwareStatusValues.SPOTAR_CMP_OK.rawValue
            self.nextStep = .sendPatch

            let dataLength: Int32 = Int32(firmwareData.count)
            var chunkStartByte: Int32 = 0

            var chunkedUpdate = [XYBluetoothResult]()

            while chunkStartByte < self.blockSize {
                // Check if we have less than current block-size bytes remaining
                let bytesRemaining: Int32 = blockSize - chunkStartByte
                let currChunkSize: Int32  = bytesRemaining >= self.chunkSize ? self.chunkSize : bytesRemaining

                print("- FIRMWARE Step: \(XYFirmwareUpdateStep.sendPatch.rawValue) - Sending bytes \(blockStartByte + chunkStartByte + 1) to \(blockStartByte + chunkStartByte + currChunkSize) (\(chunkStartByte + currChunkSize)/\(blockSize)) of \(dataLength)")

                // Calcuate progress for display
                let progress: Float = Float(blockStartByte + chunkStartByte + currChunkSize) / Float(dataLength)
                self.delegate?.progressUpdated(value: progress, offset: (blockStartByte + chunkStartByte + 1), count: dataLength)

                // Create an empty buffer of the current chunk size of bytes
                var payload = [UInt8](repeating: 0, count: Int(currChunkSize))

                // Create a range to capture the size of the current cunk
                let range = NSMakeRange(Int(self.blockStartByte + chunkStartByte), Int(currChunkSize))

                // Copy the range bytes to the payload pointer and add to the update array
                self.firmwareData.copyBytes(to: &payload, from: Range(range)!)
                chunkedUpdate.append(XYBluetoothResult(data: Data(payload)))

                // On to the chunk
                chunkStartByte += currChunkSize

                // Check if we are passing the current block
                if chunkStartByte >= self.blockSize {
                    // Prepare for next block
                    self.blockStartByte += self.blockSize

                    let bytesRemaining = dataLength - blockStartByte
                    if bytesRemaining == 0 {
                        nextStep = .completePatch
                    } else if bytesRemaining < blockSize {
                        blockSize = bytesRemaining
                        nextStep = .setPatchLength
                    }
                }
            }

            // Write out the patch chunks in one connection
            self.writeFirmware(to: .patchData, values: chunkedUpdate)

        case .completePatch:
            self.currentStep = .unstarted
            self.expectedValue = XYFirmwareStatusValues.SPOTAR_CMP_OK.rawValue
            self.nextStep = .rebootDevice

            print("- FIRMWARE Step: \(XYFirmwareUpdateStep.completePatch.rawValue)")

            var suotaEnd: UInt32 = 0xFE000000
            let data = NSData(bytes: &suotaEnd, length: MemoryLayout<UInt32>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            self.writeValue(to: .memDev, value: parameter)

        case .rebootDevice:
            self.currentStep = .completed

            print("- FIRMWARE Step: \(XYFirmwareUpdateStep.rebootDevice.rawValue)")

            var suotaEnd: UInt32 = 0xFD000000
            let data = NSData(bytes: &suotaEnd, length: MemoryLayout<UInt32>.size)
            let parameter = XYBluetoothResult(data: Data(referencing: data))

            self.writeValue(to: .memDev, value: parameter)

            // We never get a reboot response from a Sentinel X reboot, so inform
            // the delegate we are all done so they can "reboot"
            if self.parameters.rebootNoConfirm {
                self.cleanup()
            }

        case .completed:
            break

        }
    }

    func appendChecksum() {
        var crcCode: UInt8 = 0
        [UInt8](self.firmwareData).forEach { crcCode ^= $0 }
        print("- FIRMWARE appendChecksum - Value: \(crcCode)")
        self.firmwareData.append(&crcCode, count: MemoryLayout<UInt8>.size)
    }

}

// MARK: Read and write values to the device, as well as process any response
private extension XYFirmwareUpdateManager {

    // Used for bulk udpating with no response needed
    func writeFirmware(to service: OtaService, values: [XYBluetoothResult]) {
        self.device.connection {
            values.forEach { _ = self.device.set(service, value: $0, timeout: .seconds(15), withResponse: false) }
        }.then {
            self.doStep()
        }.catch { error in
            print((error as? XYBluetoothError)?.toString ?? "<unknown>")
        }
    }

    func writeValue(to service: OtaService, value: XYBluetoothResult) {
        self.device.connection {
            let result = self.device.set(service, value: value)
            if result.hasError == false {
                self.doStep()
            } else {
                print(result.error?.toString ?? "<unknown>")
            }
        }.catch { error in
            self.failure?(error as? XYBluetoothError ?? XYBluetoothError.cbPeripheralDelegateError(error))
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

    // Handler for the notification callback for the service status
    func processValue(for serviceCharacteristic: OtaService, value: XYBluetoothResult) {
        guard
            serviceCharacteristic == .servStatus,
            let data = value.asInteger else { return }

        // Debug output
        let message = self.handleResponse(for: data)
        print(message)

        // If the service gives us a good response, reset expected and do the next step
        if self.expectedValue != 0, data == self.expectedValue {
            self.currentStep = self.nextStep
            expectedValue = 0
            self.doStep()
        } else {
            self.device.updatingFirmware(false)
            if data == XYFirmwareStatusValues.SPOTAR_SAME_IMG_ERR.rawValue {
                self.failure?(XYBluetoothError.sameImage)
            } else {
                self.failure?(XYBluetoothError.unableToUpdateFirmware)
            }
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

    @discardableResult func handleResponse(for responseValue: Int) -> String {
        var message: String

        guard let errorEnum = XYFirmwareStatusValues(rawValue: responseValue) else {
            return "Unhandled status code \(responseValue)"
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

        return message
    }

}

// MARK: XYBluetoothDeviceNotifyDelegate
extension XYFirmwareUpdateManager: XYBluetoothDeviceNotifyDelegate {

    public func update(for serviceCharacteristic: XYServiceCharacteristic, value: XYBluetoothResult) {
        guard let characteristic = serviceCharacteristic as? OtaService else { return }
        self.processValue(for: characteristic, value: value)
    }

}
