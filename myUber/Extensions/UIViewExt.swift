//UIViewExt.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.


import UIKit

extension UIView {
    func fadeTo(alphaValue: CGFloat, withDuration duration: TimeInterval){
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }
    
    // this func to  move all view's ip when keyboard start editting using notification's center
    func bindToKeyBoard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardWillChange(_ notification: NSNotification){
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        let curFrame = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue: curve), animations: {
            self.frame.origin.y += deltaY
        }, completion: nil)
        
    }
}
