//
//  ElasticRefreshLoadingViewCircle.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit

// MARK: - ElasticRefreshLoadingViewCircle

/// Circle loading view with rotation animation
open class ElasticRefreshLoadingViewCircle: ElasticRefreshLoadingView {
    
    // MARK: - Constants
    
    private static let rotationAnimationKey = "RotationAnimation"
    
    // MARK: - Properties
    
    /// Shape layer for the circle
    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 5.0
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = tintColor.cgColor
        layer.actions = [
            "strokeEnd": NSNull(),
            "transform": NSNull()
        ]
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        return layer
    }()
    
    /// Identity transform for rotation
    private lazy var identityTransform: CATransform3D = {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -500
        return CATransform3DRotate(transform, (-90.0 * .pi / 180.0), 0, 0, 1.0)
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupShapeLayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShapeLayer()
    }
    
    // MARK: - Setup
    
    private func setupShapeLayer() {
        layer.addSublayer(shapeLayer)
    }
    
    // MARK: - Overrides
    
    open override func setPullProgress(_ progress: CGFloat) {
        super.setPullProgress(progress)
        
        shapeLayer.strokeEnd = min(0.9 * progress, 0.9)
        
        if progress > 1.0 {
            let degrees = (progress - 1.0) * 200.0
            shapeLayer.transform = CATransform3DRotate(identityTransform, (degrees * .pi / 180.0), 0, 0, 1.0)
        } else {
            shapeLayer.transform = identityTransform
        }
    }
    
    open override func startAnimating() {
        super.startAnimating()
        
        // Check if animation is already running
        if shapeLayer.animation(forKey: Self.rotationAnimationKey) != nil {
            return
        }
        
        // Create rotation animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        let currentRotation = shapeLayer.value(forKeyPath: "transform.rotation.z") as? Double ?? 0.0
        rotationAnimation.toValue = 2.0 * Double.pi + currentRotation
        rotationAnimation.duration = 1.0
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = .forwards
        
        shapeLayer.add(rotationAnimation, forKey: Self.rotationAnimationKey)
    }
    
    open override func stopLoading() {
        super.stopLoading()
        shapeLayer.removeAnimation(forKey: Self.rotationAnimationKey)
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        shapeLayer.strokeColor = tintColor.cgColor
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        shapeLayer.frame = CGRect(
            x: 0, 
            y: 0, 
            width: bounds.size.width + 10, 
            height: bounds.size.height + 10
        )
        
        let inset = shapeLayer.lineWidth / 2.0
        let ovalRect = shapeLayer.bounds.insetBy(dx: inset, dy: inset)
        shapeLayer.path = UIBezierPath(ovalIn: ovalRect).cgPath
    }
    
    // MARK: - Public Methods
    
    /// Get current rotation degree
    /// - Returns: Current rotation degree in radians
    open func currentDegree() -> CGFloat {
        guard let rotationValue = shapeLayer.value(forKeyPath: "transform.rotation.z") as? NSNumber else {
            return 0.0
        }
        return CGFloat(rotationValue.doubleValue)
    }
} 