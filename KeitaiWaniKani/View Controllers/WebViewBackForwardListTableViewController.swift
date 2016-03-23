//
//  WebViewBackForwardListTableViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit

protocol WebViewBackForwardListTableViewControllerDelegate: class {
    func webViewBackForwardListTableViewController(controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem)
}

class WebViewBackForwardListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var backForwardList: [WKBackForwardListItem]?
    weak var delegate: WebViewBackForwardListTableViewControllerDelegate?
    
    private let cellIdentifier = "BackForwardListTableViewCell"
    
    // MARK: - Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "History"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(done(_:)))
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return backForwardList?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) ?? UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
        cell.backgroundColor = UIColor.clearColor()
        
        let backForwardListItem = backForwardList![indexPath.row]
        cell.textLabel?.text = backForwardListItem.title
        cell.detailTextLabel?.text = backForwardListItem.URL.absoluteString
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let backForwardListItem = backForwardList![indexPath.row]
        delegate?.webViewBackForwardListTableViewController(self, didSelectBackForwardListItem: backForwardListItem)
    }
    
}
