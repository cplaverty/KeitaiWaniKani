//
//  WebAddressBarView.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WebKit

class WebAddressBarView: UIView {
    
    // MARK: - Properties
    
    private let secureSiteIndicator: UIImageView
    private let addressLabel: UILabel
    private let refreshButton: UIButton
    private let progressView: UIProgressView
    
    private let lockImage = UIImage(named: "NavigationBarLock")
    private let stopLoadingImage = UIImage(named: "NavigationBarStopLoading")
    private let reloadImage = UIImage(named: "NavigationBarReload")
    
    private unowned let webView: WKWebView
    private var keyValueObservers: [NSKeyValueObservation]?
    
    // MARK: - Initialisers
    
    required init(frame: CGRect, forWebView webView: WKWebView) {
        self.webView = webView
        secureSiteIndicator = UIImageView(image: lockImage)
        secureSiteIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addressLabel = UILabel()
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addressLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        if #available(iOS 10.0, *) {
            addressLabel.adjustsFontForContentSizeCategory = true
        }
        
        refreshButton = UIButton(type: .custom)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .clear
        progressView.progress = 0.0
        progressView.alpha = 0.0
        
        super.init(frame: frame)
        
        self.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        self.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        self.clipsToBounds = true
        self.layer.cornerRadius = 8
        self.isOpaque = false
        
        refreshButton.addTarget(self, action: #selector(stopOrRefreshWebView(_:)), for: .touchUpInside)
        
        keyValueObservers = registerObservers(webView)
        
        addSubview(secureSiteIndicator)
        addSubview(addressLabel)
        addSubview(refreshButton)
        addSubview(progressView)
        
        let views: [String : Any] = [
            "secureSiteIndicator": secureSiteIndicator,
            "addressLabel": addressLabel,
            "refreshButton": refreshButton
        ]
        
        secureSiteIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        addressLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        addressLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        bottomAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 4).isActive = true
        refreshButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        addressLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=8)-[secureSiteIndicator]-[addressLabel]-(>=8)-[refreshButton]-|", options: [], metrics: nil, views: views))
        
        progressView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Update UI
    
    private func registerObservers(_ webView: WKWebView) -> [NSKeyValueObservation] {
        let keyValueObservers = [
            webView.observe(\.hasOnlySecureContent, options: [.initial]) { [unowned self] webView, _ in
                self.secureSiteIndicator.isHidden = !webView.hasOnlySecureContent
            },
            webView.observe(\.url, options: [.initial]) { [unowned self] webView, _ in
                self.addressLabel.text = self.host(for: webView.url)
            },
            webView.observe(\.estimatedProgress, options: [.initial]) { [unowned self] webView, _ in
                let animated = webView.isLoading && self.progressView.progress < Float(webView.estimatedProgress)
                self.progressView.setProgress(Float(webView.estimatedProgress), animated: animated)
            },
            webView.observe(\.isLoading, options: [.initial]) { [unowned self] webView, _ in
                if webView.isLoading {
                    self.progressView.alpha = 1.0
                    self.refreshButton.setImage(self.stopLoadingImage, for: .normal)
                } else {
                    UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseIn], animations: { self.progressView.alpha = 0.0 })
                    self.refreshButton.setImage(self.reloadImage, for: .normal)
                }
            }
        ]
        
        return keyValueObservers
    }
    
    @objc func stopOrRefreshWebView(_ sender: UIButton) {
        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
    }
    
    private let hostPrefixesToStrip = ["m.", "www."]
    private func host(for url: URL?) -> String? {
        guard let host = url?.host?.lowercased() else {
            return nil
        }
        
        for prefix in hostPrefixesToStrip {
            if host.hasPrefix(prefix) {
                return String(host.dropFirst(prefix.count))
            }
        }
        return host
    }
    
}
