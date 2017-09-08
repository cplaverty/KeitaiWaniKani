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
    
    private let contentView: UIView
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
        
        contentView = UIView(frame: frame)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
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
        
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        contentView.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 8
        contentView.isOpaque = false
        
        refreshButton.addTarget(self, action: #selector(stopOrRefreshWebView(_:)), for: .touchUpInside)
        
        keyValueObservers = registerObservers(webView)
        
        addSubview(contentView)
        contentView.addSubview(secureSiteIndicator)
        contentView.addSubview(addressLabel)
        contentView.addSubview(refreshButton)
        contentView.addSubview(progressView)
        
        contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        
        let views: [String: Any] = [
            "secureSiteIndicator": secureSiteIndicator,
            "addressLabel": addressLabel,
            "refreshButton": refreshButton
        ]
        
        secureSiteIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        addressLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        if #available(iOS 11, *) {
            addressLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
            contentView.layoutMarginsGuide.bottomAnchor.constraint(greaterThanOrEqualTo: addressLabel.bottomAnchor).isActive = true
        } else {
            addressLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor).isActive = true
            contentView.bottomAnchor.constraint(greaterThanOrEqualTo: addressLabel.bottomAnchor).isActive = true
        }
        refreshButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        addressLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=8)-[secureSiteIndicator]-[addressLabel]-(>=8)-[refreshButton]-|", options: [], metrics: nil, views: views))
        
        progressView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
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
