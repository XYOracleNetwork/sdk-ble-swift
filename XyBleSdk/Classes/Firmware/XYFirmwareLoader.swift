//
//  XYFirmwareLoader.swift
//  Pods-XyBleSdk_Example
//
//  Created by Darren Sutherland on 11/27/18.
//

import Foundation

class XYFirmwareLoader {

    class func locateFirmware() -> [String] {

        let publicDocumentsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: publicDocumentsDir) as [NSString] else { return [] }

        // TODO de-uglify this using NSURL
        let imgFiles = files.filter {
            $0.pathExtension.compare("bin", options: .caseInsensitive) == .orderedSame ||
            $0.pathExtension.compare("ing", options: .caseInsensitive) == .orderedSame
        }.compactMap { (publicDocumentsDir as NSString).appendingPathComponent($0 as String) }

        return imgFiles
    }

    class func locateFirmware2() {
        // Get the document directory url
        guard let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)

            // if you want to filter the directory contents you can do like this:
            let mp3Files = directoryContents.filter{ $0.pathExtension == "img" }
            print("img urls:",mp3Files)
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            print("img list:", mp3FileNames)
        } catch {
            print(error.localizedDescription)
        }
    }

}
