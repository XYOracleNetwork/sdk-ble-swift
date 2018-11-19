//
//  XYGeocode.swift
//  Bolts
//
//  Created by Darren Sutherland on 10/17/18.
//

import CoreLocation

public class XYGeocode {

    private static let geocoder = CLGeocoder()

    public class func geocodeLocation(latitude: Float, longitude: Float, callback: ((String?) -> Void)? = nil) {
        let location = CLLocation(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemarks = placemarks, placemarks.count > 0 {
                callback?(placemarks[0].name)
            } else {
                callback?(nil)
            }
        }
    }

}
