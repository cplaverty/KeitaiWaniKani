//
//  WaniKaniReviewPageWebViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import WaniKaniKit

class WaniKaniReviewPageWebViewController: WebViewController {
    
    // MARK: - Properties
    
    var keyboardWillShowObserver: NSObjectProtocol?
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.allowsBackForwardNavigationGestures = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showBrowserInterface(webView.url != WaniKaniURL.lessonSession && webView.url != WaniKaniURL.reviewSession, animated: true)
        
        keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: .main) { [unowned self] _ in
            guard let url = self.webView.url, url == WaniKaniURL.lessonSession || url == WaniKaniURL.reviewSession else {
                return
            }
            
            self.showBrowserInterface(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let keyboardWillShowObserver = keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
        }
        keyboardWillShowObserver = nil
    }
    
}

