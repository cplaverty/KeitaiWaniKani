//
//  WebViewBackForwardListTableViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit

protocol WebViewBackForwardListTableViewControllerDelegate: class {
    func webViewBackForwardListTableViewController(_ controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem)
}

class WebViewBackForwardListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var backForwardList: [WKBackForwardListItem]?
    weak var delegate: WebViewBackForwardListTableViewControllerDelegate?
    
    private let cellIdentifier = "BackForwardListTableViewCell"
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "History"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backForwardList?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        cell.backgroundColor = UIColor.clear
        
        let backForwardListItem = backForwardList![indexPath.row]
        cell.textLabel?.text = backForwardListItem.title
        cell.detailTextLabel?.text = backForwardListItem.url.absoluteString
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let backForwardListItem = backForwardList![indexPath.row]
        delegate?.webViewBackForwardListTableViewController(self, didSelectBackForwardListItem: backForwardListItem)
    }
    
}
