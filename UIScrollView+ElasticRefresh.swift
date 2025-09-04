//
//  UIScrollView+ElasticRefresh.swift
//
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit
import ObjectiveC

// MARK: - Associated Object Keys

private var ObserversKey: UInt8 = 0
private var ElasticRefreshViewKey: UInt8 = 0

// MARK: - UIScrollView Extension

extension UIScrollView {
    
    // MARK: - Associated Properties
    
    /// Set of observers for tracking KVO observers
    private var observers: NSMutableSet? {
        get {
            return objc_getAssociatedObject(self, &ObserversKey) as? NSMutableSet
        }
        set {
            objc_setAssociatedObject(self, &ObserversKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// The elastic pull to refresh view instance
    public var elasticRefreshView: ElasticRefreshView? {
        get {
            return objc_getAssociatedObject(self, &ElasticRefreshViewKey) as? ElasticRefreshView
        }
        set {
            objc_setAssociatedObject(self, &ElasticRefreshViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Observer Management
    
    /// Override addObserver to track observers
    @objc dynamic func elastic_addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutableRawPointer?) {
        let observerID = "\(observer.hash)\(keyPath)"
        
        if observers == nil {
            observers = NSMutableSet()
        }
        observers?.add(observerID)
        
        elastic_addObserver(observer, forKeyPath: keyPath, options: options, context: context)
    }
    
    /// Override removeObserver to track observers
    @objc dynamic func elastic_removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        let observerID = "\(observer.hash)\(keyPath)"
        
        if let observers = observers, observers.contains(observerID) {
            observers.remove(observerID)
            elastic_removeObserver(observer, forKeyPath: keyPath)
        }
    }
    
    // MARK: - Public Methods
    
    /// Add elastic pull to refresh functionality
    /// - Parameters:
    ///   - actionHandler: Closure called when refresh is triggered
    ///   - loadingView: Custom loading view (optional)
    public func addElasticRefreshView(actionHandler: @escaping ElasticRefreshActionHandler, loadingView: ElasticRefreshLoadingView? = nil) {
        // Configure scroll view for single touch
        isMultipleTouchEnabled = false
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        // Create and configure refresh view
        let refreshView = ElasticRefreshView()
        elasticRefreshView = refreshView
        refreshView.actionHandler = actionHandler
        refreshView.loadingView = loadingView ?? ElasticRefreshLoadingViewCircle()
        
        addSubview(refreshView)
        refreshView.observing = true
    }
    
    /// Remove elastic pull to refresh view
    public func removeElasticRefreshView() {
        guard let refreshView = elasticRefreshView else { return }
        
        refreshView.disassociateDisplayLink()
        refreshView.observing = false
        refreshView.removeFromSuperview()
        elasticRefreshView = nil
    }
    
    /// Set background color for the refresh view
    /// - Parameter color: Background color
    public func setElasticRefreshBackgroundColor(_ color: UIColor) {
        elasticRefreshView?.backgroundColor = color
    }
    
    /// Set fill color for the wave animation
    /// - Parameter color: Fill color
    public func setElasticRefreshFillColor(_ color: UIColor) {
        elasticRefreshView?.fillColor = color
    }
    
    /// Stop loading animation and return to normal state
    public func stopLoading() {
        elasticRefreshView?.stopLoading()
    }
}

// MARK: - Method Swizzling

extension UIScrollView {
    
    /// Swizzle methods for observer management
    @objc static func swizzleObserverMethods() {
        let originalAddObserver = class_getInstanceMethod(UIScrollView.self, #selector(addObserver(_:forKeyPath:options:context:)))
        let swizzledAddObserver = class_getInstanceMethod(UIScrollView.self, #selector(elastic_addObserver(_:forKeyPath:options:context:)))
        
        let originalRemoveObserver = class_getInstanceMethod(UIScrollView.self, #selector(removeObserver(_:forKeyPath:)))
        let swizzledRemoveObserver = class_getInstanceMethod(UIScrollView.self, #selector(elastic_removeObserver(_:forKeyPath:)))
        
        if let originalAdd = originalAddObserver, let swizzledAdd = swizzledAddObserver {
            method_exchangeImplementations(originalAdd, swizzledAdd)
        }
        
        if let originalRemove = originalRemoveObserver, let swizzledRemove = swizzledRemoveObserver {
            method_exchangeImplementations(originalRemove, swizzledRemove)
        }
        
        // Swizzle dealloc
        let originalDealloc = class_getInstanceMethod(UIScrollView.self, NSSelectorFromString("dealloc"))
        let swizzledDealloc = class_getInstanceMethod(UIScrollView.self, #selector(elastic_dealloc))
        
        if let originalDeallocMethod = originalDealloc, let swizzledDeallocMethod = swizzledDealloc {
            method_exchangeImplementations(originalDeallocMethod, swizzledDeallocMethod)
        }
    }
    
    /// Swizzled dealloc method
    @objc dynamic func elastic_dealloc() {
        removeElasticRefreshView()
        elastic_dealloc()
    }
    
    /// Setup method swizzling (call this once in app lifecycle)
    public static func setupElasticRefresh() {
        let onceToken = "UIScrollView+ElasticRefresh.swizzle"
        _ = UIScrollView.__once(token: onceToken) {
            UIScrollView.swizzleObserverMethods()
        }
    }
}

// MARK: - Once Token Helper

extension NSObject {
    private static var _onceTokens = Set<String>()
    private static let _onceTokensLock = NSLock()
    
    static func __once(token: String, closure: () -> Void) {
        _onceTokensLock.lock()
        defer { _onceTokensLock.unlock() }
        
        if !_onceTokens.contains(token) {
            _onceTokens.insert(token)
            closure()
        }
    }
} 