// DriverAnnotation.swift
//  myUber
//  Created by MOAMEN on 11/13/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import Foundation
import MapKit

class DriverAnnotation: NSObject, MKAnnotation{
    
   dynamic var coordinate: CLLocationCoordinate2D // user coordinate that store last time in firebase
    var key: String // current user uid from firebase
    
    // init user uid and coordinate from firebase
    init(coordinate: CLLocationCoordinate2D, withKey key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
    
    func updateCurrentAnnotation(annotationPositionn annotation: DriverAnnotation, withCoordinate coordinate : CLLocationCoordinate2D) {
        
        var location = self.coordinate
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        UIView.animate(withDuration: 0.2) {
            self.coordinate = location
        }
    }
    
    
    
}

