//
//  GetAPIKeyViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import OperationKit
import WaniKaniKit

class GetAPIKeyViewController: UIViewController, UITextFieldDelegate {
    
    struct SegueIdentifiers {
        static let apiKeySet = "APIKeySetManually"
    }
    
    func preventInput() {
        apiKeyTextField.isEnabled = false
        doneBarButton.isEnabled = false
        activityIndicator.startAnimating()
    }
    
    func allowInput() {
        apiKeyTextField.isEnabled = true
        doneBarButton.isEnabled = true
        activityIndicator.stopAnimating()
    }
    
    func checkAPIKey() {
        guard let apiKey = apiKeyTextField.text else {
            return
        }
        
        preventInput()
        
        ApplicationSettings.apiKey = apiKey
        
        DDLogDebug("Checking validity of API key \(apiKey)")
        DispatchQueue.global(qos: .userInitiated).async {
            let finishHandler = BlockObserver(finishHandler: { _, operationErrors in
                let errors = operationErrors.filter { error in
                    if case UserNotificationConditionError.settingsMismatch = error {
                        return false
                    }
                    return true
                }
                
                DispatchQueue.main.async {
                    // Ignore user notification errors
                    self.allowInput()
                    if errors.isEmpty {
                        DDLogDebug("API key valid.  Dismissing view controller.")
                        self.performSegue(withIdentifier: SegueIdentifiers.apiKeySet, sender: self)
                    } else {
                        if errors.contains(where: { if case WaniKaniAPIError.userNotFound = $0 { return true } else { return false } }) {
                            ApplicationSettings.apiKey = nil
                            self.showAlert(title:"Invalid API Key", message: "The API key you entered is invalid.  Please check and try again.")
                        } else {
                            self.showAlert(title: "Unable to verify API Key",
                                           message: "An error occurred when attempting to validate the API Key.\nDetails: \(errors)")
                        }
                    }
                }
            })
            
            DDLogVerbose("Checking API key...")
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
            let operation = GetStudyQueueOperation(resolver: resolver, databaseQueue: delegate.databaseQueue, parseOnly: true)
            operation.addObserver(finishHandler)
            
            delegate.operationQueue.addOperation(operation)
        }
    }
    
    var aktfObserver: NSObjectProtocol?
    
    func observeTextField() {
        let center = NotificationCenter.default
        aktfObserver = center.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange,
                                          object: apiKeyTextField,
                                          queue: Foundation.OperationQueue.main) { _ in
                                            if let text = self.apiKeyTextField?.text {
                                                self.doneBarButton.isEnabled = !text.characters.isEmpty
                                            } else {
                                                self.doneBarButton.isEnabled = false
                                            }
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var apiKeyTextField: UITextField! {
        didSet {
            apiKeyTextField.delegate = self
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Actions
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        checkAPIKey()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        checkAPIKey()
        return true
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        apiKeyTextField?.text = ApplicationSettings.apiKey
        observeTextField()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = aktfObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
}
