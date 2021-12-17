//
//  CLLocationExtension.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/12/16.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import MapKit

// https://stackoverflow.com/questions/11077425/finding-distance-between-cllocationcoordinate2d-points
extension CLLocation {
    /// Get distance between two points
    ///
    /// - Parameters:
    ///   - from: first point
    ///   - to: second point
    /// - Returns: the distance in meters
    class func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
}
