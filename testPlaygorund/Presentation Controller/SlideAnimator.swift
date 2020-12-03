//
//  SlideAnimator.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/12/03.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit

class SlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    enum AnimationState {
        case appearMenu
        case dismissMenu
    }

    private var duration: Double
    private var moveToRight: Bool
    private var originFrame = CGRect.zero

    init(state: AnimationState, duration: Double) {
        self.moveToRight = state == .appearMenu ? true : false
        self.duration = duration
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let viewToMove = moveToRight ? transitionContext.view(forKey: .to)! : transitionContext.view(forKey: .from)!

        containerView.addSubview(viewToMove)
        
        // メニュー画面の最終位置
        let menuPositionX = moveToRight ? viewToMove.layer.position.x : -viewToMove.frame.width

        // メニュー画面の初期位置
        viewToMove.layer.position.x = moveToRight ? -viewToMove.frame.width : viewToMove.layer.position.x
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                viewToMove.layer.position.x = menuPositionX
            },
            completion: { bool in
                transitionContext.completeTransition(true)
                
            })
        
        return
    }
}

