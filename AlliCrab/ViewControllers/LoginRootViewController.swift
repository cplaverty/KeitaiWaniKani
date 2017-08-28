//
//  LoginRootViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class LoginRootViewController: UIViewController {
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        let wvc = WaniKaniLoginWebViewController.wrapped(url: WaniKaniURL.loginPage)
        present(wvc, animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
}
