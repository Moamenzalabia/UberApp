//  ViewController.swift
//  myUber
//  Created by MOAMEN on 11/8/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView
import Firebase

enum AnnotationType {
    case pickup
    case destination
}

enum ButtonAction {
    case requestRide
    case getDirectionsToPassenger
    case getDirectionsToDestination
    case startTrip
    case endTrip
}

class HomeVC: UIViewController, Alertable {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var userImageView: CustomImageView!
    @IBOutlet weak var destionationCircle: CircleView!
    @IBOutlet weak var destionationTextField: UITextField!
    @IBOutlet weak var requestButton: RoundedShadowButton!
    @IBOutlet weak var centerMapButton: UIButton!
    @IBOutlet weak var cancelButton: CustomCornerButton!
    
    var delegate: CenterVCDelegate?
    
    var locationManager: CLLocationManager?
    
    var currentUserId = Auth.auth().currentUser?.uid
    
    var regionRadius: CLLocationDistance = 1000
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "launchScreenIcon")!, iconInitialSize: CGSize(width: 100, height: 100), backgroundColor: UIColor.white)// splashScreen anmitions
    var tableview = UITableView()
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var route: MKRoute!
    var selectedItemPlacemark: MKPlacemark? = nil
    
    var actionForButton: ButtonAction = .requestRide
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAuthStatus()
        
        mapView.delegate = self
        destionationTextField.delegate = self
        
        observePassengerAndDrivers()
        centerMapOnUserLocation()
        
        DataService.instance.drivers_Reference.observe(.value) { (snapshot) in
            self.loadDriverAnnotationFromFirebase()
            
            DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId ?? "") { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            }
        }
        
        cancelButton.alpha = 0.0
        
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict{
                let pickupCoordinateArray = tripDict[USER_PICKUP_COORDINATE] as! NSArray
                let tripKey = tripDict[USER_PASSENGER_KEY] as! String
                let acceptanceStatus = tripDict[TRIP_IS_ACCEPTED] as! Bool
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: self.currentUserId!, handler: { (available) in
                        if let available = available {
                            if available == true {
                                let storyboard = UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: VC_PICKUP) as? PickupVC
                                pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                self.present(pickupVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if currentUserId != nil {
            DataService.instance.userIsDrivr(userKey: currentUserId!) { (status) in
                if status == true {
                    self.buttonForDriver(areHidden: true)
                }
            }
        }
        
        DataService.instance.trips_Reference.observe(.childRemoved) { (removedTripSnapshot) in
            let removedTripDict = removedTripSnapshot.value as? [String: AnyObject]
            if  removedTripDict?[DRIVER_KEY] != nil{
                DataService.instance.drivers_Reference.child(removedTripDict?[DRIVER_KEY] as! String).updateChildValues([DRIVER_IS_ON_TRIP: false])
            }
            
            DataService.instance.userIsDrivr(userKey: self.currentUserId!, handler: { (isDriver) in
                if isDriver == true{
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                }else{
                    self.cancelButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.requestButton.animateButton(shouldLoad: false, withMessage: MSG_REQUEST_RIDE)
                    
                    self.destionationTextField.isUserInteractionEnabled = true
                    self.destionationTextField.text = ""
                    
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                    self.centerMapOnUserLocation()
                }
            })
        }
        
        if currentUserId != nil {
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
                if isOnTrip ==  true{
                    DataService.instance.trips_Reference.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: DRIVER_KEY).value as? String == self.currentUserId! {
                                    let pickupCoordinateArray = trip.childSnapshot(forPath: USER_PICKUP_COORDINATE).value as! NSArray
                                    let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                    let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                    
                                    self.dropPinFor(placemark: pickupPlacemark)
                                    self.searchMapKitResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                                    
                                    self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                                    
                                    self.actionForButton = .getDirectionsToPassenger
                                    self.requestButton.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                                    
                                    self.buttonForDriver(areHidden: false)
                                }
                            }
                        }
                    })
                }
            }
            connectUserAndDriverForTrip()
        }
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        }else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func buttonForDriver(areHidden: Bool) {
        if areHidden {
            self.requestButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.cancelButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.centerMapButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.requestButton.isHidden = true
            self.cancelButton.isHidden = true
            self.centerMapButton.isHidden = true
        }else{
            self.requestButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.cancelButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.centerMapButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.requestButton.isHidden = false
            self.cancelButton.isHidden = false
            self.centerMapButton.isHidden = false
        }
    }
    
    // download passenger and driver image
    func observePassengerAndDrivers(){
        DataService.instance.users_Reference.observeSingleEvent(of: .value , with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            userDictionary.forEach({ (key, value) in
                if key == Auth.auth().currentUser?.uid {
                    guard let valueDictionary = value as? [String: Any] else { return }
                    guard let userImageURL = valueDictionary["userImage"] as? String else{ return }
                    self.userImageView.loadImage(urlString: userImageURL)
                }
            })
        }) { (error) in
            self.showAlert("Failed to fetch following user Ids:\(error.localizedDescription)", status: false)
        }
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        guard let valueDictionary = snap.value as? [String: Any] else { return }
                        guard let driverImageURL = valueDictionary["driverImage"] as? String else{ return }
                        self.userImageView.loadImage(urlString: driverImageURL)
                    }
                }
            }
        }
    }
    
    func loadDriverAnnotationFromFirebase() {
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.hasChild(COORDINATE){
                        //pickupModeSwitch is on add annotation from type DriverAnnotation ron map with current driver coordinate
                        if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool == true{
                            if let  driverDict = driver.value as? Dictionary <String, AnyObject> {
                                let coordinateArray = driverDict[COORDINATE] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                
                                let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                
                                var driverVisible: Bool { //to update driver annotation when he move on map
                                    return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation{
                                            if driverAnnotation.key == driver.key {
                                                driverAnnotation.updateCurrentAnnotation(annotationPositionn: driverAnnotation, withCoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    })
                                }
                                
                                if !driverVisible {
                                    self.mapView.addAnnotation(annotation)
                                }
                            }
                        }else {//pickupModeSwitch is off for all annotation from type DriverAnnotation remove it from map Annotations
                            for annotation in self.mapView.annotations {
                                if annotation.isKind(of: DriverAnnotation.self){
                                    if let annotation = annotation as? DriverAnnotation {
                                        if annotation.key == driver.key{
                                            self.mapView.removeAnnotation(annotation)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        revealingSplashView.heartAttack = true // to stop animation
    }
    
    func connectUserAndDriverForTrip() {
        DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                
                DataService.instance.trips_Reference.child(tripKey!).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                    let driverId = tripDict?[DRIVER_KEY] as! String
                    
                    let pickupCoordinateArray = tripDict?[USER_PICKUP_COORDINATE] as! NSArray
                    let pickupCoordinate = CLLocationCoordinate2DMake(pickupCoordinateArray[0] as! CLLocationDegrees, pickupCoordinateArray[1] as! CLLocationDegrees)
                    let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                    let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                    DataService.instance.drivers_Reference.child(driverId).child(COORDINATE).observeSingleEvent(of: .value, with: { (coordinateSnapshot) in
                        let coordinateSnapshot = coordinateSnapshot.value as! NSArray
                        let driverCoordinate = CLLocationCoordinate2DMake(coordinateSnapshot[0] as! CLLocationDegrees, coordinateSnapshot[1] as! CLLocationDegrees)
                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                        let driverMapItem = MKMapItem(placemark: driverPlacemark)
                        
                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: self.currentUserId!)
                        self.mapView.addAnnotation(passengerAnnotation)
                        
                        self.searchMapKitResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                        self.requestButton.animateButton(shouldLoad: false, withMessage: MSG_DRIVER_COMING)
                        self.requestButton.isUserInteractionEnabled = false
                    })
                    DataService.instance.trips_Reference.child(tripKey!).observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if tripDict?[TRIP_IN_PROGRESS] as? Bool == true {
                            self.removeOverlaysAndAnnotations(forDrivers: true, forPassengers: true)
                            
                            let destinationCoordinateArray = tripDict?[USER_DESTINATION_COORDINATE] as! NSArray
                            let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                            
                            self.dropPinFor(placemark: destinationPlacemark)
                            self.searchMapKitResultsWithPolyline(forOriginMapItem: pickupMapItem, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                            
                            self.requestButton.setTitle(MSG_ON_TRIP, for: .normal)
                        }
                    })
                })
            }
        }
    }
    
    func centerMapOnUserLocation() { // to center map to first point after any update on map
        let coordinateRegion = MKCoordinateRegion.init(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    @IBAction func requestActionButton(_ sender: Any) {
        buttonSelector(forAction: actionForButton)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.cancelButton.setupButtonAnimation()
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true{
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey)
            }else {
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                self.centerMapOnUserLocation()
            }
        }
        self.requestButton.isUserInteractionEnabled = true
    }
    
    @IBAction func centerMapButton(_ sender: Any) {
        DataService.instance.users_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == self.currentUserId! {
                        if user.hasChild(TRIP_COORDINATE){
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centerMapButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                            
                        }else {
                            self.centerMapOnUserLocation()
                            self.centerMapButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func menuButton(_ sender: Any) {
        delegate?.toggleLeftPanel() // left side button
    }
    
    func buttonSelector(forAction action: ButtonAction) {
        switch action {
        case .requestRide:
            if destionationTextField.text != "" {
                UpdateService.instance.updateTripsWithCoordinatesUponRequest()
                requestButton.animateButton(shouldLoad: true, withMessage: nil)
                cancelButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
                self.view.endEditing(true)
                destionationTextField.isUserInteractionEnabled = false
            }
        case .getDirectionsToPassenger:
            DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.trips_Reference.child(tripKey!).observe(.value, with: { (tripSnapshot) in
                        let tripDict = tripSnapshot.value as? [String: AnyObject]
                        
                        let pickupCoordinateArray = tripDict?[USER_PICKUP_COORDINATE] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2DMake(pickupCoordinateArray[0] as! CLLocationDegrees, pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupMapItem = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate))
                        
                        pickupMapItem.name = MSG_PASSENGER_PICKUP
                        pickupMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            }
        case .startTrip:
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true{
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: false)
                    
                    DataService.instance.trips_Reference.child(tripKey!).updateChildValues([TRIP_IN_PROGRESS: true])
                    
                    DataService.instance.trips_Reference.child(tripKey!).child(USER_DESTINATION_COORDINATE).observeSingleEvent(of: .value, with: { (coordinateSnapshot) in
                        
                        let destinationCoordinateArray = coordinateSnapshot.value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2DMake(destinationCoordinateArray[0] as! CLLocationDegrees, destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        
                        self.dropPinFor(placemark: destinationPlacemark)
                        self.searchMapKitResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                        self.setCustomRegion(forAnnotationType: .destination, withCoordinate: destinationCoordinate)
                        
                        self.actionForButton = .getDirectionsToDestination
                        self.requestButton.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                    })
                }
            }
        case .getDirectionsToDestination:
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.trips_Reference.child(tripKey!).child(USER_DESTINATION_COORDINATE).observe(.value, with: { (snapshot) in
                        let destinationCoordinateArray = snapshot.value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2DMake(destinationCoordinateArray[0] as! CLLocationDegrees, destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        let destinationMapItem = MKMapItem(placemark: destinationPlacemark )
                        
                        destinationMapItem.name = MSG_PASSENGER_DESTINATION
                        destinationMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            }
        case .endTrip:
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
                    self.buttonForDriver(areHidden: true)
                }
            }
        }
    }
}

extension HomeVC: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //checkLocationAuthStatus()
        if  status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true{
                if region.identifier == REGION_PICKUP{
                    self.actionForButton = .startTrip
                    self.requestButton.setTitle(MSG_START_TRIP, for: .normal)
                }else if region.identifier == REGION_DESTINATION {
                    self.cancelButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.cancelButton.isHidden = true
                    self.actionForButton = .endTrip
                    self.requestButton.setTitle(MSG_END_TRIP, for: .normal)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true{
                if region.identifier == REGION_PICKUP {
                    self.actionForButton = .getDirectionsToPassenger
                    // call an action on the button that will load direction to passenger pickup
                    self.requestButton.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                }else if region.identifier == REGION_DESTINATION {
                    self.actionForButton = .getDirectionsToDestination
                    // call an action on the button that will load directions to destination
                    self.requestButton.setTitle(MSG_GET_DIRECTIONS, for: .normal)
                }
            }
        }
    }
}

extension HomeVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        
        if currentUserId != nil {
            DataService.instance.userIsDrivr(userKey: currentUserId!) { (isDriver) in
                if isDriver == true {
                    DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip == true {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        }else{
                            self.centerMapOnUserLocation()
                        }
                    })
                }else {
                    DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                        if isOnTrip == true {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                        }else{
                            self.centerMapOnUserLocation()
                        }
                    })
                }
            }
        }
    }
    
    // drow anntoations func
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: ANNO_DRIVER)
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: ANNO_PICKUP)
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: ANNO_DESTINATION)
            return annotationView
        }
        return nil
    }
    
    // to center map to defualt location
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    // delegate func to drow custom polyline in map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(polyline: self.route.polyline)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 3
        
        shouldPresentLoadingView(false)
        
        return lineRenderer
    }
    
    //search func if you search for any destioations location this func get search resualt and append it in an array of type mapItem and diplay it in tableview
    func performSearch(){
        matchingItems.removeAll()// clear array of search's location's before do any new search
        let request = MKLocalSearch.Request() // search request
        request.naturalLanguageQuery = destionationTextField.text  // search text
        request.region = mapView.region // search region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error != nil {
                self.showAlert(error!.localizedDescription, status: false)
            }else if response!.mapItems.count == 0 {
                self.showAlert("No results Please search again for a different location!", status: false)
            }else{
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableview.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
    }
    
    // to drpw a pin annotation for your selected search location
    func dropPinFor(placemark: MKPlacemark) {
        selectedItemPlacemark = placemark
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    // drow a line on map between your location and your search location
    func searchMapKitResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem ) {
        let request = MKDirections.Request()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        }else{
            request.source = originMapItem
        }
        
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile // transport type like car , train , wake, ....
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        
        direction.calculate { (response, error) in
            guard let response = response else{
                self.showAlert(error!.localizedDescription, status: false)
                return
            }
            self.route = response.routes[0]
            
            self.mapView.addOverlay(self.route!.polyline)
            
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
        }
    }
    
    // to zoom map at any update on it
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?){
        
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver {
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key{
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                }else{
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self){
            
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        let centervariable = CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5)
        
        let spanvariable = MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0) // latitude and longitude معدل التغير في ال
        
        var region = MKCoordinateRegion(center: centervariable, span: spanvariable)
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
        
    }
    
    // clean map
    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassengers: Bool?){
        
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDrivers! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline{
                mapView.removeOverlay(overlay)
            }
        }
    }
    
    // show if driver is arrive to passener or arrive to trip destionations
    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D) {
        if type == .pickup {
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: REGION_PICKUP)
            locationManager?.startMonitoring(for: pickupRegion)
        }else if type == .destination {
            let destinationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: REGION_DESTINATION)
            locationManager?.startMonitoring(for: destinationRegion)
        }
    }
}

extension HomeVC: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == destionationTextField{
            tableview.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 200)
            tableview.layer.cornerRadius = 5
            tableview.register(UITableViewCell.self, forCellReuseIdentifier: CELL_LOCATION)
            tableview.delegate = self
            tableview.dataSource = self
            tableview.tag = 18
            tableview.rowHeight = 60
            view.addSubview(tableview)
            animateTableView(shouldShow: true)
            UIView.animate(withDuration: 0.2) {
                self.destionationCircle.backgroundColor = UIColor.red
                self.destionationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destionationTextField {
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == destionationTextField {
            if destionationTextField.text == "" {
                UIView.animate(withDuration: 0.2) {
                    self.destionationCircle.backgroundColor = UIColor.lightGray
                    self.destionationCircle.borderColor = UIColor.darkGray
                }
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableview.reloadData()
        
        DataService.instance.users_Reference.child(currentUserId!).child(TRIP_COORDINATE).removeValue()
        
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations{
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }else if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        centerMapOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2) {
                self.tableview.frame = CGRect(x: 20, y: 200, width: self.view.frame.width - 40, height: self.view.frame.height - 200)
            }
        }else{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableview.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 200)
            }) { (finished) in
                for subview in self.view.subviews{
                    if subview.tag == 18{
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: CELL_LOCATION)
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        shouldPresentLoadingView(true)
        
        guard let passengerCoordinate = locationManager?.location?.coordinate else {return}
        
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, key: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        destionationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        
        DataService.instance.users_Reference.child(currentUserId!).updateChildValues([TRIP_COORDINATE: [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        dropPinFor(placemark: selectedMapItem.placemark)
        
        searchMapKitResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem )
        animateTableView(shouldShow: false)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) { // if you drag tableview buttom remove it from superview if it is empty 
        if destionationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}


