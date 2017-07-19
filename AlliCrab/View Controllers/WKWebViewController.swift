//
//  WKWebViewController.swift
//  AlliCrab
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

private enum MessageHandlerName: String {
    case interop = "interop"
    
    static let all: [MessageHandlerName] = [.interop]
}

class WKWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIScrollViewDelegate, WKWebViewControllerDelegate, WebViewBackForwardListTableViewControllerDelegate, WKWebViewUserScriptSupport {
    
    class func wrapped(url: URL, configBlock: ((WKWebViewController) -> Void)?) -> UINavigationController {
        let wkWebViewController = self.init(url: url)
        configBlock?(wkWebViewController)
        
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
    
    required init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
    }
    
    required init(configuration: WKWebViewConfiguration) {
        super.init(nibName: nil, bundle: nil)
        self.webViewConfiguration = configuration
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
    
    var allowsBackForwardNavigationGestures: Bool { return true }
    
    var url: URL?
    
    var webViewConfiguration: WKWebViewConfiguration?
    
    private var defaultWebViewConfiguration: WKWebViewConfiguration {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let config = WKWebViewConfiguration()
        registerMessageHandlers(config.userContentController)
        config.allowsInlineMediaPlayback = true
        config.processPool = delegate.webKitProcessPool
        
        if #available(iOS 10.0, *) {
            config.ignoresViewportScaleLimits = true
        }
        
        if #available(iOS 9.0, *) {
            config.applicationNameForUserAgent = "Mobile AlliCrab"
        }
        
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = [.video]
        } else if #available(iOS 9.0, *) {
            config.requiresUserActionForMediaPlayback = false
        } else {
            config.mediaPlaybackRequiresUserAction = false
        }
        
        return config
    }
    
    private var WKWebViewControllerObservationContext = 0
    
    weak var progressView: UIProgressView!
    private var progressViewIsHidden = true
    
    lazy var statusBarView: UIView = {
        let view = UIBottomBorderedView(frame: UIApplication.shared.statusBarFrame, color: .lightGray, width: 0.5)
        view.autoresizingMask = .flexibleWidth
        view.backgroundColor = ApplicationSettings.globalBarTintColor
        
        return view
    }()
    
    private let webViewObservedKeys = ["canGoBack", "canGoForward", "estimatedProgress", "loading", "URL"]
    private(set) weak var webView: WKWebView!
    
    private func createWebView() -> WKWebView {
        let webView = WKWebView(frame: self.view.bounds, configuration: webViewConfiguration ?? defaultWebViewConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = self.allowsBackForwardNavigationGestures
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        webView.keyboardDisplayDoesNotRequireUserAction()
        
        for webViewObservedKey in self.webViewObservedKeys {
            webView.addObserver(self, forKeyPath: webViewObservedKey, options: [], context: &self.WKWebViewControllerObservationContext)
        }
        
        return webView
    }
    
    lazy var backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ArrowLeft"), style: .plain, target: self, action: #selector(backButtonTouched(_:forEvent:)))
    }()
    lazy var forwardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ArrowRight"), style: .plain, target: self, action: #selector(forwardButtonTouched(_:forEvent:)))
    }()
    lazy var shareButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    }()
    lazy var openInSafariButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "OpenInSafari"), style: .plain, target: self, action: #selector(openInSafari(_:)))
    }()
    lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(done(_:)))
    }()
    
    private var shouldIncludeDoneButton: Bool = false
    
    // MARK: - Actions
    
    func done(_ sender: UIBarButtonItem) {
        finish()
    }
    
    func share(_ sender: UIBarButtonItem) {
        guard let absoluteURL = webView.url?.absoluteURL else {
            return
        }
        
        var activityItems: [AnyObject] = [absoluteURL as NSURL]
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
                    
                    if onePasswordExtension.isOnePasswordExtensionActivityType(activityType.map { $0.rawValue }) {
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
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL)
        } else {
            UIApplication.shared.openURL(URL)
        }
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
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if self.toolbarItems?.isEmpty == false {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
        injectUserScripts(to: webView)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        injectUserScripts(to: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        
        switch url {
        case WaniKaniURLs.lessonSession, WaniKaniURLs.reviewSession:
            showBrowserInterface(false, animated: true)
        default: break
        }
    }
    
    private func injectUserScripts(to webView: WKWebView) {
        webView.configuration.userContentController.removeAllUserScripts()
        if let url = webView.url {
            _ = injectUserScripts(for: url)
        }
    }
    
    private func showErrorDialog(_ error: Error) {
        let nserror = error as NSError
        switch (nserror.domain, nserror.code) {
        // Ignore navigation cancellation errors
        case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102):
            break
        default:
            showAlert(title: "Failed to load page", message: error.localizedDescription)
        }
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newVC = type(of: self).init(configuration: configuration)
        newVC.delegate = self
        newVC.url = navigationAction.request.url
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return newVC.webView
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            let host = frame.request.url?.host ?? "web page"
            let title = "From \(host):"
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let host = frame.request.url?.host ?? "web page"
            let title = "From \(host):"
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let host = frame.request.url?.host ?? "web page"
            let title = "From \(host):"
            DDLogInfo("Displaying input panel with title \(title) and message \(prompt)")
            let alert = UIAlertController(title: title, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageName = MessageHandlerName(rawValue: message.name) else {
            DDLogWarn("Received unhandled message name \(message.name) with \(message.body)")
            return
        }
        
        switch messageName {
        case .interop:
            guard let command = message.body as? String else {
                DDLogWarn("Failed to convert message body! \(message.body)")
                return
            }
            
            switch command {
            default:
                DDLogWarn("Received unhandled command \(command) in \(message.body)")
            }
            break
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
        finish()
    }
    
    // MARK: - WebViewBackForwardListTableViewControllerDelegate
    
    func webViewBackForwardListTableViewController(_ controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem) {
        controller.dismiss(animated: true, completion: nil)
        self.webView.go(to: item)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = self.createWebView()
        self.webView = webView
        
        self.view.addSubview(webView)
        self.view.addSubview(statusBarView)
        
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[statusBarView]", options: [], metrics: nil, views: ["statusBarView": statusBarView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[statusBarView]|", options: [], metrics: nil, views: ["statusBarView": statusBarView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        
        if let nc = self.navigationController {
            shouldIncludeDoneButton = nc == self.presentingViewController?.presentedViewController && nc.viewControllers.first == self
            
            let navBar = nc.navigationBar
            
            let progressView = UIProgressView(progressViewStyle: .default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.trackTintColor = .clear
            progressView.progress = 0.0
            progressView.alpha = 0.0
            navBar.addSubview(progressView)
            self.progressView = progressView
            
            NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: navBar, attribute: .leading, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: navBar, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: progressView, attribute: .bottom, relatedBy: .equal, toItem: navBar, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
            
            let addressBarView = WKWebAddressBarView(frame: CGRect(origin: .zero, size: CGSize(width: navBar.bounds.width, height: 28)), forWebView: webView)
            addressBarView.autoresizingMask = [.flexibleWidth]
            self.navigationItem.titleView = addressBarView
        }
        
        configureToolbars(for: self.traitCollection)
        
        if let url = self.url {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass || newCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            configureToolbars(for: newCollection)
        }
    }
    
    /// Sets the navigation bar and toolbar items based on the given UITraitCollection
    func configureToolbars(for traitCollection: UITraitCollection) {
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
        navigationItem.leftBarButtonItems = customLeftBarButtonItems
        navigationItem.rightBarButtonItems = customRightBarButtonItems
        let flexibleSpace = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
        setToolbarItems([backButton, flexibleSpace(), forwardButton, flexibleSpace(), shareButton, flexibleSpace(), openInSafariButton], animated: true)
    }
    
    /// For iPad and iPhone in landscape
    func addToolbarItemsForAllOtherTraitCollections() {
        self.navigationController?.setToolbarHidden(true, animated: true)
        setToolbarItems(nil, animated: true)
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItems = customLeftBarButtonItems + [backButton, forwardButton]
        navigationItem.rightBarButtonItems = customRightBarButtonItems + [openInSafariButton, shareButton]
    }
    
    var customLeftBarButtonItems: [UIBarButtonItem] {
        var buttons: [UIBarButtonItem] = []
        buttons.reserveCapacity(1)
        
        if #available(iOS 10.0, *) {
            if shouldIncludeDoneButton {
                buttons.append(doneButton)
            }
        }
        
        return buttons
    }
    
    var customRightBarButtonItems: [UIBarButtonItem] {
        var buttons: [UIBarButtonItem] = []
        buttons.reserveCapacity(1)
        
        if #available(iOS 10.0, *) {
        } else {
            if shouldIncludeDoneButton {
                buttons.append(doneButton)
            }
        }
        
        return buttons
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
        configureToolbars(for: traitCollection)
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        shareButton.isEnabled = !webView.isLoading && webView.url != nil
        openInSafariButton.isEnabled = webView.url != nil
    }
    
    func fillUsing1Password(_ sender: AnyObject!) {
        OnePasswordExtension.shared().fillItem(intoWebView: self.webView, for: self, sender: sender, showOnlyLogins: true) { success, error in
            if (!success) {
                DDLogWarn("Failed to fill password into webview: \(String(describing: error))")
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
    
    func finish() {
        unregisterMessageHandlers(webView.configuration.userContentController)
        delegate?.wkWebViewControllerDidFinish(self)
    }
    
    func registerMessageHandlers(_ userContentController: WKUserContentController) {
        DDLogVerbose("Registering command handlers")
        for name in MessageHandlerName.all {
            userContentController.add(self, name: name.rawValue)
        }
    }
    
    func unregisterMessageHandlers(_ userContentController: WKUserContentController) {
        DDLogVerbose("Unregistering command handlers")
        for name in MessageHandlerName.all {
            userContentController.removeScriptMessageHandler(forName: name.rawValue)
        }
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &WKWebViewControllerObservationContext else {
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
