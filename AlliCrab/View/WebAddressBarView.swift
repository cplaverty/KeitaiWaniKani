//
//  WebAddressBarView.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit

class WebAddressBarView: UIView {
    
    // MARK: - Properties
    
    let secureSiteIndicator: UIImageView
    let addressLabel: UILabel
    let refreshButton: UIButton
    
    var url: URL? { didSet { updateUI() } }
    var loading: Bool = false { didSet { updateUI() } }
    
    private let lockImage = UIImage(named: "NavigationBarLock")
    private let stopLoadingImage = UIImage(named: "NavigationBarStopLoading")
    private let reloadImage = UIImage(named: "NavigationBarReload")
    
    private unowned let webView: UIWebView
    
    // MARK: - Initialisers
    
    init(frame: CGRect, forWebView webView: UIWebView) {
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
        refreshButton.removeTarget(self, action: nil, for: .allEvents)
    }
    
    // MARK: - Update UI
    
    func stopOrRefreshWebView(_ sender: UIButton) {
        url = webView.request?.url
        if webView.isLoading {
            webView.stopLoading()
            loading = false
        } else {
            webView.reload()
            loading = true
        }
        updateUI()
    }
    
    private func updateUI() {
        assert(Thread.isMainThread, "Must be called on the main thread")
        
        // Padlock
        secureSiteIndicator.isHidden = url?.scheme != "https"
        
        // URL
        addressLabel.text = domainForURL(url)
        
        // Stop/Reload indicator
        if loading {
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
    
}
