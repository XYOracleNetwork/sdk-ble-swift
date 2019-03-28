//
//  XYFirmwareLoader.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 11/27/18.
//

import Foundation

public class XYFirmwareLoader {

    public class func locateDocumentsFirmware() -> [URL] {
        // Get the document directory url
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }

        var firmwareUrls = [URL]()

        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            firmwareUrls = directoryContents.filter { $0.pathExtension == "img" || $0.pathExtension == "bin" }
        } catch {
            print(error.localizedDescription)
        }

        return firmwareUrls
    }

    public class func locateBundleFirmware(for fileName: String, type: String) -> URL? {
        let path: String? = Bundle.main.path(forResource: fileName, ofType: type)
        return URL.init(fileURLWithPath: path!)
    }

    public class func getFirmwareData(from url: URL) -> Data? {
        return try? Data(contentsOf: url)
    }

    public class func getFirmwareData(for versionData: XYRemoteVersionData, success: @escaping (Data?) -> Void, error: @escaping (Error?) -> Void, progress: @escaping (Float) -> Void) {
        guard let loader = XYFirmwareRemoteLoader(path: versionData.path) else {
            error(XYBluetoothError.unableToUpdateFirmware)
            return
        }

        loader.download(success: success, error: error, progress: progress)
    }

}

// MARK: Wraps the remote version JSON data
public struct XYRemoteVersionData: Decodable {
    public var version: String, path: String
}

public struct XYRemoteVersionData2: Decodable {
    struct SentinelX: Decodable {
        var version: String, path: String, type: String, bank: Int
    }

    struct Firmware: Decodable {
        public var version: String, path: String, type: String, priority: Int, bank: Int
    }

    struct Xy4: Decodable {
        var firmware: [Firmware]
    }

    var sentinelX: SentinelX
    var xy4: Xy4
}

// MARK: Fetches the version JSON and the path to the firmware
public class XYFirmwareRemoteVersionLoader {

    public init?(family: XYDeviceFamily) {
        guard family.id == XY4BluetoothDevice.id else { return nil }
    }

    public func get(from path: String = "https://s3.amazonaws.com/xyfirmware.xyo.network/sentinelx/version.json") -> XYRemoteVersionData? {
        guard
            let url = URL(string: path),
            let versionData = self.loadJson(from: url) else {
                return nil
            }

        return versionData
    }

    private func loadJson(from url: URL) -> XYRemoteVersionData? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(XYRemoteVersionData.self, from: data)
            return jsonData
        } catch {}

        return nil
    }

}

// MARK: Fetches the version JSON and the path to the firmware
public class XYSentinelFirmwareRemoteVersionLoader {

    public class func get(from path: String = "https://s3.amazonaws.com/xyfirmware.xyo.network/sentinelx/version.json") -> XYRemoteVersionData2? {
        guard
            let url = URL(string: path),
            let versionData = self.loadJson(from: url) else {
                return nil
        }

        return versionData
    }

    private class func loadJson(from url: URL) -> XYRemoteVersionData2? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode(XYRemoteVersionData2.self, from: data)
            return jsonData
        } catch {}

        return nil
    }

}

// MARK: Used for grabbing the binary firmware from a remote server, allows for background download
internal class XYFirmwareRemoteLoader: NSObject, URLSessionDownloadDelegate {

    private let url: URL
    private var backgroundSession: URLSession?

    private var
    success: ((Data?) -> Void)?,
    error: ((Error?) -> Void)?,
    progress: ((Float) -> Void)?

    init?(path: String) {
        guard let url = URL(string: path) else { return nil }
        self.url = url
        super.init()
    }

    func download(success: @escaping (Data?) -> Void, error: @escaping (Error?) -> Void, progress: @escaping (Float) -> Void) {
        self.success = success
        self.error = error
        self.progress = progress
        
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: self.url.absoluteString)
        self.backgroundSession = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        guard let task = self.backgroundSession?.downloadTask(with: self.url) else {
            self.backgroundSession?.finishTasksAndInvalidate()
            self.error?(XYBluetoothError.unableToUpdateFirmware)
            return
        }
        task.resume()
    }

    // Download is done
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let data = try? Data(contentsOf: location)
        self.backgroundSession?.finishTasksAndInvalidate()
        self.success?(data)
    }

    // Download is in progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.progress?(progress)
    }

    // Something bad happened
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.backgroundSession?.finishTasksAndInvalidate()
        self.error?(error)
    }

}
