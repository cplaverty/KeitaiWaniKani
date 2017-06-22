//
//  WKWebAddressBarView.swift
//  AlliCrab
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
        addressLabel.setContentCompressionResistancePriority(addressLabel.contentCompressionResistancePriority(for: .horizontal) - 1, for: .horizontal)
        refreshButton = UIButton(type: .custom)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5
        self.isOpaque = false
        self.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        
        refreshButton.addTarget(self, action: #selector(stopOrRefreshWebView(_:)), for: .touchUpInside)
        
        for webViewObservedKey in webViewObservedKeys {
            webView.addObserver(self, forKeyPath: webViewObservedKey, options: [], context: &observationContext)
        }
        
        updateUIFromWebView()
        addSubview(secureSiteIndicator)
        addSubview(addressLabel)
        addSubview(refreshButton)
        
        let views: [String : Any] = [
            "secureSiteIndicator": secureSiteIndicator,
            "addressLabel": addressLabel,
            "refreshButton": refreshButton
        ]
        
        NSLayoutConstraint(item: secureSiteIndicator, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: addressLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: refreshButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        
        NSLayoutConstraint(item: addressLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=8)-[secureSiteIndicator]-[addressLabel]-(>=8)-[refreshButton]-|", options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=4)-[addressLabel]-(>=4)-|", options: [], metrics: nil, views: views))
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
    
    func stopOrRefreshWebView(_ sender: UIButton) {
        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }
    
    private func updateUIFromWebView() {
        // Padlock
        secureSiteIndicator.isHidden = !webView.hasOnlySecureContent
        
        // URL
        addressLabel.text = domainForURL(webView.url)
        
        // Stop/Reload indicator
        if webView.isLoading {
            refreshButton.setImage(stopLoadingImage, for: UIControlState())
        } else {
            refreshButton.setImage(reloadImage, for: UIControlState())
        }
    }
    
    let hostPrefixesToStrip = ["m.", "www."]
    private func domainForURL(_ URL: Foundation.URL?) -> String? {
        guard let host = URL?.host?.lowercased() else {
            return nil
        }
        
        for prefix in hostPrefixesToStrip {
            if let range = host.range(of: prefix, options: [.anchored]) {
                return host.substring(from: range.upperBound)
            }
        }
        return host
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if object as AnyObject? === self.webView {
            DispatchQueue.main.async { [weak self] in
                self?.updateUIFromWebView()
            }
        }
    }
    
}
