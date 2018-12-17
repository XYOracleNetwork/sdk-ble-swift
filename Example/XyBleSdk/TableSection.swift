//
//  TableSection.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/4/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XyBleSdk

enum TableSection: Int {
    case xy1 = 0, xy2, xy3, xy4, xyMobile, xyGps

    var title: String {
        switch self {
        case .xy1: return XYFinderDeviceFamily.xy1.familyName
        case .xy2: return XYFinderDeviceFamily.xy2.familyName
        case .xy3: return XYFinderDeviceFamily.xy3.familyName
        case .xy4: return XYFinderDeviceFamily.xy4.familyName
        case .xyMobile: return XYFinderDeviceFamily.xymobile.familyName
        case .xyGps: return XYFinderDeviceFamily.xygps.familyName
        }
    }

    static let values = [xy1, xy2, xy3, xy4, xyMobile, xyGps]
}

extension XYFinderDeviceFamily {

    var toTableSection: TableSection? {
        switch self {
        case .xy1: return TableSection.xy1
        case .xy2: return TableSection.xy2
        case .xy3: return TableSection.xy3
        case .xy4: return TableSection.xy4
        case .xymobile: return TableSection.xy1
        case .xygps: return TableSection.xyGps
        default: return nil
        }
    }
}
