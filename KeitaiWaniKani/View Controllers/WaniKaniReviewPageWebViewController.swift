//
//  WaniKaniReviewPageWebViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WebKit
import CocoaLumberjack
import WaniKaniKit

class WaniKaniReviewPageWebViewController: WKWebViewController {
    
    // MARK: - Properties
    
    override var allowsBackForwardNavigationGestures: Bool { return false }
    
    // MARK: - Initialisers
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.removeInputAccessoryView()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showBrowserInterface(webView.url != WaniKaniURLs.lessonSession && webView.url != WaniKaniURLs.reviewSession, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ApplicationSettings.forceRefresh = true
    }
    
    // MARK: - Update UI
    
    func keyboardDidShow(_ notification: Notification) {
        guard let url = webView.url, url == WaniKaniURLs.lessonSession || url == WaniKaniURLs.reviewSession else { return }
        
        showBrowserInterface(false, animated: false)
    }
    
}
