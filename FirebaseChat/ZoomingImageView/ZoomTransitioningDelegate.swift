//
//  ZoomTransitioningDelegate.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 26.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit

//@objc
protocol ZoomingViewController {
    func zoomingImageView(for transition : ZoomTransitioningDelegate) -> UIImageView?
    func zoomingBackgroundView(for transition : ZoomTransitioningDelegate) -> UIView?
    func zoomingType(for transition : ZoomTransitioningDelegate) -> Constants.SegueType?
}

enum TransitionState {
    case initial
    case final
}

class ZoomTransitioningDelegate: NSObject{
    var transitioDuration  = 0.5
    var operation : UINavigationController.Operation = .none
    private let zoomScale = CGFloat(15)
    private let backgroudScale = CGFloat(0.7)
    
    typealias ZoomingViews = (otherView: UIView, imageView: UIView)
    
    func configureViews(for state: TransitionState, containerView: UIView, backgroudViewController: UIViewController, viewsInBackground: ZoomingViews, viewsInForegorund: ZoomingViews, snapshotViews: ZoomingViews){
        switch state {
        case .initial:
            backgroudViewController.view.transform = CGAffineTransform.identity
            backgroudViewController.view.alpha = 1
            let cgrect = viewsInBackground.imageView.superview?.convert(viewsInBackground.imageView.frame, to: nil)
            snapshotViews.imageView.frame = cgrect!
            break
        case .final:
            backgroudViewController.view.transform = CGAffineTransform(scaleX: backgroudScale, y: backgroudScale)
            backgroudViewController.view.alpha = 0
            snapshotViews.imageView.frame = containerView.convert(viewsInForegorund.imageView.frame, to: viewsInForegorund.imageView.superview)
            break
        }
    }
}

extension ZoomTransitioningDelegate: UIViewControllerAnimatedTransitioning{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitioDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        var duration = transitionDuration(using: transitionContext)
        let fromViewController = transitionContext.viewController(forKey: .from)!
        let toViewController = transitionContext.viewController(forKey: .to)!
        let containerView = transitionContext.containerView
        
        var backgroudViewController = fromViewController
        var foregroundViewController = toViewController

        if self.operation == .pop {
            backgroudViewController = toViewController
            foregroundViewController = fromViewController
        }
        
        let maybeBackgroundImageView = (backgroudViewController as? ZoomingViewController)?.zoomingImageView(for: self)
        let maybeForegroundImageView = (foregroundViewController as? ZoomingViewController)?.zoomingImageView(for: self)
        duration = ((backgroudViewController as? ZoomingViewController)?.zoomingType(for: self) == .profile ? 0.0 : duration )
        
        let backgroundImageView = maybeBackgroundImageView
        let foregroundImageView = maybeForegroundImageView
        
        let imageViewSnapshot = UIImageView(image: backgroundImageView?.image)
        imageViewSnapshot.contentMode = .scaleAspectFit
        imageViewSnapshot.layer.masksToBounds = true
        
        backgroundImageView?.isHidden = true
        foregroundImageView?.isHidden = true
        
        
        let foregroundViewBackgroundColor = foregroundViewController.view.backgroundColor
        foregroundViewController.view.backgroundColor = .clear
        containerView.backgroundColor = .white

        containerView.addSubview(backgroudViewController.view)
        containerView.addSubview(foregroundViewController.view)
        containerView.addSubview(imageViewSnapshot)
        
        var preTransitionState = TransitionState.initial
        var postTransitionState = TransitionState.final

        if self.operation == .pop {
            preTransitionState = .final
            postTransitionState = .initial
        }
        
        
        self.configureViews(for: preTransitionState, containerView: containerView, backgroudViewController: backgroudViewController, viewsInBackground: (backgroundImageView!, backgroundImageView!), viewsInForegorund: (foregroundImageView!, foregroundImageView!), snapshotViews: (imageViewSnapshot, imageViewSnapshot))
        
        foregroundViewController.view.layoutIfNeeded()
        
        UIView.animate(withDuration:  duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [], animations: {
            self.configureViews(for: postTransitionState, containerView: containerView, backgroudViewController: backgroudViewController, viewsInBackground: (backgroundImageView!, backgroundImageView!), viewsInForegorund: (foregroundImageView!, foregroundImageView!), snapshotViews: (imageViewSnapshot, imageViewSnapshot))
        }, completion: { (finished) in
            
            backgroudViewController.view.transform = CGAffineTransform.identity
            imageViewSnapshot.removeFromSuperview()
            backgroundImageView?.isHidden = false
            foregroundImageView?.isHidden = false
            foregroundViewController.view.backgroundColor = foregroundViewBackgroundColor
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
        
    }
    
    
}

extension ZoomTransitioningDelegate: UINavigationControllerDelegate{
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if fromVC is ZoomingViewController && toVC is ZoomingViewController{
            if (fromVC is SettingsViewController && toVC is MediaViewController) || ( toVC is SettingsViewController && fromVC is MediaViewController){
                return nil
            }else if(toVC is RoomViewController && fromVC is RoomViewController){
                return nil
            }else{
                self.operation = operation
                return self
            }
            
        }else{
            return nil
        }
    }
}
