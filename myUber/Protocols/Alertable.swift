//  Alertable.swift
//  myUber
//  Created by MOAMEN on 11/23/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

protocol Alertable {}

extension Alertable where Self: UIViewController{
    
    
    func showAlert(_ alertMessage: String, status: Bool ) {
        
        if status == false {
            CustomAlert.instance.showAlert(Status: "Failure", message: alertMessage, alertType: .failure)
        }else{
            CustomAlert.instance.showAlert(Status: "Success", message: alertMessage, alertType: .success)
        }
        
        
    }
}
