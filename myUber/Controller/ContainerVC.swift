//  ContainerVC.swift
//  myUber
//  Created by MOAMEN on 11/9/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.

import UIKit
import QuartzCore

//States of vc
enum SlideOutState {
    case collapsed
    case leftPanelExpanded
}
// showing vc's
enum ShowWhichVC{
    case homeVC
}

var showVC: ShowWhichVC = .homeVC // defualt open vc ic homevc

class ContainerVC: UIViewController {
   
    var homeVC: HomeVC!
    var leftVC: LeftSidePanelVC!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed {
        didSet{ // add shadow to left side view whent it is open
            let shouldShowShadow = (currentState != .collapsed) // if currentState is .collapsed, then shouldShowShadow is false
            shouldShowShadowForCenterViewController(status: shouldShowShadow)
        }
    }
    var isHidden = false
    let centerPanelExpandedOffset: CGFloat = 160 // size of  vc that expand in it
    var tap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC) // init vc is showvc that' at firs ic homevc
    }
    
    func initCenter(screen: ShowWhichVC) {
        
        var presentingController: UIViewController
        showVC = screen
        
        // if homevc is nill present homevc in root view
        if homeVC == nil {
           homeVC = UIStoryboard.homeVC()
           homeVC.delegate = self
        }
        
        presentingController = homeVC
        
        // befor expand any vc clean root view to save memory
        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParent()
        }
        
        // after clean parent view and centerController
        centerController = presentingController
        view.addSubview(centerController.view)
        addChild(centerController)
        centerController.didMove(toParent: self)
        
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return isHidden
    }
}

extension ContainerVC: CenterVCDelegate {
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        
        // means notAlreadyexpanded = is in leftpanelside of view 'menu is close'
        if notAlreadyExpanded{
            addLeftPanelViewController()
        }
        animateLeftPanel(shouldExpand: notAlreadyExpanded) // means notAlreadyexpanded is in rightsidepanel of view 'menu is open'

    }
    
    func addLeftPanelViewController() {
        if leftVC == nil {
            leftVC = UIStoryboard.leftViewController()
            addChildSidePanelViewController(leftVC)
        }
    }
    
    func addChildSidePanelViewController(_ sidePanelController: LeftSidePanelVC)  {
         view.insertSubview(sidePanelController.view, at: 0)
         addChild(sidePanelController)
         sidePanelController.didMove(toParent: self)
    }
    
    @objc func animateLeftPanel(shouldExpand: Bool) {
        // means is in right side  'means menu is open'
        if shouldExpand { // left side menu is open
            isHidden = !isHidden
            animateStausBar()
            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            animateCenterPanelXposition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        }else{// left side menu is closed
            isHidden = !isHidden
            animateStausBar()
            hideWhiteCoverView()
            animateCenterPanelXposition(targetPosition: 0) { (finished) in
                if finished == true{
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            }
        }
    }
    
    func animateCenterPanelXposition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func animateStausBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
           self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func setupWhiteCoverView(){
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self.centerController.view.addSubview(whiteCoverView)
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)

        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func shouldShowShadowForCenterViewController(status: Bool){
        if status == true {
            centerController.view.layer.shadowOpacity = 0.6
        }else{
            centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func hideWhiteCoverView(){
        centerController.view.removeGestureRecognizer(tap)
        for subview in self.centerController.view.subviews {
            if subview.tag == 25{
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }) { (finished) in
                    subview.removeFromSuperview()
                }
            }
        }
    }
}

private extension UIStoryboard{
    
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: MAIN_STORYBOARD, bundle: Bundle.main)
    }
    
    class func leftViewController() -> LeftSidePanelVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_LEFT_PANEL) as? LeftSidePanelVC
    }
    
    class func homeVC() -> HomeVC? {
        return mainStoryboard().instantiateViewController(withIdentifier: VC_HOME) as? HomeVC
    }
}
