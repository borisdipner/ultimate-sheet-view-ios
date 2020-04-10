//
//  SheetViewController.swift
//  ultimate-sheet-swift
//
//  Created by Boris Dipner on 08.04.2020.
//  Copyright © 2020 Boris Dipner. All rights reserved.
//

import UIKit

class SheetViewController: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    // MARK: Variables Defenition
    var ultimateSheet: SelfSheetViewController!
    var visualEffectView: UIVisualEffectView!
    
    let cardHeight: CGFloat = 400
    let cardHandleAreaHeight: CGFloat = 200
    
    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0
    
    // MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCard()
    }
}

// MARK: Private
private extension SheetViewController {
    
    // MARK: SetUp
    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        
        ultimateSheet = SelfSheetViewController(nibName:"SelfSheetViewController", bundle:nil)
        self.addChild(ultimateSheet)
        self.view.addSubview(ultimateSheet.view)
        
        ultimateSheet.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        
        ultimateSheet.view.clipsToBounds = true
        
        ultimateSheet.handleArea.layer.cornerRadius = 25
        ultimateSheet.handleArea.layer.shadowRadius = 7
        ultimateSheet.handleArea.layer.shadowOpacity = 0.2
        ultimateSheet.handleArea.layer.shadowColor = UIColor.black.cgColor
//        ultimateSheet.view.layer.shadowOffset = CGSize(width: 0, height: 5)
//        ultimateSheet.view.layer.borderWidth = 2
//        ultimateSheet.view.layer.borderColor = UIColor.gray.cgColor
        
        ultimateSheet.handleViewRectangle.layer.cornerRadius = 4
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SheetViewController.handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SheetViewController.handleCardPan(recognizer:)))
        
        ultimateSheet.handleArea.addGestureRecognizer(tapGestureRecognizer)
        ultimateSheet.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
}

// MARK: Animation
private extension SheetViewController {
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.ultimateSheet.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.ultimateSheet.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.8) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}

// MARK: GestureRecognizer
private extension SheetViewController {
    
    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.ultimateSheet.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
            
        default:
            break;
            
        }
    }
}
