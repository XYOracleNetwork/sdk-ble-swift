//
//  XYFirmwareLoader.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 11/27/18.
//

import Foundation

public class XYFirmwareLoader {

    public class func locateFirmware() -> [URL] {
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

}
