// RoundImageView.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.
import UIKit

class RoundImageView: UIImageView {

    override func awakeFromNib() {
        setupImageView()
    }
    
    fileprivate func setupImageView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }

}
