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
    func wkWebViewControllerDidFinish(controller: WKWebViewController)
}

class WKWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, WKWebViewControllerDelegate, WebViewBackForwardListTableViewControllerDelegate, BundleResourceLoader {
    
    class func forURL(URL: NSURL, @noescape configBlock: (WKWebViewController) -> Void = { _ in }) -> UINavigationController {
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
    
    required init(URL: NSURL) {
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
        webView.UIDelegate = nil
        // Unregister the listeners on the web view
        for webViewObservedKey in self.webViewObservedKeys {
            webView.removeObserver(self, forKeyPath: webViewObservedKey, context: &WKWebViewControllerObservationContext)
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    // MARK: - Properties
    
    weak var delegate: WKWebViewControllerDelegate?
    
    var URL: NSURL?
    
    var allowsBackForwardNavigationGestures: Bool { return true }
    
    private static var defaultWebViewConfiguration: WKWebViewConfiguration = {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
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
        let statusBarView = UIBottomBorderedView(color: UIColor.lightGrayColor(), width: 0.5)
        statusBarView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.size.width, height: 20))
        statusBarView.autoresizingMask = .FlexibleWidth
        statusBarView.backgroundColor = ApplicationSettings.globalBarTintColor()
        
        return statusBarView
    }()
    
    private let webViewObservedKeys = ["canGoBack", "canGoForward", "estimatedProgress", "loading", "URL"]
    private(set) var webView: WKWebView!
    
    private func createWebViewWithConfiguration(webViewConfiguration: WKWebViewConfiguration = defaultWebViewConfiguration) -> WKWebView {
        let webView = WKWebView(frame: CGRect.zero, configuration: webViewConfiguration)
        webView.scrollView.delegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.UIDelegate = self
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
        let item = UIBarButtonItem(image: UIImage(named: "ArrowLeft"), style: .Plain, target: self, action: "backButtonTouched:forEvent:")
        return item
    }()
    lazy var forwardButton: UIBarButtonItem = {
        let item = UIBarButtonItem(image: UIImage(named: "ArrowRight"), style: .Plain, target: self, action: "forwardButtonTouched:forEvent:")
        return item
    }()
    lazy var shareButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share:")
    }()
    lazy var openInSafariButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "OpenInSafari"), style: .Plain, target: self, action: "openInSafari:")
    }()
    lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "done:")
    }()
    
    var shouldIncludeDoneButton: Bool {
        guard let nc = self.navigationController else { return false }
        
        let isFirst = nc.viewControllers.first == self
        let presentingVC = self.presentingViewController
        let presentedVC = presentingVC?.presentedViewController
        
        return isFirst && presentedVC == nc
    }
    
    // MARK: - Actions
    
    func done(sender: UIBarButtonItem) {
        delegate?.wkWebViewControllerDidFinish(self)
    }
    
    func share(sender: UIBarButtonItem) {
        guard let absoluteURL = webView.URL?.absoluteURL else {
            return
        }
        
        var activityItems: [AnyObject] = [absoluteURL]
        let onePasswordExtension = OnePasswordExtension.sharedExtension()
        if onePasswordExtension.isAppExtensionAvailable() {
            onePasswordExtension.createExtensionItemForWebView(webView) { extensionItem, error -> Void in
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
                                let errorDescription = error?.description ?? "(No error details)"
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
    
    func openInSafari(sender: UIBarButtonItem) {
        guard let URL = webView.URL else {
            return
        }
        
        UIApplication.sharedApplication().openURL(URL)
    }
    
    func backButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches()?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.backList, sender: sender)
        case 1: // Tap
            self.webView.goBack()
        default: break
        }
    }
    
    func forwardButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches()?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.forwardList, sender: sender)
        case 1: // Tap
            self.webView.goForward()
        default: break
        }
    }
    
    func showBackForwardList(backForwardList: [WKBackForwardListItem], sender: UIBarButtonItem) {
        let bflvc = WebViewBackForwardListTableViewController()
        bflvc.backForwardList = backForwardList
        bflvc.delegate = self
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            bflvc.tableView.backgroundColor = UIColor.clearColor()
            let popover = UIPopoverController(contentViewController: bflvc)
            popover.presentPopoverFromBarButtonItem(sender, permittedArrowDirections: [.Up, .Down], animated: true)
        } else {
            let nc = UINavigationController(rootViewController: bflvc)
            self.presentViewController(nc, animated: true, completion: nil)
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.request.URL {
        case WaniKaniURLs.subscription?:
            self.showAlertWithTitle("Can not manage subscription", message: "Due to Apple App Store rules, you can not manage your subscription within the app.")
            decisionHandler(.Cancel)
        default:
            decisionHandler(.Allow)
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.Allow)
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if self.toolbarItems?.isEmpty == false {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        DDLogWarn("Navigation failed: \(error)")
        showErrorDialog(error)
    }
    
    private func showErrorDialog(error: NSError) {
        switch (error.domain, error.code) {
            // Ignore navigation cancellation errors
        case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102):
            break
        default:
            showAlertWithTitle("Failed to load page", message: error.localizedDescription ?? "Unknown error")
        }
    }
    
    // MARK: - WKUIDelegate
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newVC = self.dynamicType.init(configuration: configuration)
        newVC.delegate = self
        newVC.URL = navigationAction.request.URL
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return newVC.webView
    }
    
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let host = frame.request.URL?.host ?? "web page"
        let title = "From \(host):"
        dispatch_async(dispatch_get_main_queue()) {
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in completionHandler() })
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        let host = frame.request.URL?.host ?? "web page"
        let title = "From \(host):"
        dispatch_async(dispatch_get_main_queue()) {
            DDLogInfo("Displaying alert with title \(title) and message \(message)")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in completionHandler(true) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { _ in completionHandler(false) })
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        let host = frame.request.URL?.host ?? "web page"
        let title = "From \(host):"
        dispatch_async(dispatch_get_main_queue()) {
            DDLogInfo("Displaying input panel with title \(title) and message \(prompt)")
            let alert = UIAlertController(title: title, message: prompt, preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in completionHandler(alert.textFields?.first?.text) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { _ in completionHandler(nil) })
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        guard let nc = navigationController where nc.navigationBarHidden else { return true }
        
        showBrowserInterface(true, animated: true)
        return false
    }
    
    // MARK: - WKWebViewControllerDelegate
    
    func wkWebViewControllerDidFinish(controller: WKWebViewController) {
        self.delegate?.wkWebViewControllerDidFinish(self)
    }
    
    // MARK: - WebViewBackForwardListTableViewControllerDelegate
    
    func webViewBackForwardListTableViewController(controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        self.webView.goToBackForwardListItem(item)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userContentController = webView.configuration.userContentController
        userContentController.removeAllUserScripts()
        if let userScripts = getUserScripts() {
            for script in userScripts {
                userContentController.addUserScript(script)
            }
        }
        
        self.view.addSubview(webView)
        self.view.addSubview(statusBarView)
        
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[webView]|", options: [], metrics: nil, views: ["webView": webView]))
        
        configureForTraitCollection(self.traitCollection)
        
        if let nc = self.navigationController {
            let navBar = nc.navigationBar
            
            let progressView = UIProgressView(progressViewStyle: .Default)
            progressView.translatesAutoresizingMaskIntoConstraints = false
            progressView.trackTintColor = UIColor.clearColor()
            progressView.progress = 0.0
            progressView.alpha = 0.0
            navBar.addSubview(progressView)
            self.progressView = progressView
            
            NSLayoutConstraint(item: progressView, attribute: .Leading, relatedBy: .Equal, toItem: navBar, attribute: .Leading, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressView, attribute: .Trailing, relatedBy: .Equal, toItem: navBar, attribute: .Trailing, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: progressView, attribute: .Bottom, relatedBy: .Equal, toItem: navBar, attribute: .Bottom, multiplier: 1, constant: 0).active = true
            
            let addressBarView = WKWebAddressBarView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: navBar.bounds.width, height: 28)), forWebView: webView)
            addressBarView.autoresizingMask = [.FlexibleWidth]
            self.navigationItem.titleView = addressBarView
        }
        
        if let url = self.URL {
            let request = NSURLRequest(URL: url)
            self.webView.loadRequest(request)
        }
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass || newCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            configureForTraitCollection(newCollection)
        }
    }
    
    /// Sets the navigation bar and toolbar items based on the given UITraitCollection
    func configureForTraitCollection(traitCollection: UITraitCollection) {
        statusBarView.hidden = traitCollection.verticalSizeClass == .Compact
        if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular {
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
        let flexibleSpace = { UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil) }
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
    
    // MARK: - User Scripts
    
    func getUserScripts() -> [WKUserScript]? {
        return nil
    }
    
    func getUserScriptContent(name: String) -> String {
        guard let scriptURL = NSBundle.mainBundle().URLForResource("\(name)", withExtension: "js") else {
            fatalError("Count not find user script \(name).js in main bundle")
        }
        return try! String(contentsOfURL: scriptURL)
    }
    
    // MARK: - Implementation
    
    func presentActivityViewController(activityItems: [AnyObject], title: String?, sender: UIBarButtonItem, completionHandler: UIActivityViewControllerCompletionWithItemsHandler? = nil) {
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        avc.popoverPresentationController?.barButtonItem = sender;
        avc.completionWithItemsHandler = completionHandler
        if let title = title {
            avc.setValue(title, forKey: "subject")
        }
        
        navigationController?.presentViewController(avc, animated: true, completion: nil)
    }
    
    private func updateUIFromWebView() {
        // Network indicator
        UIApplication.sharedApplication().networkActivityIndicatorVisible = webView.loading
        
        // Loading progress
        let shouldHideProgress = !webView.loading
        if !progressViewIsHidden && shouldHideProgress {
            UIView.animateWithDuration(0.1) {
                self.progressView?.setProgress(1.0, animated: false)
            }
            UIView.animateWithDuration(0.3, delay: 0.0, options: [.CurveEaseIn],
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
        backButton.enabled = webView.canGoBack
        forwardButton.enabled = webView.canGoForward
        shareButton.enabled = !webView.loading && webView.URL != nil
        openInSafariButton.enabled = webView.URL != nil
    }
    
    func fillUsing1Password(sender: AnyObject!) {
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(self.webView, forViewController: self, sender: sender, showOnlyLogins: true) { success, error in
            if (!success) {
                DDLogWarn("Failed to fill password into webview: <\(error)>")
            } else {
                DDLogDebug("Filled login using password manager")
            }
        }
    }
    
    func showBrowserInterface(showBrowserInterface: Bool, animated: Bool) {
        guard let nc = self.navigationController else { return }
        
        nc.setNavigationBarHidden(!showBrowserInterface, animated: animated)
        if self.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(!showBrowserInterface, animated: animated)
        }
    }
    
    // MARK: - Key-Value Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &WKWebViewControllerObservationContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if object === self.webView {
            updateUIFromWebView()
        }
    }
}