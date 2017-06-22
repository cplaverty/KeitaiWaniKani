//
//  WebViewController.swift
//  AlliCrab
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
        self.toolbarHidden = nc.isToolbarHidden
        self.hidesBarsOnSwipe = nc.hidesBarsOnSwipe
        self.hidesBarsWhenVerticallyCompact = nc.hidesBarsWhenVerticallyCompact
    }
    
    func applyToNavigationController(_ nc: UINavigationController) {
        nc.isToolbarHidden = self.toolbarHidden
        nc.hidesBarsOnSwipe = self.hidesBarsOnSwipe
        nc.hidesBarsWhenVerticallyCompact = self.hidesBarsWhenVerticallyCompact
    }
}

protocol WebViewControllerDelegate: class {
    func webViewControllerDidFinish(_ controller: WebViewController)
}

class WebViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, WebViewControllerDelegate, UIWebViewUserScriptSupport {
    
    class func wrapped(url: URL, configBlock: ((WebViewController) -> Void)?) -> UINavigationController {
        let webViewController = self.init(url: url)
        configBlock?(webViewController)
        
        let nc = UINavigationController(navigationBarClass: nil, toolbarClass: nil)
        nc.pushViewController(webViewController, animated: false)
        
        return nc
    }
    
    // MARK: - Initialisers
    
    required init(url: URL) {
        super.init(nibName: nil, bundle: nil)
        self.url = url
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        webView?.delegate = nil
        backScreenEdgePanGesture?.removeTarget(self, action: nil)
        forwardScreenEdgePanGesture?.removeTarget(self, action: nil)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // MARK: - Properties
    
    weak var jsContext: JSContext?
    weak var delegate: WebViewControllerDelegate?
    var allowsBackForwardNavigationGestures: Bool { return true }
    
    var url: URL?
    private var lastRequest: URLRequest? = nil
    private(set) var requestStack: [URLRequest] = []
    private var userScriptsInjected = false
    private var navigationBarSettings: NavigationBarSettings? = nil
    
    var addressBarView: WebAddressBarView!
    
    private func createWebView() -> UIWebView {
        let webView = UIWebView(frame: self.view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.delegate = self
        webView.delegate = self
        webView.backgroundColor = .white
        webView.allowsInlineMediaPlayback = true
        webView.mediaPlaybackRequiresUserAction = false
        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = true
        }
        
        return webView
    }
    
    weak var webView: UIWebView?
    
    lazy var statusBarView: UIView = {
        let statusBarView = UIBottomBorderedView(frame: UIApplication.shared.statusBarFrame, color: .lightGray, width: 0.5)
        statusBarView.autoresizingMask = .flexibleWidth
        statusBarView.backgroundColor = ApplicationSettings.globalBarTintColor
        
        return statusBarView
    }()
    
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
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }()
    
    var shouldIncludeDoneButton: Bool {
        return self.navigationController?.viewControllers.first == self
    }
    
    private var backScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer?
    private var forwardScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer?
    
    // MARK: - Actions
    
    func done(_ sender: UIBarButtonItem) {
        delegate?.webViewControllerDidFinish(self)
    }
    
    func share(_ sender: UIBarButtonItem) {
        guard let webView = self.webView, let absoluteURL = webView.request?.url?.absoluteURL else {
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
                self.presentActivityViewController(activityItems, title: self.title, sender: sender) {
                    activityType, completed, returnedItems, activityError in
                    if let error = activityError {
                        DDLogWarn("Activity failed: \(error)")
                        return
                    }
                    
                    guard completed else {
                        return
                    }
                    
                    if onePasswordExtension.isOnePasswordExtensionActivityType(activityType.map { $0.rawValue }) {
                        onePasswordExtension.fillReturnedItems(returnedItems, intoWebView: webView) { success, error in
                            if !success {
                                let errorDescription = error?.localizedDescription ?? "(No error details)"
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
    
    func openInSafari(_ sender: UIBarButtonItem) {
        guard let URL = webView?.request?.url else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL)
        } else {
            UIApplication.shared.openURL(URL)
        }
    }
    
    func backButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let webView = self.webView else { return }
        
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let webView = self.webView else { return }
        
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    func backScreenEdgePanGestureTriggered(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let webView = self.webView else { return }
        
        if gestureRecognizer.state == .ended && webView.canGoBack {
            webView.goBack()
        }
    }
    
    func forwardScreenEdgePanGestureTriggered(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let webView = self.webView else { return }
        
        if gestureRecognizer.state == .ended && webView.canGoForward {
            webView.goForward()
        }
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        DDLogVerbose("shouldStartLoadWithRequest: \(request) navigationType: \(navigationType)")
        lastRequest = request
        if requestStack.isEmpty {
            addressBarView.url = request.url
        }
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        if let request = lastRequest {
            requestStack.append(request)
            if let requestURLStarted = request.url,
                requestURLStarted == WaniKaniURLs.loginPage || requestURLStarted == WaniKaniURLs.lessonSession || requestURLStarted == WaniKaniURLs.reviewSession {
                DDLogDebug("Clearing user script injection flag")
                userScriptsInjected = false
            }
        }
        DDLogVerbose("webViewDidStartLoad webView.request: \(requestStack.last?.description ?? "<none>")")
        // Start load of new page
        if requestStack.count == 1 {
            title = "Loading..."
            addressBarView.loading = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            if self.toolbarItems?.isEmpty == false {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
        }
        updateUIFromWebView()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
        let endEditing: @convention(block) () -> Void = { [weak self] in
            DispatchQueue.main.async {
                DDLogVerbose("Forcing endEditing")
                self?.webView?.endEditing(true)
            }
        }
        jsContext?.setObject(unsafeBitCast(endEditing, to: AnyObject.self), forKeyedSubscript: "endEditing" as NSString)
        
        let requestFinished = requestStack.popLast()
        DDLogVerbose("webViewDidFinishLoad webView.request: \(String(describing: requestFinished))")
        // Finish load of new page
        if requestStack.isEmpty {
            if let documentTitle = webView.stringByEvaluatingJavaScript(from: "document.title"), !documentTitle.isEmpty {
                title = documentTitle
            }
            addressBarView.url = webView.request?.url
            addressBarView.loading = false
            lastRequest = nil
        }
        updateUIFromWebView()
        
        if !userScriptsInjected {
            if let url = webView.request?.url {
                userScriptsInjected = injectUserScripts(for: url)
                
                if url == WaniKaniURLs.lessonSession || url == WaniKaniURLs.reviewSession {
                    showBrowserInterface(false, animated: true)
                }
            }
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        DDLogWarn("Navigation failed: \(error)")
        addressBarView.url = webView.request?.url
        addressBarView.loading = false
        requestStack.removeAll()
        updateUIFromWebView()
        
        let nsError = error as NSError
        if nsError.domain != "WebKitErrorDomain" && nsError.code != 102 {
            switch (nsError.domain, nsError.code) {
            // Ignore navigation cancellation errors
            case (NSURLErrorDomain, NSURLErrorCancelled), ("WebKitErrorDomain", 102):
                break
            default:
                showAlert(title: "Failed to load page", message: error.localizedDescription)
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard let nc = navigationController, nc.isNavigationBarHidden else { return true }
        
        showBrowserInterface(true, animated: true)
        return false
    }
    
    // MARK: - WebViewControllerDelegate
    
    func webViewControllerDidFinish(_ controller: WebViewController) {
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
        self.view.addSubview(statusBarView)
        
        if allowsBackForwardNavigationGestures {
            backScreenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(backScreenEdgePanGestureTriggered(_:)))
            backScreenEdgePanGesture!.edges = .left
            forwardScreenEdgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(forwardScreenEdgePanGestureTriggered(_:)))
            forwardScreenEdgePanGesture!.edges = .right
            webView.scrollView.addGestureRecognizer(backScreenEdgePanGesture!)
            webView.scrollView.addGestureRecognizer(forwardScreenEdgePanGesture!)
            webView.scrollView.panGestureRecognizer.require(toFail: backScreenEdgePanGesture!)
            webView.scrollView.panGestureRecognizer.require(toFail: forwardScreenEdgePanGesture!)
        }
        
        configureToolbars(for: self.traitCollection)
        
        if let nc = self.navigationController {
            let navBar = nc.navigationBar
            
            addressBarView = WebAddressBarView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: navBar.bounds.width, height: 28)), forWebView: webView)
            addressBarView.autoresizingMask = [.flexibleWidth]
            self.navigationItem.titleView = addressBarView
        }
        
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let nc = self.navigationController {
            if toolbarItems?.isEmpty == false {
                nc.setToolbarHidden(false, animated: false)
            }
            nc.hidesBarsOnSwipe = true
            nc.hidesBarsWhenVerticallyCompact = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let nc = self.navigationController {
            navigationBarSettings?.applyToNavigationController(nc)
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
        UIApplication.shared.isNetworkActivityIndicatorVisible = webView?.isLoading ?? false
        
        // Navigation buttons
        backButton.isEnabled = webView?.canGoBack ?? false
        forwardButton.isEnabled = webView?.canGoForward ?? false
        shareButton.isEnabled = webView?.request?.url != nil
        openInSafariButton.isEnabled = webView?.request?.url != nil
    }
    
    func fillUsing1Password(_ sender: AnyObject!) {
        guard let webView = self.webView else { return }
        
        OnePasswordExtension.shared().fillItem(intoWebView: webView, for: self, sender: sender, showOnlyLogins: true) { success, error in
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
    
}

extension UIWebViewNavigationType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .linkClicked: return "LinkClicked"
        case .formSubmitted: return "FormSubmitted"
        case .backForward: return "BackForward"
        case .reload: return "Reload"
        case .formResubmitted: return "FormResubmitted"
        case .other: return "Other"
        }
    }
}
