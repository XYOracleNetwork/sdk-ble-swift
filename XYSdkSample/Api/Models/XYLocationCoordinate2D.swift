//
//  XYLocationCoordinate2D.swift
//  XYSdk
//
//  Created by Arie Trouw on 4/20/17.
//  Copyright © 2017 XY - The Findables Company. All rights reserved.
//

import CoreLocation

public class XYLocationCoordinate2D {
    public var latitude : Double = 0
    public var longitude : Double = 0
    public var horizontalAccuracy : Double = 0
    public var verticalAccuracy : Double = 0

    public init(_ location: CLLocation) {
        self.longitude = location.coordinate.longitude
        self.latitude = location.coordinate.latitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
    }
}
