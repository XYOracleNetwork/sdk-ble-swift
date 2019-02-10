//
//  XYDeviceFamily.swift
//  Pods-SampleiOS
//
//  Created by Carter Harrison on 2/4/19.
//

import Foundation

public struct XYDeviceFamily {
    static var famlies = [String : XYDeviceFamily]()
    
    public let uuid : UUID
    public let prefix : String
    public let familyName : String
    public let id : String
    
    public init(uuid: UUID, prefix : String, familyName : String, id : String) {
        self.uuid = uuid
        self.prefix = prefix
        self.familyName = familyName
        self.id = id
    }
    
    public func enable (enable : Bool) {
        if (enable) {
             XYDeviceFamily.famlies[self.uuid.uuidString.lowercased()] = self
        } else {
            XYDeviceFamily.famlies.removeValue(forKey: self.uuid.uuidString.lowercased())
        }
    }
    
    public func diable () {
        XYDeviceFamily.famlies.removeValue(forKey: self.uuid.uuidString.lowercased())
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
