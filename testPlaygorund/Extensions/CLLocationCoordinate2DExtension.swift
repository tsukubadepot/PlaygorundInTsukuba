//
//  CLLocationCoordinate2DExtension.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import MapKit

extension CLLocationCoordinate2D {
    func near(to: CLLocationCoordinate2D, delta: CLLocationDegrees) -> Bool {
        return fabs(self.latitude - to.latitude) < delta && fabs(self.longitude - to.longitude) < delta
    }
}
