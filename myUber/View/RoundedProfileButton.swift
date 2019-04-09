//  RoundedProfileButton.swift
//  myUber
//  Created by MOAMEN on 11/20/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

class RoundedProfileButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = self.frame.width / 2
        layer.masksToBounds = true
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 3
    }
}
