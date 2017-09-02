//
//  WebViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import OnePasswordExtension
import os
import UIKit
import WaniKaniKit
import WebKit

protocol WebViewControllerDelegate: class {
    func webViewController(_ controller: WebViewController, didFinish url: URL?)
}

class WebViewController: UIViewController {
    
    class func wrapped(url: URL, configBlock: ((WebViewController) -> Void)? = nil) -> UINavigationController {
        let webViewController = self.init(url: url)
        configBlock?(webViewController)
        
        let nc = UINavigationController(rootViewController: webViewController)
        nc.hidesBarsOnSwipe = true
        nc.hidesBarsWhenVerticallyCompact = true
        
        return nc
    }
    
    // MARK: - Properties
    
    weak var delegate: WebViewControllerDelegate?
    private(set) var webView: WKWebView!
    
    private var url: URL?
    private var webViewConfiguration: WKWebViewConfiguration?
    private var shouldIncludeDoneButton = false
    private var keyValueObservers: [NSKeyValueObservation]?
    
    private lazy var backButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ArrowLeft"), style: .plain, target: self, action: #selector(backButtonTouched(_:forEvent:)))
    private lazy var forwardButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "ArrowRight"), style: .plain, target: self, action: #selector(forwardButtonTouched(_:forEvent:)))
    private lazy var shareButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    private lazy var openInSafariButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "OpenInSafari"), style: .plain, target: self, action: #selector(openInSafari(_:)))
    private lazy var doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(done(_:)))
    
    private lazy var defaultWebViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        registerMessageHandlers(config.userContentController)
        config.applicationNameForUserAgent = "Mobile AlliCrab"
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        config.processPool = delegate.webKitProcessPool
        
        if #available(iOS 10.0, *) {
            config.ignoresViewportScaleLimits = true
        }
        
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = [.video]
        } else {
            config.requiresUserActionForMediaPlayback = false
        }
        
        return config
    }()
    
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
        // We nil these references out to unregister KVO on WKWebView
        self.navigationItem.titleView = nil
        keyValueObservers = nil
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    // MARK: - Actions
    
    @objc func backButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.backList, sender: sender)
        case 1: // Tap
            self.webView.goBack()
        default: break
        }
    }
    
    @objc func forwardButtonTouched(_ sender: UIBarButtonItem, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        switch touch.tapCount {
        case 0: // Long press
            self.showBackForwardList(webView.backForwardList.forwardList, sender: sender)
        case 1: // Tap
            self.webView.goForward()
        default: break
        }
    }
    
    @objc func share(_ sender: UIBarButtonItem) {
        guard let absoluteURL = webView.url?.absoluteURL else {
            return
        }
        
        var activityItems: [AnyObject] = [absoluteURL as NSURL]
        activityItems.reserveCapacity(2)
        
        let onePasswordExtension = OnePasswordExtension.shared()
        if onePasswordExtension.isAppExtensionAvailable() {
            onePasswordExtension.createExtensionItem(forWebView: webView) { extensionItem, error -> Void in
                if let error = error {
                    if #available(iOS 10.0, *) {
                        os_log("Failed to create 1Password extension item: %@", type: .error, error as NSError)
                    }
                } else if let extensionItem = extensionItem {
                    activityItems.append(extensionItem)
                }
                self.presentActivityViewController(activityItems, title: self.webView.title, sender: sender) {
                    activityType, completed, returnedItems, activityError in
                    if let error = activityError {
                        if #available(iOS 10.0, *) {
                            os_log("Activity failed: %@", type: .error, error as NSError)
                        }
                        DispatchQueue.main.async {
                            self.showAlert(title: "Activity failed", message: error.localizedDescription)
                        }
                        return
                    }
                    
                    guard completed else {
                        return
                    }
                    
                    if onePasswordExtension.isOnePasswordExtensionActivityType(activityType?.rawValue) {
                        onePasswordExtension.fillReturnedItems(returnedItems, intoWebView: self.webView) { success, error in
                            if !success {
                                let errorDescription = error?.localizedDescription ?? "(No error details)"
                                if #available(iOS 10.0, *) {
                                    os_log("Failed to fill password from password manager: %@", type: .error, errorDescription)
                                }
                                DispatchQueue.main.async {
                                    self.showAlert(title: "Password fill failed", message: errorDescription)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            presentActivityViewController(activityItems, title: webView.title, sender: sender)
        }
    }
    
    @objc func openInSafari(_ sender: UIBarButtonItem) {
        guard let URL = webView.url else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL)
        } else {
            UIApplication.shared.openURL(URL)
        }
    }
    
    @objc func done(_ sender: UIBarButtonItem) {
        finish()
    }
    
    func showBackForwardList(_ backForwardList: [WKBackForwardListItem], sender: UIBarButtonItem) {
        let vc = WebViewBackForwardListTableViewController()
        vc.backForwardList = backForwardList
        vc.delegate = self
        vc.modalPresentationStyle = .popover
        
        if let popover = vc.popoverPresentationController {
            popover.delegate = vc
            popover.permittedArrowDirections = [.up, .down]
            popover.barButtonItem = sender
        }
        
        present(vc, animated: true, completion: nil)
    }
    
    func presentActivityViewController(_ activityItems: [AnyObject], title: String?, sender: UIBarButtonItem, completionHandler: UIActivityViewControllerCompletionWithItemsHandler? = nil) {
        let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        avc.popoverPresentationController?.barButtonItem = sender;
        avc.completionWithItemsHandler = completionHandler
        if let title = title {
            avc.setValue(title, forKey: "subject")
        }
        
        navigationController?.present(avc, animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = makeWebView()
        keyValueObservers = registerObservers(webView)
        
        self.view.addSubview(webView)
        
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if let nc = self.navigationController {
            shouldIncludeDoneButton = nc.viewControllers[0] == self
            
            let addressBarView = WebAddressBarView(frame: nc.navigationBar.bounds, forWebView: webView)
            self.navigationItem.titleView = addressBarView
        }
        
        configureToolbars(for: self.traitCollection)
        
        if let url = self.url {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    private func makeWebView() -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration ?? defaultWebViewConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.keyboardDisplayDoesNotRequireUserAction()
        
        return webView
    }
    
    private func registerObservers(_ webView: WKWebView) -> [NSKeyValueObservation] {
        let keyValueObservers = [
            webView.observe(\.canGoBack, options: [.initial]) { [unowned self] webView, _ in
                self.backButton.isEnabled = webView.canGoBack
            },
            webView.observe(\.canGoForward, options: [.initial]) { [unowned self] webView, _ in
                self.forwardButton.isEnabled = webView.canGoForward
            },
            webView.observe(\.isLoading, options: [.initial]) { [unowned self] webView, _ in
                UIApplication.shared.isNetworkActivityIndicatorVisible = webView.isLoading
                self.shareButton.isEnabled = !webView.isLoading && webView.url != nil
            },
            webView.observe(\.url, options: [.initial]) { [unowned self] webView, _ in
                let hasURL = webView.url != nil
                self.shareButton.isEnabled = !webView.isLoading && hasURL
                self.openInSafariButton.isEnabled = hasURL
            }
        ]
        
        return keyValueObservers
    }
    
    // MARK: - Size class transitions
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if newCollection.horizontalSizeClass != traitCollection.horizontalSizeClass || newCollection.verticalSizeClass != traitCollection.verticalSizeClass {
            configureToolbars(for: newCollection)
        }
    }
    
    /// Sets the navigation bar and toolbar items based on the given UITraitCollection
    func configureToolbars(for traitCollection: UITraitCollection) {
        if traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular {
            addToolbarItemsForCompactWidthRegularHeight()
        } else {
            addToolbarItemsForAllOtherTraitCollections()
        }
    }
    
    /// For phone in portrait
    func addToolbarItemsForCompactWidthRegularHeight() {
        self.navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.leftItemsSupplementBackButton = !shouldIncludeDoneButton
        navigationItem.leftBarButtonItems = customLeftBarButtonItems
        navigationItem.rightBarButtonItems = customRightBarButtonItems
        let flexibleSpace = { UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) }
        setToolbarItems([backButton, flexibleSpace(), forwardButton, flexibleSpace(), shareButton, flexibleSpace(), openInSafariButton], animated: true)
    }
    
    /// For phone in landscape and pad in any orientation
    func addToolbarItemsForAllOtherTraitCollections() {
        self.navigationController?.setToolbarHidden(true, animated: true)
        setToolbarItems(nil, animated: true)
        navigationItem.leftItemsSupplementBackButton = !shouldIncludeDoneButton
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
    
    func showBrowserInterface(_ shouldShowBrowserInterface: Bool, animated: Bool) {
        guard let nc = self.navigationController else { return }
        
        nc.setNavigationBarHidden(!shouldShowBrowserInterface, animated: animated)
        if self.toolbarItems?.isEmpty == false {
            nc.setToolbarHidden(!shouldShowBrowserInterface, animated: animated)
        }
    }
    
    func finish() {
        unregisterMessageHandlers(webView.configuration.userContentController)
        dismiss(animated: true, completion: nil)
    }
    
    func registerMessageHandlers(_ userContentController: WKUserContentController) {
    }
    
    func unregisterMessageHandlers(_ userContentController: WKUserContentController) {
    }
}

// MARK: - WebViewBackForwardListTableViewControllerDelegate
extension WebViewController: WebViewBackForwardListTableViewControllerDelegate {
    func webViewBackForwardListTableViewController(_ controller: WebViewBackForwardListTableViewController, didSelectBackForwardListItem item: WKBackForwardListItem) {
        controller.dismiss(animated: true, completion: nil)
        self.webView.go(to: item)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
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
        if #available(iOS 10.0, *) {
            os_log("Navigation failed: %@", type: .error, error as NSError)
        }
        showErrorDialog(error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if #available(iOS 10.0, *) {
            os_log("Navigation failed: %@", type: .error, error as NSError)
        }
        showErrorDialog(error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webViewController(self, didFinish: webView.url)
        
        guard let url = webView.url else { return }
        
        switch url {
        case WaniKaniURL.lessonSession, WaniKaniURL.reviewSession:
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
        switch error {
        case let urlError as URLError where urlError.code == .cancelled:
            break
        case let nsError as NSError where nsError.domain == "WebKitErrorDomain" && nsError.code == 102:
            break
        default:
            showAlert(title: "Failed to load page", message: error.localizedDescription)
        }
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    }
}

// MARK: - WKUIDelegate
extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let newVC = type(of: self).init(configuration: configuration)
        newVC.url = navigationAction.request.url
        self.navigationController?.pushViewController(newVC, animated: true)
        
        return newVC.webView
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            let host = frame.request.url?.host ?? "web page"
            let title = "From \(host):"
            if #available(iOS 10.0, *) {
                os_log("Displaying alert with title %@ and message %@", type: .debug, title, message)
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let host = frame.request.url?.host ?? "web page"
            let title = "From \(host):"
            if #available(iOS 10.0, *) {
                os_log("Displaying alert with title %@ and message %@", type: .debug, title, message)
            }
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
            if #available(iOS 10.0, *) {
                os_log("Displaying input panel with title %@ and message %@", type: .debug, title, prompt)
            }
            let alert = UIAlertController(title: title, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - WebViewUserScriptSupport
extension WebViewController: WebViewUserScriptSupport {
}
