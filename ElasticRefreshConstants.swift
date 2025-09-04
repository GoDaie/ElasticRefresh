//
//  ElasticRefreshConstants.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Key Path Constants

/// ContentOffset key path for KVO
internal let ElasticRefreshContentOffset = "contentOffset"

/// ContentInset key path for KVO  
internal let ElasticRefreshContentInset = "contentInset"

/// Frame key path for KVO
internal let ElasticRefreshFrame = "frame"

/// PanGestureRecognizer state key path for KVO
internal let ElasticRefreshPanGestureRecognizerState = "panGestureRecognizer.state"

// MARK: - Animation Constants

/// Maximum wave height during pull animation
internal let ElasticRefreshWaveMaxHeight: CGFloat = 70.0

/// Minimum offset distance to trigger refresh
internal let ElasticRefreshMinOffsetToPull: CGFloat = 95.0

/// Content inset when loading
internal let ElasticRefreshLoadingContentInset: CGFloat = 50.0

/// Loading view size
internal let ElasticRefreshLoadingViewSize: CGFloat = 15.0 