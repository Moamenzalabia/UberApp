//  LeftSidePanelVC.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import Firebase

class LeftSidePanelVC: UIViewController, Alertable {
    
    let appDelegate = AppDelegate.getAppDelegate() // becuse it an variable on app delegate file
    let currentUserId = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var userImageView: CustomImageView!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    @IBOutlet weak var pickupModeLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userAccountLabel: UILabel!
    @IBOutlet weak var loginOutButton: CustomCornerButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLabel.isHidden = true
        
        observePassengerAndDrivers()
        
        if Auth.auth().currentUser == nil {
            userEmailLabel.text = ""
            userAccountLabel.text = ""
            userImageView.isHidden = true
            loginOutButton.setTitle(MSG_SIGN_UP_SIGN_IN, for: .normal)
        }else{
            userEmailLabel.text = Auth.auth().currentUser?.email
            
            userAccountLabel.text = ""
            userImageView.isHidden = false
            loginOutButton.setTitle(MSG_SIGN_OUT, for: .normal)
        }
    }
    
    // download passenger profile data
    func observePassengerAndDrivers(){
        DataService.instance.users_Reference.observeSingleEvent(of: .value , with: { (snapshot) in
            guard let userDictionary = snapshot.value as? [String: Any] else { return }
            userDictionary.forEach({ (key, value) in
                if key == Auth.auth().currentUser?.uid {
                    self.userAccountLabel.text = ACCOUNT_TYPE_PASSENGER
                    guard let valueDictionary = value as? [String: Any] else { return }
                    guard let userImageURL = valueDictionary["userImage"] as? String else{ return }
                    self.userImageView.loadImage(urlString: userImageURL)
                }
            })
        }) { (error) in
            self.showAlert("Failed to fetch following user Ids: \( error.localizedDescription)", status: false)
            
        }
        
        // download driver profile data
        DataService.instance.drivers_Reference.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountLabel.text = ACCOUNT_TYPE_DRIVER
                        self.pickupModeSwitch.isHidden = false
                        guard let valueDictionary = snap.value as? [String: Any] else { return }
                        guard let driverImageURL = valueDictionary["driverImage"] as? String else{ return }
                        self.userImageView.loadImage(urlString: driverImageURL)
                        self.pickupModeLabel.isHidden = false
                        guard let switchStatus = snap.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool else {return}
                        self.pickupModeSwitch.isOn = switchStatus
                    }
                }
            }
        }
    }
    
    
    @IBAction func switchToggleButton(_ sender: Any) {
        
        if pickupModeSwitch.isOn {
            pickupModeLabel.text = MSG_PICKUP_MODE_ENABLED
            appDelegate.MenuContainerVC.toggleLeftPanel()
            DataService.instance.drivers_Reference.child(currentUserId!).updateChildValues([ACCOUNT_PICKUP_MODE_ENABLED: true])
        }else{
            pickupModeLabel.text = MSG_PICKUP_MODE_DISABLED
            appDelegate.MenuContainerVC.toggleLeftPanel()
            DataService.instance.drivers_Reference.child(currentUserId!).updateChildValues([ACCOUNT_PICKUP_MODE_ENABLED: false])
        }
        
    }
    
    @IBAction func signUpLoginButton(_ sender: Any) {
        self.loginOutButton.setupButtonAnimation()
        
        if Auth.auth().currentUser == nil{
            let storyboard = UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: VC_LOGIN) as? LoginVC
            present(loginVC!, animated: true, completion: nil)
            
        } else { // if user is loged in 
            do{
                try Auth.auth().signOut()
                userEmailLabel.text = ""
                userAccountLabel.text = ""
                userImageView.isHidden = true
                pickupModeLabel.text = ""
                pickupModeSwitch.isHidden = true
                loginOutButton.setTitle(MSG_SIGN_UP_SIGN_IN, for: .normal)
            }catch(let error){
                self.showAlert("Failed to log out: \( error.localizedDescription)", status: false)
                
            }
        }
    }
}

