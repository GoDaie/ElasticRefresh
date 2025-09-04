//
//  ElasticRefreshExample.swift
//  
//  Usage example for JElasticPullToRefresh Swift version
//  Created by iOS Senior Engineer on 2024/12/19.
//  Copyright © 2024 iOS Development Team. All rights reserved.
//

import UIKit

// MARK: - Example Usage

class ElasticRefreshExampleViewController: UIViewController {
    
    // MARK: - Properties
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return table
    }()
    
    private var dataSource = Array(1...50)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        setupElasticRefresh()
        setupWithCustomLoadingView()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Elastic Pull to Refresh Example"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupElasticRefresh() {
        // IMPORTANT: Setup swizzling once in your app lifecycle (e.g., in AppDelegate)
        UIScrollView.setupElasticRefresh()
        
        // Create custom loading view (optional)
        let loadingView = ElasticRefreshLoadingViewCircle()
        loadingView.tintColor = .white
        
        // Add elastic pull to refresh
        tableView.addElasticRefreshView(actionHandler: { [weak self] in
            self?.performRefresh()
        }, loadingView: loadingView)
        
        // Customize appearance
        tableView.setElasticRefreshBackgroundColor(.clear)
//        tableView.setElasticRefreshFillColor(.systemBlue.withAlphaComponent(0.3))
    }
    
    private func performRefresh() {
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Add new items to simulate refresh
            let newItems = Array((self.dataSource.count + 1)...(self.dataSource.count + 10))
            self.dataSource.insert(contentsOf: newItems, at: 0)
            
            // Reload table data
            self.tableView.reloadData()
            
            // Stop loading animation
            self.tableView.stopLoading()
        }
    }
    
    deinit {
        // Clean up (optional, but good practice)
        tableView.removeElasticRefreshView()
    }
}

// MARK: - TableView DataSource & Delegate

extension ElasticRefreshExampleViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "Item \(dataSource[indexPath.row])"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Advanced Usage Examples

extension ElasticRefreshExampleViewController {
    
    /// Example: Custom loading view
    func setupWithCustomLoadingView() {
        // Create custom loading view by subclassing ElasticRefreshLoadingView
        class CustomLoadingView: ElasticRefreshLoadingView {
            
            private let activityIndicator = UIActivityIndicatorView(style: .medium)
            
            override func setPullProgress(_ progress: CGFloat) {
                super.setPullProgress(progress)
                alpha = progress
            }
            
            override func startAnimating() {
                super.startAnimating()
                activityIndicator.startAnimating()
            }
            
            override func stopLoading() {
                super.stopLoading()
                activityIndicator.stopAnimating()
            }
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                addSubview(activityIndicator)
                activityIndicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
                activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
        
        let customLoadingView = CustomLoadingView()
        
        tableView.addElasticRefreshView(actionHandler: { [weak self] in
            self?.performRefresh()
        }, loadingView: customLoadingView)
    }
    
    /// Example: ScrollView usage (not just TableView)
    func setupWithScrollView() {
        let scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: view.bounds.width, height: 2000)
        
        scrollView.addElasticRefreshView(actionHandler: {
            // Handle refresh for scroll view
            print("ScrollView refresh triggered!")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                scrollView.stopLoading()
            }
        })
        
        // Set custom colors
        scrollView.setElasticRefreshFillColor(.systemRed)
    }
} 
