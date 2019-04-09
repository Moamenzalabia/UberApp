//  RoundedShadowView.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        setupView()
    }

    fileprivate func setupView() {
        self.layer.cornerRadius = 5.0
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
    }
}
