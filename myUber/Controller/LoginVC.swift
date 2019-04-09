//  LoginVC.swift
//  myUber
//  Created by MOAMEN on 11/10/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, Alertable {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var emailTextField: RoundTextField!
    @IBOutlet weak var passwordTextField: RoundTextField!
    @IBOutlet weak var authButton: RoundedShadowButton!
    @IBOutlet weak var userProgileImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        view.bindToKeyBoard() // this func to move all view's up when keyboard is start editting
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(snder:)))
        self.view.addGestureRecognizer(tap) //  this tap to move all view's back to nirmal state when end editting
    
    }
    
    // fuc than handel dismiss keyboard
    @objc func  handleScreenTap(snder: UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func userProfileImage(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing =  true
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    //Mark: display image in button and it's status  and custom desgin
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage]  as? UIImage {
            userProgileImage.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)
            
        }else if let originalImage = info[.originalImage]  as? UIImage {
            userProgileImage.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func authButton(_ sender: Any) {
        
        if emailTextField != nil && passwordTextField != nil { // there is data in textfields
            authButton.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            
            if let email = emailTextField.text, let password = passwordTextField.text{
                
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in // if user have an account before
                    if error == nil { // there is no error
                        if let user = user {
                            if self.segmentedControl.selectedSegmentIndex == 0{ // user with type of user
                                let userData = ["provider": user.providerID] as [String:Any]
                                DataService.init().createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                            }else{ // user with type of driver
                                let userData = ["provider": user.providerID, USER_IS_DRIVER: true, ACCOUNT_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                            }
                        }
                        self.showAlert("Email user authenticated successfully with Firebase", status: true)
                        self.authButton.animateButton(shouldLoad: false, withMessage: "LOG OUT")
                        self.dismiss(animated: true, completion: nil)
                    }else{ // if there is an error
                        if let errorCode = AuthErrorCode(rawValue: error!._code){
                            switch errorCode{
                            case .wrongPassword:
                                self.showAlert("Whoops! That was the wrong password!", status: false)
                            case .weakPassword:
                                self.showAlert("Please make a Strong password!", status: false)
                            default:
                                self.showAlert("An  error occurred. Please try again.", status: false)
                            }
                            self.authButton.animateButton(shouldLoad: false, withMessage: "LOG IN ")
                        }
                        // create new acount
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {// if have an error
                                if let errorCode = AuthErrorCode(rawValue: error!._code){
                                    switch errorCode{
                                    case .invalidEmail:
                                        self.showAlert("Email invalid. please try again.", status: false)
                                    case .emailAlreadyInUse:
                                        self.showAlert("That email is already in use. please try again.", status: false)
                                    default:
                                        self.showAlert("An  error occurred. Please try again.", status: false)
                                        
                                    }
                                }
                                self.authButton.animateButton(shouldLoad: false, withMessage: "SIGN UP/LOGIN")
                            }else{
                                guard let image = self.userProgileImage.imageView?.image  else {return}
                                guard let uploadData = image.jpegData(compressionQuality: 0.1) else {return}
                                let filename = NSUUID().uuidString
                                //Mark: to save user image into firebase Storage
                                let storageRef = Storage.storage().reference().child("Profile_images")
                                _ = storageRef.child(filename).putData(uploadData, metadata: nil, completion: { (metadata,error ) in
                                    guard let metadata = metadata else{
                                        self.showAlert("Failed to upload profile image:\(error!.localizedDescription)", status: false)
                                        return
                                    }
                                    let downloadURL = metadata.downloadURL()!.absoluteString
                                    if let user = user {
                                        if self.segmentedControl.selectedSegmentIndex == 0{
                                            let userData = ["provider": user.providerID, "userImage": downloadURL] as [String:Any]
                                            DataService.init().createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                        }else{
                                            let userData = ["provider": user.providerID, "driverImage": downloadURL, USER_IS_DRIVER: true, MSG_PICKUP_MODE_ENABLED: false, DRIVER_IS_ON_TRIP: false] as [String: Any]
                                            DataService.instance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                        }
                                    }
                                })
                                self.showAlert(" Successfully create a new user with Firebase", status: true)
                                self.authButton.animateButton(shouldLoad: false, withMessage: "LOG OUT")
                                self.dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                }
            }
        }
    }
    
}
