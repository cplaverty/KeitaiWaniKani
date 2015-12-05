//
//  WebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import OnePasswordExtension
import WaniKaniKit

protocol WebViewControllerDelegate: class {
    func webViewControllerDidFinish(controller: WebViewController)
}

class WebViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, WebViewControllerDelegate {
    
    private struct SegueIdentifiers {
        static let showBackHistory = "Show Web Back History"
        static let showForwardHistory = "Show Web Forward History"
    }
    
    class func forURL(URL: NSURL, @noescape configBlock: (WebViewController) -> Void) -> UINavigationController {
        let webViewController = self.init(URL: URL)
        configBlock(webViewController)
        
        let nc = UINavigationController(navigationBarClass: nil, toolbarClass: nil)
        if webViewController.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(false, animated: false)
        }
        nc.hidesBarsOnSwipe = true
        nc.hidesBarsWhenVerticallyCompact = true
        
        nc.pushViewController(webViewController, animated: false)
        
        return nc
    }
    
    // MARK: - Initialisers
    
    required init(URL: NSURL) {
        super.init(nibName: nil, bundle: nil)
        self.URL = URL
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        webView.scrollView.delegate = nil
        webView.delegate = nil
        backScreenEdgePanGesture?.removeTarget(self, action: nil)
        forwardScreenEdgePanGesture?.removeTarget(self, action: nil)
    }
    
    // MARK: - Properties
    
    weak var delegate: WebViewControllerDelegate?
    var allowsBackForwardNavigationGestures: Bool = true
    
    var URL: NSURL?
    private var webViewPageTitle: String?
    private(set) var requestStack: [NSURLRequest] = []
    
    weak var progressView: UIProgressView!
    private var progressViewIsHidden = true
    private var estimatedLoadingProgress: Float = 0
    
    var addressBarView: WebAddressBarView!
    
    func createWebView() -> UIWebView {
        let webView = UIWebView(frame: self.view.bounds)
        webView.scrollView.delegate = self
        webView.delegate = self
        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        webView.backgroundColor = UIColor.whiteColor()
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        
        return webView
    }
    
    lazy var statusBarView: UIView = {
        let statusBarView = UIBottomBorderedView(color: UIColor.lightGrayColor(), width: 1)
        statusBarView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.size.width, height: 20))
        statusBarView.autoresizingMask = .FlexibleWidth
        statusBarView.backgroundColor = ApplicationSettings.globalBarTintColor()
        
        return statusBarView
    }()
    
    lazy var webView: UIWebView = self.createWebView()
    
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
        return self.navigationController?.viewControllers.first == self
    }
    
    private var backScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer?
    private var forwardScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer?
    
    // MARK: - Actions
    
    func done(sender: UIBarButtonItem) {
        delegate?.webViewControllerDidFinish(self)
    }
    
    func share(sender: UIBarButtonItem) {
        guard let absoluteURL = webView.request?.URL?.absoluteURL else {
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
                self.presentActivityViewController(activityItems, title: self.webViewPageTitle, sender: sender) {
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
            presentActivityViewController(activityItems, title: webViewPageTitle, sender: sender)
        }
    }
    
    func openInSafari(sender: UIBarButtonItem) {
        guard let URL = webView.request?.URL else {
            return
        }
        
        UIApplication.sharedApplication().openURL(URL)
    }
    
    func backButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func backScreenEdgePanGestureTriggered(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        if gestureRecognizer.state == .Ended && webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardScreenEdgePanGestureTriggered(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        if gestureRecognizer.state == .Ended && webView.canGoForward {
            webView.goForward()
        }
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        DDLogVerbose("shouldStartLoadWithRequest: \(request) navigationType: \(navigationType)")
        if requestStack.isEmpty {
            addressBarView.URL = request.URL
        }
        requestStack.append(request)
        estimatedLoadingProgress = 0
        switch request.URL {
        case WaniKaniURLs.subscription?:
            self.showAlertWithTitle("Can not manage subscription", message: "Due to Apple App Store rules, you can not manage your subscription within the app.")
            return false
        default:
            return true
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        let requestStarted = requestStack.last!
        DDLogVerbose("webViewDidStartLoad webView.request: \(requestStarted)")
        // Start load of new page
        if requestStack.count == 1 {
            estimatedLoadingProgress = 0.1
            webViewPageTitle = nil
            addressBarView.loading = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            if self.toolbarItems?.isEmpty == false {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
        }
        updateUIFromWebView()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let requestFinished = requestStack.popLast()
        DDLogVerbose("webViewDidFinishLoad webView.request: \(requestFinished)")
        // Finish load of new page
        if requestStack.isEmpty {
            estimatedLoadingProgress = 1
            if let documentTitle = webView.stringByEvaluatingJavaScriptFromString("document.title") where !documentTitle.isEmpty {
                webViewPageTitle = documentTitle
            }
            addressBarView.URL = webView.request?.URL
            addressBarView.loading = false
        }
        updateUIFromWebView()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        DDLogWarn("Navigation failed: \(error)")
        addressBarView.URL = webView.request?.URL
        addressBarView.loading = false
        requestStack.removeAll()
        updateUIFromWebView()
        
        if let error = error where error.domain != "WebKitErrorDomain" && error.code != 102 {
            switch (error.domain, error.code) {
                // Ignore navigation cancellation errors
            case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102):
                break
            default:
                showAlertWithTitle("Failed to load page", message: error.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        guard let nc = navigationController where nc.navigationBarHidden else { return true }
        
        showBrowserInterface(true, animated: true)
        return false
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(controller: WebViewController) {
        self.delegate?.webViewControllerDidFinish(self)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(webView)
        self.view.addSubview(statusBarView)
        
        if allowsBackForwardNavigationGestures {
            backScreenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: "backScreenEdgePanGestureTriggered:")
            backScreenEdgePanGesture!.edges = .Left
            forwardScreenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: "forwardScreenEdgePanGestureTriggered:")
            forwardScreenEdgePanGesture!.edges = .Right
            webView.scrollView.addGestureRecognizer(backScreenEdgePanGesture!)
            webView.scrollView.addGestureRecognizer(forwardScreenEdgePanGesture!)
            webView.scrollView.panGestureRecognizer.requireGestureRecognizerToFail(backScreenEdgePanGesture!)
            webView.scrollView.panGestureRecognizer.requireGestureRecognizerToFail(forwardScreenEdgePanGesture!)
        }
        
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
            
            addressBarView = WebAddressBarView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: navBar.bounds.width, height: 28)), forWebView: webView)
            addressBarView.autoresizingMask = [.FlexibleWidth]
            self.navigationItem.titleView = addressBarView
        }
        
        if let url = self.URL {
            let request = NSURLRequest(URL: url)
            self.webView.loadRequest(request)
        }
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        statusBarView.hidden = newCollection.verticalSizeClass == .Compact
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass || newCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            configureForTraitCollection(newCollection)
        }
    }
    
    /// Sets the navigation bar and toolbar items based on the given UITraitCollection
    func configureForTraitCollection(traitCollection: UITraitCollection) {
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
    
    func injectStyleSheet(name: String, inWebView webView: UIWebView) {
        guard let ssURL = NSBundle.mainBundle().URLForResource(name, withExtension: "css") else {
            fatalError("Count not find style sheet \(name).css in main bundle")
        }
        let contents = encodeForJavascript(try! String(contentsOfURL: ssURL))
        
        let script = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
            DDLogError("Failed to add style sheet \(name).css")
        }
    }
    
    func injectScript(name: String, inWebView webView: UIWebView) {
        guard let scriptURL = NSBundle.mainBundle().URLForResource(name, withExtension: "js") else {
            fatalError("Count not find user script \(name).js in main bundle")
        }
        let contents = encodeForJavascript(try! String(contentsOfURL: scriptURL))
        
        let script = "var script = document.createElement('script');script.setAttribute('type', 'text/javascript');script.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).js'));document.head.appendChild(script);"
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
            DDLogError("Failed to add script \(name).js")
        }
    }
    
    private func encodeForJavascript(string: String) -> String  {
        return string.unicodeScalars.map({$0.escape(asASCII: false)}).joinWithSeparator("")
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
        UIApplication.sharedApplication().networkActivityIndicatorVisible = addressBarView.loading
        
        // Loading progress
        let shouldHideProgress = !addressBarView.loading
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
            progressView?.setProgress(estimatedLoadingProgress, animated: true)
            
            progressViewIsHidden = false
        } else if !progressViewIsHidden && !shouldHideProgress{
            progressView?.setProgress(estimatedLoadingProgress, animated: true)
        }
        
        // Navigation buttons
        backButton.enabled = webView.canGoBack
        forwardButton.enabled = webView.canGoForward
        shareButton.enabled = webView.request?.URL != nil
        openInSafariButton.enabled = webView.request?.URL != nil
    }
    
    func fillUsing1Password(sender: AnyObject!) {
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(self.webView, forViewController: self, sender: sender, showOnlyLogins: true) { success, error in
            if (!success) {
                DDLogWarn("Failed to fill password into webview: \(error)")
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
    
}

extension UIWebViewNavigationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case LinkClicked: return "LinkClicked"
        case FormSubmitted: return "FormSubmitted"
        case BackForward: return "BackForward"
        case Reload: return "Reload"
        case FormResubmitted: return "FormResubmitted"
        case Other: return "Other"
        }
    }
}

private class UIBottomBorderedView: UIView {
    private let borderLayer: CALayer
    private let borderWidth: CGFloat
    
    init(color: UIColor, width: CGFloat) {
        borderLayer = CALayer()
        borderLayer.backgroundColor = color.CGColor
        borderWidth = width
        super.init(frame: CGRect.zero)
        self.layer.addSublayer(borderLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = CGRect(x: 0, y: max(0, self.frame.size.height - borderWidth), width: self.frame.size.width, height: borderWidth)
    }
}
