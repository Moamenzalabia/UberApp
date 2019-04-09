//  DataService.swift
//  myUber
//  Created by MOAMEN on 11/11/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import Firebase

var  main_Reference = Database.database().reference()

class DataService {
    
    static let instance = DataService()
   
    // only use inside this class
    private var Base_Ref = main_Reference
    private var Users_Ref = main_Reference.child("users")
    private var Drivers_Ref = main_Reference.child("drivers")
    private var Trips_Ref = main_Reference.child("trips")
    
    // use outside this class
    var database_Reference: DatabaseReference{
        return Base_Ref
    }
    
    var users_Reference: DatabaseReference{
        return Users_Ref
    }
    
    var drivers_Reference: DatabaseReference{
        return Drivers_Ref 
    }
    
    var trips_Reference: DatabaseReference{
        return Trips_Ref
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String,Any>, isDriver: Bool) {
        
        if isDriver{
            Drivers_Ref.child(uid).updateChildValues(userData)
        }else{
            Users_Ref.child(uid).updateChildValues(userData)
        }
    }
    
    func driverIsAvailable(key: String, handler: @escaping(_ status: Bool?) -> Void) {
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot {
                    if driver.key == key {
                        if driver.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool == true {
                            if driver.childSnapshot(forPath: DRIVER_IS_ON_TRIP).value as? Bool == true{
                                handler(false)
                            }else{
                                handler(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func driverIsOnTrip(driverKey: String, handler: @escaping(_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void) {
        
        DataService.instance.drivers_Reference.child(driverKey).child(DRIVER_IS_ON_TRIP).observe(.value) { (driverTripStatusSnapshot) in
            if let driverTripStatusSnapshot = driverTripStatusSnapshot.value as? Bool{
                if driverTripStatusSnapshot == true{
                    DataService.instance.Trips_Ref.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot]{
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: DRIVER_KEY).value as? String == driverKey {
                                    handler(true, driverKey, trip.key)
                                }else {
                                    return
                                }
                            }
                        }
                    })
                }else {
                    handler(false, nil, nil)
                }
            }
        }
    }
    
    func passengerIsOnTrip(passengerKey: String, handler: @escaping(_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void) {
        DataService.instance.Trips_Ref.observeSingleEvent(of: .value) { (tripSnapshot) in
            if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.key == passengerKey {
                        if trip.childSnapshot(forPath: TRIP_IS_ACCEPTED).value as? Bool == true{
                            let driverKey = trip.childSnapshot(forPath: DRIVER_KEY).value as? String
                                    handler(true, driverKey, trip.key)
                        }else{
                            handler(false, nil, nil)
                        }
                    }
                }
            }
        }
    }
    
    func userIsDrivr(userKey: String, handler: @escaping(_ status: Bool?) -> Void) {
        
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (driverSnapshot) in
            if let driverSnapshot = driverSnapshot.children.allObjects as? [DataSnapshot] {
                for  driver in driverSnapshot {
                    if driver.key == userKey {
                        handler(true)
                    }else {
                        handler(false)
                    }
                }
            }
        }
    }
    
}
