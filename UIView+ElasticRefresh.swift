//
//  UIView+ElasticRefresh.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit

// MARK: - UIView Extension for ElasticRefresh

extension UIView {
    
    /// Get center point, optionally using presentation layer if animating
    /// - Parameter usePresentationLayerIfPossible: Whether to use presentation layer position
    /// - Returns: The center point of the view or its presentation layer
    func elasticRefresh_centerUsePresentationLayerIfPossible(_ usePresentationLayerIfPossible: Bool) -> CGPoint {
        if usePresentationLayerIfPossible, let presentationLayer = layer.presentation() {
            return presentationLayer.position
        } else {
            return center
        }
    }
} 