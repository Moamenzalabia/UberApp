// RoundedShadowButton.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved
import UIKit

class RoundedShadowButton: UIButton {
    
    var originalSize: CGRect?
    
    override func awakeFromNib() {
        setupButtonView()
    }
    
    func setupButtonView() {
        originalSize = self.frame
        self.layer.cornerRadius = 5.0
        self.layer.shadowRadius = 10.0
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize.zero
    }
    
    // custom nice anmation for button
    func  animateButton(shouldLoad: Bool, withMessage message: String?)  {
        let spinner = UIActivityIndicatorView()
        spinner.style = .whiteLarge
        spinner.color = UIColor.darkGray
        spinner.alpha = 0.0
        spinner.hidesWhenStopped = true
        spinner.tag = 21
        
        if shouldLoad { // is user press on button add spinner and start anmations 
            self.addSubview(spinner)
            self.setTitle("", for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = self.frame.height / 2
                self.frame = CGRect(x: self.frame.midX - (self.frame.height / 2), y: self.frame.origin.y, width: self.frame.height, height: self.frame.height)
            }, completion: { (finished) in
                if finished == true{
                    spinner.startAnimating()
                    spinner.center = CGPoint(x: self.frame.width / 2 + 1, y: self.frame.width / 2 + 1)
                    spinner.fadeTo(alphaValue: 1.0, withDuration: 0.2)
                    
                }
            })
            self.isUserInteractionEnabled = false // to stop user action durring anmation
        }else{// after load is false  remove spinner from super view and enable user action and set originalsize to button
            self.isUserInteractionEnabled = true
            for subview in self.subviews {
                if subview.tag == 21 {
                    subview.removeFromSuperview()
                }
            }
            UIView.animate(withDuration: 0.2) {
                self.layer.cornerRadius = 5.0
                self.frame = self.originalSize!
                self.setTitle(message, for: .normal)
            }
        }
    }
}

