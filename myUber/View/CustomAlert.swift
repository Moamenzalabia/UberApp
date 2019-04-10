//  CustomAlert.swift
//  myUber
//  Created by MOAMEN on 11/23/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

class CustomAlert: UIView {
    
    static let instance = CustomAlert()
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var alertStatus: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var alertView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        Bundle.main.loadNibNamed("CustomAlert", owner: self, options: nil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit(){
        
        image.layer.cornerRadius = 30
        image.layer.borderColor = UIColor.white.cgColor
        image.layer.borderWidth = 2
        alertView.layer.cornerRadius = 10
        parentView.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - 165, y: (UIScreen.main.bounds.height / 2) - 155, width: 330, height: 310)
        parentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
    }
    
    enum AlertType {
        case success
        case failure
    }
    
    func showAlert(Status: String?, message: String?, alertType: AlertType) {
        
        DispatchQueue.main.async {
            self.alertStatus.text = Status ?? ""
            self.alertMessage.text = message ?? ""
        }
        
        switch alertType {
        case .success:
            image.image = UIImage(named: "Success")
            alertButton.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            alertButton.setTitle("Done", for: .normal)
        case .failure:
            image.image = UIImage(named: "Failure")
            alertButton.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        }
        UIApplication.shared.keyWindow?.addSubview(parentView)
        
    }
    
    @IBAction func alertButton(_ sender: Any) {
        parentView.removeFromSuperview()
    }
    
}
