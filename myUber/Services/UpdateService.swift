//UpdateService.swift
//  myUber
//  Created by MOAMEN on 11/13/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import Firebase
import MapKit
import Foundation


class UpdateService {
    
    static var instance = UpdateService() //singltop pattern
    
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.users_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        DataService.instance.users_Reference.child(user.key).updateChildValues([COORDINATE: [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        }
        
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.key == Auth.auth().currentUser?.uid {
                        if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool == true {
                            DataService.instance.drivers_Reference.child(driver.key).updateChildValues([COORDINATE: [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        }
    }
    
    func observeTrips(handler: @escaping(_ coordinateDict: [String: Any]? ) -> Void) {
        
        DataService.instance.trips_Reference.observe(.value) { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for trip in tripSnapshot {
                    if trip.hasChild(USER_PASSENGER_KEY) && trip.hasChild(TRIP_IS_ACCEPTED) {
                        if let tripDict = trip.value as? Dictionary<String, AnyObject> {
                            handler(tripDict)
                        }
                    }
                }
            }
        }
    }
    
    func updateTripsWithCoordinatesUponRequest() {
        
        DataService.instance.users_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        if !user.hasChild(USER_IS_DRIVER) {
                            if let userDict = user.value as? Dictionary<String, AnyObject> {
                                let pickupArray = userDict[COORDINATE] as! NSArray
                                let destinationArray = userDict[TRIP_COORDINATE] as! NSArray
                                
                            DataService.instance.trips_Reference.child(user.key).updateChildValues([USER_PICKUP_COORDINATE:[pickupArray[0],pickupArray[1]],
                                                                                                    USER_DESTINATION_COORDINATE: [destinationArray[0], destinationArray[1]],
                                                                                                    USER_PASSENGER_KEY: user.key, TRIP_IS_ACCEPTED: false])
                            }
                        }
                    }
                }
            }
        }
    }
    
    func acceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String ){
        
        DataService.instance.trips_Reference.child(passengerKey).updateChildValues([DRIVER_KEY: driverKey, TRIP_IS_ACCEPTED: true])
        DataService.instance.drivers_Reference.child(driverKey).updateChildValues([DRIVER_IS_ON_TRIP: true])
    }
    
    func cancelTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String?){
        
        DataService.instance.trips_Reference.child(passengerKey).removeValue()
        DataService.instance.users_Reference.child(passengerKey).child(TRIP_COORDINATE).removeValue()
        if driverKey != nil{
            DataService.instance.drivers_Reference.child(driverKey!).updateChildValues([DRIVER_IS_ON_TRIP: false])
        }
        
    }
    
}
