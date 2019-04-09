//  RoundMapView.swift
//  myUber
//  Created by MOAMEN on 11/23/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import MapKit

class RoundMapView: MKMapView {

    override func layoutSubviews() {
     
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }

}
