//
//  WebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import JavaScriptCore
import UIKit
import CocoaLumberjack
import OnePasswordExtension
import WaniKaniKit

private struct NavigationBarSettings {
    let toolbarHidden: Bool
    let hidesBarsOnSwipe: Bool
    let hidesBarsWhenVerticallyCompact: Bool
    
    init(navigationController nc: UINavigationController) {
        self.toolbarHidden = nc.toolbarHidden
        self.hidesBarsOnSwipe = nc.hidesBarsOnSwipe
        self.hidesBarsWhenVerticallyCompact = nc.hidesBarsWhenVerticallyCompact
    }
    
    func applyToNavigationController(nc: UINavigationController) {
        nc.toolbarHidden = self.toolbarHidden
        nc.hidesBarsOnSwipe = self.hidesBarsOnSwipe
        nc.hidesBarsWhenVerticallyCompact = self.hidesBarsWhenVerticallyCompact
    }
}

protocol WebViewControllerDelegate: class {
    func webViewControllerDidFinish(controller: WebViewController)
}

class WebViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, WebViewControllerDelegate, BundleResourceLoader {
    
    class func forURL(URL: NSURL, @noescape configBlock: (WebViewController) -> Void) -> UINavigationController {
        let webViewController = self.init(URL: URL)
        configBlock(webViewController)
        
        let nc = UINavigationController(navigationBarClass: nil, toolbarClass: nil)
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
        webView?.delegate = nil
        backScreenEdgePanGesture?.removeTarget(self, action: nil)
        forwardScreenEdgePanGesture?.removeTarget(self, action: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    // MARK: - Properties
    
    weak var jsContext: JSContext?
    weak var delegate: WebViewControllerDelegate?
    var allowsBackForwardNavigationGestures: Bool { return true }
    
    var URL: NSURL?
    private var lastRequest: NSURLRequest? = nil
    private(set) var requestStack: [NSURLRequest] = []
    private var userScriptsInjected = false
    private var navigationBarSettings: NavigationBarSettings? = nil
    
    func createWebView() -> UIWebView {
        let webView = UIWebView(frame: self.view.bounds)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.delegate = self
        webView.delegate = self
        webView.backgroundColor = UIColor.whiteColor()
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        
        return webView
    }
    
    weak var webView: UIWebView?
    
    lazy var statusBarView: UIView = {
        let statusBarView = UIBottomBorderedView(color: UIColor.lightGrayColor(), width: 0.5)
        statusBarView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.frame.size.width, height: 20))
        statusBarView.autoresizingMask = .FlexibleWidth
        statusBarView.backgroundColor = ApplicationSettings.globalBarTintColor()
        
        return statusBarView
    }()
    
    lazy var backButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ArrowLeft"), style: .Plain, target: self, action: "backButtonTouched:forEvent:")
    }()
    lazy var forwardButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ArrowRight"), style: .Plain, target: self, action: "forwardButtonTouched:forEvent:")
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
        guard let webView = self.webView, let absoluteURL = webView.request?.URL?.absoluteURL else {
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
                self.presentActivityViewController(activityItems, title: self.title, sender: sender) {
                    activityType, completed, returnedItems, activityError in
                    if let error = activityError {
                        DDLogWarn("Activity failed: \(error)")
                        return
                    }
                    
                    guard completed else {
                        return
                    }
                    
                    if onePasswordExtension.isOnePasswordExtensionActivityType(activityType) {
                        onePasswordExtension.fillReturnedItems(returnedItems, intoWebView: webView) { success, error in
                            if !success {
                                let errorDescription = error?.description ?? "(No error details)"
                                DDLogWarn("Failed to fill password from password manager: \(errorDescription)")
                            }
                        }
                    }
                }
            }
        } else {
            presentActivityViewController(activityItems, title: title, sender: sender)
        }
    }
    
    func openInSafari(sender: UIBarButtonItem) {
        guard let URL = webView?.request?.URL else {
            return
        }
        
        UIApplication.sharedApplication().openURL(URL)
    }
    
    func backButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let webView = self.webView else { return }
        
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardButtonTouched(sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let webView = self.webView else { return }
        
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func backScreenEdgePanGestureTriggered(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let webView = self.webView else { return }
        
        if gestureRecognizer.state == .Ended && webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardScreenEdgePanGestureTriggered(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let webView = self.webView else { return }
        
        if gestureRecognizer.state == .Ended && webView.canGoForward {
            webView.goForward()
        }
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        DDLogVerbose("shouldStartLoadWithRequest: \(request) navigationType: \(navigationType)")
        lastRequest = request
        switch request.URL {
        case WaniKaniURLs.subscription?:
            self.showAlertWithTitle("Can not manage subscription", message: "Please use Safari to manage your subscription.")
            return false
        default:
            return true
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        if let request = lastRequest {
            requestStack.append(request)
            if let requestURLStarted = request.URL
                where requestURLStarted == WaniKaniURLs.loginPage || requestURLStarted == WaniKaniURLs.lessonSession || requestURLStarted == WaniKaniURLs.reviewSession {
                    DDLogDebug("Clearing user script injection flag")
                    userScriptsInjected = false
            }
        }
        DDLogVerbose("webViewDidStartLoad webView.request: \(requestStack.last?.description ?? "<none>")")
        // Start load of new page
        if requestStack.count == 1 {
            title = "Loading..."
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            if self.toolbarItems?.isEmpty == false {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
        }
        updateUIFromWebView()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        jsContext = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
        let setTitle: @convention(block) String -> Void = { [weak self] title in self?.title = title }
        jsContext?.setObject(unsafeBitCast(setTitle, AnyObject.self), forKeyedSubscript: "setWebViewPageTitle")
        
        let requestFinished = requestStack.popLast()
        DDLogVerbose("webViewDidFinishLoad webView.request: \(requestFinished)")
        // Finish load of new page
        if requestStack.isEmpty {
            if let documentTitle = webView.stringByEvaluatingJavaScriptFromString("document.title") where !documentTitle.isEmpty {
                title = documentTitle
            }
            lastRequest = nil
        }
        updateUIFromWebView()
        
        if !userScriptsInjected {
            if let URL = webView.request?.URL {
                injectUserScriptsForURL(URL)
            }
        }
    }
    
    func injectUserScriptsForURL(URL: NSURL) {
        guard let webView = self.webView else { return }
        
        // Common user scripts
        switch URL {
        case WaniKaniURLs.loginPage:
            DDLogDebug("Loading user scripts")
            injectScript("common", inWebView: webView)
            userScriptsInjected = true
        case WaniKaniURLs.lessonSession:
            showBrowserInterface(false, animated: true)
            DDLogDebug("Loading user scripts")
            injectScript("common", inWebView: webView)
            injectStyleSheet("resize", inWebView: webView)
            if ApplicationSettings.disableLessonSwipe {
                injectScript("noswipe", inWebView: webView)
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript("WKU.user", inWebView: webView)
            }
            userScriptsInjected = true
        case WaniKaniURLs.reviewSession:
            showBrowserInterface(false, animated: true)
            DDLogDebug("Loading user scripts")
            injectScript("common", inWebView: webView)
            injectStyleSheet("resize", inWebView: webView)
            if ApplicationSettings.userScriptJitaiEnabled {
                injectScript("jitai.user", inWebView: webView)
            }
            if ApplicationSettings.userScriptIgnoreAnswerEnabled {
                injectScript("wkoverride.user", inWebView: webView)
            }
            if ApplicationSettings.userScriptDoubleCheckEnabled {
                injectScript("wkdoublecheck", inWebView: webView)
            }
            if ApplicationSettings.userScriptWaniKaniImproveEnabled {
                injectStyleSheet("jquery.qtip.min", inWebView: webView)
                injectScript("jquery.qtip.min", inWebView: webView)
                injectScript("wkimprove", inWebView: webView)
            }
            if ApplicationSettings.userScriptMarkdownNotesEnabled {
                injectScript("showdown.min", inWebView: webView)
                injectScript("markdown.user", inWebView: webView)
            }
            if ApplicationSettings.userScriptHideMnemonicsEnabled {
                injectScript("wkhidem.user", inWebView: webView)
            }
            if ApplicationSettings.userScriptReorderUltimateEnabled {
                injectScript("WKU.user", inWebView: webView)
            }
            userScriptsInjected = true
        default: break
        }
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        DDLogWarn("Navigation failed: \(error)")
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
        
        if let nc = self.navigationController {
            navigationBarSettings = NavigationBarSettings(navigationController: nc)
        }
        
        let webView = self.createWebView()
        self.webView = webView
        
        self.view.addSubview(webView)
        NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: webView, attribute: .Leading, relatedBy: .Equal, toItem: self.view, attribute: .Leading, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: webView, attribute: .Trailing, relatedBy: .Equal, toItem: self.view, attribute: .Trailing, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1, constant: 0).active = true

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
        
        if let url = self.URL {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nc = self.navigationController {
            if toolbarItems?.isEmpty == false {
                nc.setToolbarHidden(false, animated: false)
            }
            nc.hidesBarsOnSwipe = true
            nc.hidesBarsWhenVerticallyCompact = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let nc = self.navigationController {
            navigationBarSettings?.applyToNavigationController(nc)
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
    
    func injectStyleSheet(name: String, inWebView webView: UIWebView) {
        let contents = loadBundleResource(name, withExtension: "css", javascriptEncode: true)
        
        let script = "var style = document.createElement('style');style.setAttribute('type', 'text/css');style.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).css'));document.head.appendChild(style);"
        
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
            DDLogError("Failed to add style sheet \(name).css")
        }
    }
    
    func injectScript(name: String, inWebView webView: UIWebView) {
        let contents = loadBundleResource(name, withExtension: "js", javascriptEncode: true)
        
        let script = "var script = document.createElement('script');script.setAttribute('type', 'text/javascript');script.appendChild(document.createTextNode('\(contents)'));document.head.appendChild(document.createComment('\(name).js'));document.head.appendChild(script);"
        if webView.stringByEvaluatingJavaScriptFromString(script) == nil {
            DDLogError("Failed to add script \(name).js")
        }
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
        UIApplication.sharedApplication().networkActivityIndicatorVisible = webView?.loading ?? false
        
        // Navigation buttons
        backButton.enabled = webView?.canGoBack ?? false
        forwardButton.enabled = webView?.canGoForward ?? false
        shareButton.enabled = webView?.request?.URL != nil
        openInSafariButton.enabled = webView?.request?.URL != nil
    }
    
    func fillUsing1Password(sender: AnyObject!) {
        guard let webView = self.webView else { return }
        
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(webView, forViewController: self, sender: sender, showOnlyLogins: true) { success, error in
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
