// CircleView.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

class CircleView: UIView {

    @IBInspectable var borderColor: UIColor? {
        didSet{
            setupView()
        }
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    fileprivate func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }

}
