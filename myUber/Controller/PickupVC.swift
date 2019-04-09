//  PickupVC.swift
//  myUber
//  Created by MOAMEN on 11/23/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import MapKit
import Firebase

class PickupVC: UIViewController {
    
    var currentUserId = Auth.auth().currentUser?.uid
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    var locationPlacemark:MKPlacemark!
    @IBOutlet weak var pickupMapView: RoundMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickupMapView.delegate = self
        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        DataService.instance.trips_Reference.child(passengerKey).observe(.value) { (tripSnapshot) in
            if tripSnapshot.exists() { // if trip is still exists
                if tripSnapshot.childSnapshot(forPath: TRIP_IS_ACCEPTED).value as? Bool == true { // if another driver accept user trip dismiss all drivers for accept user trip
                    self.dismiss(animated: true, completion: nil)
                }
            }else{ //if user cancel trip dismiss driver accept controller
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String)  {
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func acceptTripButton(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentingViewController?.shouldPresentLoadingView(true)
    }
    
}

extension PickupVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else{
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinFor(placemark:MKPlacemark) {
        
        pin = placemark
        // remove all annotation from map first than add it into map
        for annotation in pickupMapView.annotations {
            pickupMapView.removeAnnotation(annotation)
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        pickupMapView.addAnnotation(annotation)
        
    }
    
}


