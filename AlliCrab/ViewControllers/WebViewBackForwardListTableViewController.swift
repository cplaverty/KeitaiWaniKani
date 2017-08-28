//
//  WebViewBackForwardListTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
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
        
        navigationItem.title = "History"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        
        if UIAccessibilityIsReduceTransparencyEnabled() {
            tableView.backgroundColor = .white
        } else {
            tableView.backgroundColor = .clear
        }
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
        cell.backgroundColor = .clear
        
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

// MARK: - UIPopoverPresentationControllerDelegate
extension WebViewBackForwardListTableViewController: UIPopoverPresentationControllerDelegate {
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if style == .popover || style == .none {
            return nil
        }
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
    
    func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        if style == .popover || style == .none {
            let vc = presentationController.presentedViewController as! WebViewBackForwardListTableViewController
            if UIAccessibilityIsReduceTransparencyEnabled() {
                vc.tableView.backgroundColor = .white
            } else {
                vc.tableView.backgroundColor = .clear
            }
            return
        }
        let vc = presentationController.presentedViewController as! WebViewBackForwardListTableViewController
        vc.tableView.backgroundColor = .white
    }
}
