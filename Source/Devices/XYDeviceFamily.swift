//
//  XYDeviceFamily.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XYDeviceFamily {
    static var famlies = [String : XYDeviceFamily]()
    
    let uuid : UUID
    let prefix : String
    let familyName : String
    let id : String
    
    init(uuid: UUID, prefix : String, familyName : String, id : String) {
        self.uuid = uuid
        self.prefix = prefix
        self.familyName = familyName
        self.id = id
    }
    
    public static func allFamlies () -> [XYDeviceFamily] {
        return famlies.values.map {
            $0
        }
    }
    
    public static func build(iBeacon : XYIBeaconDefinition) -> XYDeviceFamily? {
        return XYDeviceFamily.famlies[iBeacon.uuid.uuidString.lowercased()]
    }
}
