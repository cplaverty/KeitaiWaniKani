//
//  WKWebAddressBarView.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit

class WKWebAddressBarView: UIView {
    
    // MARK: - Properties
    
    let secureSiteIndicator: UIImageView
    let addressLabel: UILabel
    let refreshButton: UIButton
    
    private let lockImage = UIImage(named: "NavigationBarLock")
    private let stopLoadingImage = UIImage(named: "NavigationBarStopLoading")
    private let reloadImage = UIImage(named: "NavigationBarReload")
    
    private var observationContext = 0
    private let webViewObservedKeys = ["hasOnlySecureContent", "loading", "URL"]
    private let webView: WKWebView
    
    // MARK: - Initialisers
    
    init(frame: CGRect, forWebView webView: WKWebView) {
        self.webView = webView
        secureSiteIndicator = UIImageView(image: lockImage)
        secureSiteIndicator.translatesAutoresizingMaskIntoConstraints = false
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.setContentCompressionResistancePriority(addressLabel.contentCompressionResistancePriorityForAxis(.Horizontal) - 1, forAxis: .Horizontal)
        refreshButton = UIButton(type: .Custom)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5
        self.opaque = false
        self.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        
        refreshButton.addTarget(self, action: #selector(stopOrRefreshWebView(_:)), forControlEvents: .TouchUpInside)
        
        for webViewObservedKey in webViewObservedKeys {
            webView.addObserver(self, forKeyPath: webViewObservedKey, options: [], context: &observationContext)
        }
        
        updateUIFromWebView()
        addSubview(secureSiteIndicator)
        addSubview(addressLabel)
        addSubview(refreshButton)
        
        let views = [
            "secureSiteIndicator": secureSiteIndicator,
            "addressLabel": addressLabel,
            "refreshButton": refreshButton
        ]
        
        NSLayoutConstraint(item: secureSiteIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: addressLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: refreshButton, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        
        NSLayoutConstraint(item: addressLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(>=8)-[secureSiteIndicator]-[addressLabel]-(>=8)-[refreshButton]-|", options: [], metrics: nil, views: views))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(>=4)-[addressLabel]-(>=4)-|", options: [], metrics: nil, views: views))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Unregister the listeners on the web view
        for webViewObservedKey in webViewObservedKeys {
            webView.removeObserver(self, forKeyPath: webViewObservedKey, context: &observationContext)
        }
    }
    
    // MARK: - Update UI
    
    func stopOrRefreshWebView(sender: UIButton) {
        if webView.loading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }
    
    private func updateUIFromWebView() {
        // Padlock
        secureSiteIndicator.hidden = !webView.hasOnlySecureContent
        
        // URL
        addressLabel.text = domainForURL(webView.URL)
        
        // Stop/Reload indicator
        if webView.loading {
            refreshButton.setImage(stopLoadingImage, forState: .Normal)
        } else {
            refreshButton.setImage(reloadImage, forState: .Normal)
        }
    }
    
    let hostPrefixesToStrip = ["m.", "www."]
    private func domainForURL(URL: NSURL?) -> String? {
        guard let host = URL?.host?.lowercaseString else {
            return nil
        }
        
        for prefix in hostPrefixesToStrip {
            if let range = host.rangeOfString(prefix, options: [.AnchoredSearch]) {
                return host.substringFromIndex(range.endIndex)
            }
        }
        return host
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &observationContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if object === self.webView {
            updateUIFromWebView()
        }
    }
    
}