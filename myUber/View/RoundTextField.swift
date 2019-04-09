//  RoundTextField.swift
//  myUber
//  Created by MOAMEN on 11/10/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

class RoundTextField: UITextField {
    
    let padding = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    override func awakeFromNib() {
        setupTextField()
    }
    
    func setupTextField(){
        self.layer.cornerRadius = self.layer.frame.size.height / 2
        self.layer.masksToBounds = true
        
    }
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
}

