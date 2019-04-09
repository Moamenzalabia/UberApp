//  CenterVCDelegate.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit


//  this to handel left side menu moving and action 
protocol CenterVCDelegate {
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
    
}
