//  PassengerAnnotation.swift
//  myUber
//  Created by MOAMEN on 11/21/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation{
    
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
