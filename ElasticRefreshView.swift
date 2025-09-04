//
//  ElasticRefreshView.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit

// MARK: - Enums and Typealias

/// Refresh states for the elastic pull to refresh view
@objc public enum ElasticRefreshState: Int {
    case stopped = 0
    case dragging
    case animatingBounce
    case loading
    case animatingToStopped
}

/// Completion block for refresh operations
public typealias ElasticRefreshCompletionBlock = () -> Void

/// Action handler for refresh events
public typealias ElasticRefreshActionHandler = () -> Void

// MARK: - ElasticRefreshView

/// Main elastic pull to refresh view with wave animation
open class ElasticRefreshView: UIView {
    
    // MARK: - Public Properties
    
    /// Current refresh state
    open var refreshState: ElasticRefreshState = .stopped {
        didSet {
            handleStateChange(from: oldValue, to: refreshState)
        }
    }
    
    /// Loading view instance
    open var loadingView: ElasticRefreshLoadingView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let loadingView = loadingView {
                addSubview(loadingView)
            }
        }
    }
    
    /// Fill color for the wave
    open var fillColor: UIColor = .clear {
        didSet {
            shapeLayer.fillColor = fillColor.cgColor
        }
    }
    
    /// Whether this view is observing scroll view changes
    open var observing: Bool = false {
        didSet {
            updateObserving()
        }
    }
    
    /// Action handler called when refresh is triggered
    open var actionHandler: ElasticRefreshActionHandler?
    
    // MARK: - Private Properties
    
    private var stateChanged: Bool = false
    private var originalContentInsetTop: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    // Control point views for wave animation
    private lazy var bounceAnimationHelperView = UIView()
    private lazy var cControlPointView = UIView()
    private lazy var l1ControlPointView = UIView()
    private lazy var l2ControlPointView = UIView()
    private lazy var l3ControlPointView = UIView()
    private lazy var r1ControlPointView = UIView()
    private lazy var r2ControlPointView = UIView()
    private lazy var r3ControlPointView = UIView()
    
    // Animation layers
    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.black.cgColor
        layer.actions = [
            "path": NSNull(),
            "position": NSNull(),
            "bounds": NSNull()
        ]
        return layer
    }()
    
    private lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        return link
    }()
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    deinit {
        observing = false
        NotificationCenter.default.removeObserver(self)
        displayLink.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Setup layers and subviews
        layer.addSublayer(shapeLayer)
        
        // Add control point views
        addSubview(bounceAnimationHelperView)
        addSubview(cControlPointView)
        addSubview(l1ControlPointView)
        addSubview(l2ControlPointView)
        addSubview(l3ControlPointView)
        addSubview(r1ControlPointView)
        addSubview(r2ControlPointView)
        addSubview(r3ControlPointView)
        
        // Setup loading view
        loadingView = ElasticRefreshLoadingView()
        
        // Observe app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - State Management
    
    private var actualRefreshState: ElasticRefreshState {
        return stateChanged ? refreshState : .stopped
    }
    
    private func handleStateChange(from previousState: ElasticRefreshState, to newState: ElasticRefreshState) {
        stateChanged = true
        
        switch newState {
        case .animatingBounce where previousState == .dragging:
            loadingView?.startAnimating()
            animateBounce()
            
        case .loading where actionHandler != nil:
            actionHandler?()
            
        case .animatingToStopped:
            resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: true) { [weak self] in
                self?.refreshState = .stopped
            }
            
        case .stopped:
            loadingView?.stopLoading()
            
        default:
            break
        }
    }
    
    // MARK: - Observation
    
    private func updateObserving() {
        guard let scrollView = scrollView else { return }
        
        if observing {
            scrollView.addObserver(self, forKeyPath: ElasticRefreshContentOffset, options: .new, context: nil)
            scrollView.addObserver(self, forKeyPath: ElasticRefreshContentInset, options: .new, context: nil)
            scrollView.addObserver(self, forKeyPath: ElasticRefreshFrame, options: .new, context: nil)
            scrollView.addObserver(self, forKeyPath: ElasticRefreshPanGestureRecognizerState, options: .new, context: nil)
        } else {
            scrollView.removeObserver(self, forKeyPath: ElasticRefreshContentOffset)
            scrollView.removeObserver(self, forKeyPath: ElasticRefreshContentInset)
            scrollView.removeObserver(self, forKeyPath: ElasticRefreshFrame)
            scrollView.removeObserver(self, forKeyPath: ElasticRefreshPanGestureRecognizerState)
        }
    }
    
    // MARK: - KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath, let change = change else { return }
        
        switch keyPath {
        case ElasticRefreshContentOffset:
            if let newValue = change[.newKey] as? NSValue {
                let newContentOffsetY = newValue.cgPointValue.y
                handleContentOffsetChange(newContentOffsetY)
            }
            
        case ElasticRefreshContentInset:
            if let newValue = change[.newKey] as? NSValue {
                let newContentInsetTop = newValue.uiEdgeInsetsValue.top
                originalContentInsetTop = newContentInsetTop
            }
            
        case ElasticRefreshFrame:
            setNeedsLayout()
            
        case ElasticRefreshPanGestureRecognizerState:
            if let scrollView = scrollView {
                let gestureState = scrollView.panGestureRecognizer.state
                if gestureState == .ended || gestureState == .cancelled || gestureState == .failed {
                    scrollViewDidChangeContentOffset(dragging: false)
                }
            }
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func handleContentOffsetChange(_ newContentOffsetY: CGFloat) {
        guard let scrollView = scrollView else { return }
        
        if (refreshState == .loading || refreshState == .animatingToStopped) && 
           newContentOffsetY < -scrollView.contentInset.top {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top)
        } else {
            scrollViewDidChangeContentOffset(dragging: scrollView.isDragging)
        }
        
        setNeedsLayout()
    }
    
    // MARK: - Scroll View Interaction
    
    private func scrollViewDidChangeContentOffset(dragging: Bool) {
        let offsetY = actualContentOffsetY
        
        switch refreshState {
        case .stopped where dragging:
            refreshState = .dragging
            
        case .dragging where !dragging:
            if offsetY >= ElasticRefreshMinOffsetToPull {
                refreshState = .animatingBounce
            } else {
                refreshState = .stopped
            }
            
        case .dragging, .stopped:
            let pullProgress = offsetY / ElasticRefreshMinOffsetToPull
            loadingView?.setPullProgress(pullProgress)
            
        default:
            break
        }
    }
    
    // MARK: - Animation
    
    private func animateBounce() {
        guard let scrollView = scrollView else { return }
        
        resetScrollViewContentInset(shouldAddObserverWhenFinished: false, animated: false, completion: nil)
        
        let centerY = ElasticRefreshLoadingContentInset
        let duration: TimeInterval = 0.9
        
        scrollView.isScrollEnabled = false
        startDisplayLink()
        scrollView.removeObserver(self, forKeyPath: ElasticRefreshContentOffset)
        scrollView.removeObserver(self, forKeyPath: ElasticRefreshContentInset)
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.43, initialSpringVelocity: 0, options: .layoutSubviews, animations: { [weak self] in
            guard let self = self else { return }
            self.cControlPointView.center = CGPoint(x: self.cControlPointView.center.x, y: centerY)
            self.l1ControlPointView.center = CGPoint(x: self.l1ControlPointView.center.x, y: centerY)
            self.l2ControlPointView.center = CGPoint(x: self.l2ControlPointView.center.x, y: centerY)
            self.l3ControlPointView.center = CGPoint(x: self.l3ControlPointView.center.x, y: centerY)
            self.r1ControlPointView.center = CGPoint(x: self.r1ControlPointView.center.x, y: centerY)
            self.r2ControlPointView.center = CGPoint(x: self.r2ControlPointView.center.x, y: centerY)
            self.r3ControlPointView.center = CGPoint(x: self.r3ControlPointView.center.x, y: centerY)
        }) { [weak self] _ in
            guard let self = self, let scrollView = self.scrollView else { return }
            
            self.stopDisplayLink()
            self.resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: false, completion: nil)
            scrollView.addObserver(self, forKeyPath: ElasticRefreshContentOffset, options: .new, context: nil)
            scrollView.isScrollEnabled = true
            self.refreshState = .loading
        }
        
        bounceAnimationHelperView.center = CGPoint(x: 0, y: originalContentInsetTop + currentHeight)
        UIView.animate(withDuration: duration * 0.4) { [weak self] in
            guard let self = self else { return }
            let contentInsetTop = self.originalContentInsetTop
            self.bounceAnimationHelperView.center = CGPoint(x: 0, y: contentInsetTop + ElasticRefreshLoadingContentInset)
        }
    }
    
    private func resetScrollViewContentInset(shouldAddObserverWhenFinished: Bool, animated: Bool, completion: ElasticRefreshCompletionBlock?) {
        guard let scrollView = scrollView else { return }
        
        var contentInset = scrollView.contentInset
        contentInset.top = originalContentInsetTop
        
        if refreshState == .animatingBounce {
            contentInset.top += currentHeight
        } else if refreshState == .loading {
            contentInset.top += ElasticRefreshLoadingContentInset
        }
        
        scrollView.removeObserver(self, forKeyPath: ElasticRefreshContentInset)
        
        let animationBlock = {
            scrollView.contentInset = contentInset
        }
        
        let completionBlock = { [weak self] in
            guard let self = self else { return }
            if shouldAddObserverWhenFinished && self.observing {
                scrollView.addObserver(self, forKeyPath: ElasticRefreshContentInset, options: .new, context: nil)
            }
            completion?()
        }
        
        if animated {
            startDisplayLink()
            UIView.animate(withDuration: 0.35, animations: animationBlock) { [weak self] _ in
                self?.stopDisplayLink()
                completionBlock()
            }
        } else {
            animationBlock()
            completionBlock()
        }
    }
    
    // MARK: - Display Link
    
    private func startDisplayLink() {
        displayLink.isPaused = false
    }
    
    private func stopDisplayLink() {
        displayLink.isPaused = true
    }
    
    @objc private func displayLinkTick() {
        let width = bounds.size.width
        var height: CGFloat = 0
        
        if refreshState == .animatingBounce {
            guard let scrollView = scrollView else { return }
            
            let bounceCenter = bounceAnimationHelperView.elasticRefresh_centerUsePresentationLayerIfPossible(isAnimating)
            scrollView.contentInset = UIEdgeInsets(
                top: bounceCenter.y,
                left: scrollView.contentInset.left,
                bottom: scrollView.contentInset.bottom,
                right: scrollView.contentInset.right
            )
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: -scrollView.contentInset.top)
            
            height = scrollView.contentInset.top - originalContentInsetTop
            frame = CGRect(x: 0, y: -height - 1.0, width: width, height: height)
        } else if refreshState == .animatingToStopped {
            height = actualContentOffsetY
        }
        
        shapeLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        shapeLayer.path = currentPath
        
        layoutLoadingView()
    }
    
    // MARK: - Path Generation
    
    private var currentPath: CGPath {
        guard let scrollView = scrollView else { return UIBezierPath().cgPath }
        
        let width = scrollView.bounds.size.width
        let bezierPath = UIBezierPath()
        let animating = isAnimating
        
        bezierPath.move(to: .zero)
        bezierPath.addLine(to: CGPoint(x: 0, y: l3ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating).y))
        
        bezierPath.addCurve(
            to: l1ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint1: l3ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint2: l2ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating)
        )
        
        bezierPath.addCurve(
            to: r1ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint1: cControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint2: r1ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating)
        )
        
        bezierPath.addCurve(
            to: r3ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint1: r1ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating),
            controlPoint2: r2ControlPointView.elasticRefresh_centerUsePresentationLayerIfPossible(animating)
        )
        
        bezierPath.addLine(to: CGPoint(x: width, y: 0))
        bezierPath.close()
        
        return bezierPath.cgPath
    }
    
    // MARK: - Helper Properties
    
    private var scrollView: UIScrollView? {
        return superview as? UIScrollView
    }
    
    private var isAnimating: Bool {
        return refreshState == .animatingBounce || refreshState == .animatingToStopped
    }
    
    private var actualContentOffsetY: CGFloat {
        guard let scrollView = scrollView else { return 0 }
        return max(-scrollView.contentInset.top - scrollView.contentOffset.y, 0)
    }
    
    private var currentHeight: CGFloat {
        guard let scrollView = scrollView else { return 0 }
        return max(-originalContentInsetTop - scrollView.contentOffset.y, 0)
    }
    
    private var currentWaveHeight: CGFloat {
        return min(bounds.size.height / 3.0 * 1.6, ElasticRefreshWaveMaxHeight)
    }
    
    // MARK: - Layout
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let scrollView = scrollView, refreshState != .animatingBounce else { return }
        
        let width = scrollView.bounds.size.width
        let height = currentHeight
        
        frame = CGRect(x: 0, y: -height, width: width, height: height)
        
        if refreshState == .loading || refreshState == .animatingToStopped {
            // Loading state - straight line
            let controlPoints = [cControlPointView, l1ControlPointView, l2ControlPointView, l3ControlPointView, r1ControlPointView, r2ControlPointView, r3ControlPointView]
            
            cControlPointView.center = CGPoint(x: width / 2.0, y: height)
            l1ControlPointView.center = CGPoint(x: 0, y: height)
            l2ControlPointView.center = CGPoint(x: 0, y: height)
            l3ControlPointView.center = CGPoint(x: 0, y: height)
            r1ControlPointView.center = CGPoint(x: width, y: height)
            r2ControlPointView.center = CGPoint(x: width, y: height)
            r3ControlPointView.center = CGPoint(x: width, y: height)
        } else {
            // Dragging state - curved wave
            let locationX = scrollView.panGestureRecognizer.location(in: scrollView).x
            let waveHeight = currentWaveHeight
            let baseHeight = bounds.size.height - waveHeight
            
            let minLeftX = min((locationX - width / 2.0) * 0.28, 0)
            let maxRightX = max(width + (locationX - width / 2.0) * 0.28, width)
            
            let leftPartWidth = locationX - minLeftX
            let rightPartWidth = maxRightX - locationX
            
            guard !locationX.isNaN else { return }
            
            cControlPointView.center = CGPoint(x: locationX, y: baseHeight + waveHeight * 1.36)
            l1ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
            l2ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.44, y: baseHeight)
            l3ControlPointView.center = CGPoint(x: minLeftX, y: baseHeight)
            r1ControlPointView.center = CGPoint(x: maxRightX - rightPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
            r2ControlPointView.center = CGPoint(x: maxRightX - rightPartWidth * 0.44, y: baseHeight)
            r3ControlPointView.center = CGPoint(x: maxRightX, y: baseHeight)
        }
        
        shapeLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        shapeLayer.path = currentPath
        
        layoutLoadingView()
    }
    
    private func layoutLoadingView() {
        guard let loadingView = loadingView else { return }
        
        let width = bounds.size.width
        let height = bounds.size.height
        
        let loadingViewSize = ElasticRefreshLoadingViewSize
        let minOriginY = (ElasticRefreshLoadingContentInset - loadingViewSize) / 2.0
        let originY = max(min((height - loadingViewSize) / 2.0, minOriginY), 0)
        
        loadingView.frame = CGRect(
            x: (width - loadingViewSize) / 2.0,
            y: originY,
            width: loadingViewSize,
            height: loadingViewSize
        )
        
        loadingView.maskLayer.frame = convert(shapeLayer.frame, to: loadingView)
        loadingView.maskLayer.path = shapeLayer.path
    }
    
    // MARK: - Public Methods
    
    /// Stop loading and return to normal state
    open func stopLoading() {
        guard refreshState != .animatingToStopped else { return }
        refreshState = .animatingToStopped
    }
    
    /// Disassociate display link (called when removing from scroll view)
    open func disassociateDisplayLink() {
        displayLink.invalidate()
    }
    
    // MARK: - Notifications
    
    @objc private func applicationWillEnterForeground() {
        if refreshState == .loading {
            setNeedsLayout()
        }
    }
} 