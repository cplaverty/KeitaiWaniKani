//
//  WKWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import CocoaLumberjack
import OnePasswordExtension
import WaniKaniKit

protocol WKWebViewControllerDelegate: class {
    func wkWebViewControllerDidFinish(_ controller: WKWebViewController)
}

class WKWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, WKWebViewControllerDelegate, WebViewBackForwardListTableViewControllerDelegate, WKWebViewUserScriptSupport {
    
    class func forURL(_ URL: Foundation.URL, configBlock: @noescape (WKWebViewController) -> Void = { _ in }) -> UINavigationController {
        let wkWebViewController = self.init(URL: URL)
        configBlock(wkWebViewController)
        
        let nc = UINavigationController(navigationBarClass: nil, toolbarClass: nil)
        if wkWebViewController.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(false, animated: false)
        }
        nc.hidesBarsOnSwipe = true
        nc.hidesBarsWhenVerticallyCompact = true
        
        nc.pushViewController(wkWebViewController, animated: false)
        
        return nc
    }
    
    // MARK: - Initialisers
    
    required init(URL: Foundation.URL) {
        super.init(nibName: nil, bundle: nil)
        self.webView = createWebViewWithConfiguration()
        self.URL = URL
    }
    
    required init(configuration: WKWebViewConfiguration) {
        super.init(nibName: nil, bundle: nil)
        self.webView = createWebViewWithConfiguration(configuration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        webView.scrollView.delegate = nil
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        // Unregister the listeners on the web view
        for webViewObservedKey in self.webViewObservedKeys {
            webView.removeObserver(self, forKeyPath: webViewObservedKey, context: &WKWebViewControllerObservationContext)
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // MARK: - Properties
    
    weak var delegate: WKWebViewControllerDelegate?
    
    var URL: Foundation.URL?
    
    var allowsBackForwardNavigationGestures: Bool { return true }
    
    private static var defaultWebViewConfiguration: WKWebViewConfiguration = {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.processPool = delegate.webKitProcessPool
        if #available(iOS 9.0, *) {
            config.applicationNameForUserAgent = "KeitaiWaniKani"
            config.requiresUserActionForMediaPlayback = false
        } else {
            config.mediaPlaybackRequiresUserAction = false
        }
        
        return config
    }()
    
    private var WKWebViewControllerObservationContext = 0
    
    weak var progressView: UIProgressView!
    private var progressViewIsHidden = true
    
    lazy var statusBarView: UIView = {
        let statusBarView = UIBottomBorderedView(color: UIColor.lightGray, width: 0.5)
        statusBarView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.size.width, height: 20))
        statusBarView.autoresizingMask = .flexibleWidth
        statusBarView.backgroundColor = ApplicationSettings.globalBarTintColor()
        
        return statusBarView
    }()
    
    private let webViewObservedKeys = ["canGoBack", "canGoForward", "estimatedProgress", "loading", "URL"]
    private(set) var webView: WKWebView!
    
    private func createWebViewWithConfiguration(_ webViewConfiguration: WKWebViewConfiguration = defaultWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: CGRect.zero, configuration: webViewConfiguration)
        webView.keyboardDisplayDoesNotRequireUserAction()
        webView.scrollView.delegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = self.allowsBackForwardNavigationGestures
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        
        for webViewObservedKey in self.webViewObservedKeys {
            webView.addObserver(self, forKeyPath: webViewObservedKey, options: [], context: &self.WKWebViewControllerObservationContext)
        }
        
        return webView
    }
    
    lazy var backButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "ArrowLeft"), style: .plain, target: self, action: #selector(backButtonTouched(_:forEvent:)))
        return item
    }()
    lazy var forwardButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "ArrowRight"), style: .plain, target: self, action: #selector(forwardButtonTouched(_:forEvent:)))
        return item
    }()
    lazy var shareButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    }()
    lazy var openInSafariButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "OpenInSafari"), style: .plain, target: self, action: #selector(openInSafari(_:)))
    }()
    lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }()
    
    var shouldIncludeDoneButton: Bool {
        guard let nc = self.navigationController else { return false }
        
        let isFirst = nc.viewControllers.first == self
        let presentingVC = self.presentingViewController
        let presentedVC = presentingVC?.presentedViewController
        
        return isFirst && presentedVC == nc
    }
    
    // MARK: - Actions
    
    func done(_ sender: UIBarButtonItem) {
        delegate?.wkWebViewControllerDidFinish(self)
    }
    
    func share(_ sender: UIBarButtonItem) {
        guard let absoluteURL = webView.url?.absoluteURL else {
            return
        }
        
        var activityItems: [AnyObject] = [absoluteURL]
        let onePasswordExtension = OnePasswordExtension.shared()
        if onePasswordExtension.isAppExtensionAvailable() {
            onePasswordExtension.createExtensionItem(forWebView: webView) { extensionItem, error -> Void in
                if let error = error {
                    DDLogWarn("Failed to create 1Password extension item: \(error)")
                } else if let extensionItem = extensionItem {
                    activityItems.append(extensionItem)
                }
                self.presentActivityViewController(activityItems, title: self.webView.title, sender: sender) {
                    activityType, completed, returnedItems, activityError in
                    if let error = activityError {
                        DDLogWarn("Activity failed: \(error)")
                        return
                    }
                    
                    guard completed else {
                        return
                    }
                    
                    if onePasswordExtension.isOnePasswordExtensionActivityType(activityType) {
                        onePasswordExtension.fillReturnedItems(returnedItems, intoWebView: self.webView) { success, error in
                            if !success {
                                let errorDescription = error?.localizedDescription ?? "(No error details)"
                                DDLogWarn("Failed to fill password from password manager: \(errorDescription)")
                            }
                        }
                    }
                }
            }
        } else {
            presentActivityViewController(activityItems, title: webView.title, sender: sender)
        }
    }
    
    func openInSafari(_ sender: UIBarButtonItem) {
        guard let URL = webView.url else {
            return
        }
        
        UIApplication.shared.openURL(URL)
    }
    
    func backButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.backList, sender: sender)
        case 1: // Tap
            self.webView.goBack()
        default: break
        }
    }
    
    func forwardButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.forwardList, sender: sender)
        case 1: // Tap
            self.webView.goForward()
        default: break
        }
    }
    
    func showBackForwardList(_ backForwardList: [WKBackForwardListItem], sender: UIBarButtonItem) {
        let bflvc = WebViewBackForwardListTableViewController()
        bflvc.backForwardList = backForwardList
        bflvc.delegate = self
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            bflvc.tableView.backgroundColor = UIColor.clear
            let popover = UIPopoverController(contentViewController: bflvc)
            popover.present(from: sender, permittedArrowDirections: [.up, .down], animated: true)
        } else {
            let nc = UINavigationController(rootViewController: bflvc)
            self.present(nc, animated: true, completion: nil)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
//    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
//        switch navigationAction.request.URL {
//        case WaniKaniURLs.subscription?:
//            self.showAlertWithTitle("Can not manage subscription", message: "Due to Apple App Store rules, you can not manage your subscription within the app.")
//            decisionHandler(.Cancel)
//        default:
//            decisionHandler(.Allow)
//        }
//    }
    
//    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
//        decisionHandler(.Allow)
//    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if self.toolbarItems?.isEmpty == false {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
        webView.configuration.userContentController.removeAllUserScripts()
        if let url = webView.url {
            _ = injectUserScripts(forURL: url)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    private func showErrorDialog(_ error: NSError) {
        switch (error.domain, error.code) {
        // Ignore navigation cancellation errors
        case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102):
            break
        default:
            showAlertWithTitle("Failed to load page", message: error.localizedDescription ?? "Unknown error")
        }
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newVC = self.dynamicType.init(configuration: configuration)
        newVC.delegate = self
        newVC.URL = navigationAction.request.url
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return newVC.webView
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let host = frame.request.url?.host ?? "web page"
        let title = "From \(host):"
        DispatchQueue.main.async {
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        let host = frame.request.url?.host ?? "web page"
        let title = "From \(host):"
        DispatchQueue.main.async {
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        let host = frame.request.url?.host ?? "web page"
        let title = "From \(host):"
        DispatchQueue.main.async {
            DDLogInfo("Displaying input panel with title \(title) and message \(prompt)")
            let alert = UIAlertController(title: title, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard let nc = navigationController, nc.isNavigationBarHidden else { return true }
        
        showBrowserInterface(true, animated: true)
        return false
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(_ controller: WKWebViewController) {
        self.delegate?.wkWebViewControllerDidFinish(self)
    }
    
    // MARK: - WebViewBackForwardListTableViewControllerDelegate
    
    func webViewBackForwardListTableViewController(_ controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem) {
        controller.dismiss(animated: true, completion: nil)
        self.webView.go(to: item)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(webView)
        self.view.addSubview(statusBarView)
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        
        configureForTraitCollection(self.traitCollection)
        
        if let nc = self.navigationController {
            let navBar = nc.navigationBar
            
            let progressView = UIProgressView(progressViewStyle: .default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.trackTintColor = UIColor.clear
            progressView.progress = 0.0
            progressView.alpha = 0.0
            navBar.addSubview(progressView)
            self.progressView = progressView
            
            NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: navBar, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: navBar, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .bottom, relatedBy: .equal, toItem: navBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            
            let addressBarView = WKWebAddressBarView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: navBar.bounds.width, height: 28)), forWebView: webView)
            addressBarView.autoresizingMask = [.flexibleWidth]
            self.navigationItem.titleView = addressBarView
        }
        
        if let url = self.URL {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass || newCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            configureForTraitCollection(newCollection)
        }
    }
    
    /// Sets the navigation bar and toolbar items based on the given UITraitCollection
    func configureForTraitCollection(_ traitCollection: UITraitCollection) {
        statusBarView.isHidden = traitCollection.verticalSizeClass == .compact
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            addToolbarItemsForCompactWidthRegularHeight()
        } else {
            addToolbarItemsForAllOtherTraitCollections()
        }
    }
    
    /// For iPhone in portrait
    func addToolbarItemsForCompactWidthRegularHeight() {
        self.navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = shouldIncludeDoneButton ? [doneButton] : nil
        let flexibleSpace = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
        setToolbarItems([backButton, flexibleSpace(), forwardButton, flexibleSpace(), shareButton, flexibleSpace(), openInSafariButton], animated: true)
    }
    
    /// For iPad and iPhone in landscape
    func addToolbarItemsForAllOtherTraitCollections() {
        self.navigationController?.setToolbarHidden(true, animated: true)
        setToolbarItems(nil, animated: true)
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItems = [backButton, forwardButton]
        navigationItem.rightBarButtonItems = shouldIncludeDoneButton ? [doneButton, openInSafariButton, shareButton] : [openInSafariButton, shareButton]
    }
    
    // MARK: - Implementation
    
    func presentActivityViewController(_ activityItems: [AnyObject], title: String?, sender: UIBarButtonItem, completionHandler: UIActivityViewControllerCompletionWithItemsHandler? = nil) {
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        avc.popoverPresentationController?.barButtonItem = sender;
        avc.completionWithItemsHandler = completionHandler
        if let title = title {
            avc.setValue(title, forKey: "subject")
        }
        
        navigationController?.present(avc, animated: true, completion: nil)
    }
    
    private func updateUIFromWebView() {
        // Network indicator
        UIApplication.shared.isNetworkActivityIndicatorVisible = webView.isLoading
        
        // Loading progress
        let shouldHideProgress = !webView.isLoading
        if !progressViewIsHidden && shouldHideProgress {
            UIView.animate(withDuration: 0.1) {
                self.progressView?.setProgress(1.0, animated: false)
            }
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn],
                animations: {
                    self.progressView?.alpha = 0.0
                },
                completion: { _ in
                    self.progressView?.setProgress(0.0, animated: false)
            })
            
            progressViewIsHidden = true
        } else if progressViewIsHidden && !shouldHideProgress {
            progressView?.setProgress(0.0, animated: false)
            progressView?.alpha = 1.0
            progressView?.setProgress(Float(webView.estimatedProgress), animated: true)
            
            progressViewIsHidden = false
        } else if !progressViewIsHidden && !shouldHideProgress{
            progressView?.setProgress(Float(webView.estimatedProgress), animated: true)
        }
        
        // Navigation buttons
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        shareButton.isEnabled = !webView.isLoading && webView.url != nil
        openInSafariButton.isEnabled = webView.url != nil
    }
    
    func fillUsing1Password(_ sender: AnyObject!) {
        OnePasswordExtension.shared().fillItem(intoWebView: self.webView, for: self, sender: sender, showOnlyLogins: true) { success, error in
            if (!success) {
                DDLogWarn("Failed to fill password into webview: <\(error)>")
            } else {
                DDLogDebug("Filled login using password manager")
            }
        }
    }
    
    func showBrowserInterface(_ showBrowserInterface: Bool, animated: Bool) {
        guard let nc = self.navigationController else { return }
        
        nc.setNavigationBarHidden(!showBrowserInterface, animated: animated)
        if self.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(!showBrowserInterface, animated: animated)
        }
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &WKWebViewControllerObservationContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if object === self.webView {
            updateUIFromWebView()
        }
    }
}
