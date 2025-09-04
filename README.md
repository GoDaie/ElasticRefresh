# ElasticRefresh

## ✨ Features

- 🌊 **Elastic Wave Animation** - Unique elastic wave effect during pull-to-refresh
- 🎨 **Highly Customizable** - Customize colors, animation timing, and loading views
- 🚀 **Pure Swift** - Written in modern Swift 5.0+ with type safety
- 📱 **Universal** - Works with UITableView, UICollectionView, and UIScrollView
- ⚡ **High Performance** - Optimized animations with smooth 60fps performance
- 🛡️ **Memory Safe** - Proper memory management with weak references
- 🎯 **Easy Integration** - Simple one-line setup with powerful customization options

![image](https://github.com/GoDaie/ElasticRefresh/blob/main/refresh.gif)

```ruby
# Add to your Podfile
pod 'ElasticRefresh'
```


## 🚀 Quick Start

### Basic Usage

```swift
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // IMPORTANT: Call this once in your app lifecycle (e.g., AppDelegate)
        UIScrollView.setupElasticRefresh()
        
        // Add elastic refresh to your table view
        tableView.addElasticRefreshView(actionHandler: { [weak self] in
            self?.refreshData()
        })
    }
    
    private func refreshData() {
        // Perform your data refresh here
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Reload your data
            self.tableView.reloadData()
            
            // Stop the refresh animation
            self.tableView.stopLoading()
        }
    }
}
```
