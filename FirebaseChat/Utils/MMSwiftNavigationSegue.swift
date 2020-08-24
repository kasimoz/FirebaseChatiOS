//
//  MMSwiftNavigationSegue.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 6.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import UIKit

class MMSwiftNavigationSegue: UIStoryboardSegue {
    var height = CGFloat.zero
    override func perform() {
        
        let tabBarController = self.source as! MediaViewController
        let destinationController = self.destination as UIViewController
        
        for view in tabBarController.containerView.subviews as [UIView] {
            view.removeFromSuperview()
        }
        
        // Add view to placeholder view
        tabBarController.currentViewController = destinationController
        tabBarController.containerView.addSubview(destinationController.view)
        
        // Set autoresizing
        tabBarController.containerView.translatesAutoresizingMaskIntoConstraints = false
        destinationController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[v1]-0-|", options: .alignAllTop, metrics: nil, views: ["v1": destinationController.view as Any])
        
        tabBarController.containerView.addConstraints(horizontalConstraint)
        
        let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[v1]-0-|", options: .alignAllTop, metrics: nil, views: ["v1": destinationController.view as Any])
        
        
        tabBarController.containerView.addConstraints(verticalConstraint)
        tabBarController.containerView.layoutIfNeeded()
        
        destinationController.didMove(toParent: tabBarController)
    }
    
}
