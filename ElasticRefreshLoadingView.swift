//
//  ElasticRefreshLoadingView.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit

// MARK: - ElasticRefreshLoadingView

/// Base loading view for elastic pull to refresh
open class ElasticRefreshLoadingView: UIView {
    
    // MARK: - Properties
    
    /// Mask layer for the loading view
    public private(set) lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.black.cgColor
        layer.actions = [
            "path": NSNull(),
            "position": NSNull(),
            "bounds": NSNull()
        ]
        self.layer.mask = layer
        return layer
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Ensure maskLayer is initialized
        _ = maskLayer
    }
    
    // MARK: - Public Methods
    
    /// Set pull progress (0.0 to 1.0+)
    /// - Parameter progress: Progress value
    open func setPullProgress(_ progress: CGFloat) {
        // Override in subclasses for custom progress handling
    }
    
    /// Start loading animation
    open func startAnimating() {
        // Override in subclasses for custom animation
    }
    
    /// Stop loading animation
    open func stopLoading() {
        // Override in subclasses for custom stop handling
    }
} 