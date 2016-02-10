//
//  GetAPIKeyViewController.swift
//  KeitaiWaniKani
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
        apiKeyTextField.enabled = false
        doneBarButton.enabled = false
        activityIndicator.startAnimating()
    }
    
    func allowInput() {
        apiKeyTextField.enabled = true
        doneBarButton.enabled = true
        activityIndicator.stopAnimating()
    }
    
    func checkAPIKey() {
        guard let apiKey = apiKeyTextField.text else {
            return
        }

        preventInput()

        ApplicationSettings.apiKey = apiKey
        
        DDLogDebug("Checking validity of API key \(apiKey)")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            let finishHandler = BlockObserver(finishHandler: { _, operationErrors in
                let errors = operationErrors.filter { error in
                    if case UserNotificationConditionError.SettingsMismatch = error {
                        return false
                    }
                    return true
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    // Ignore user notification errors
                    self.allowInput()
                    if errors.isEmpty {
                        DDLogDebug("API key valid.  Dismissing view controller.")
                        self.performSegueWithIdentifier(SegueIdentifiers.apiKeySet, sender: self)
                    } else {
                        if errors.contains({ if case WaniKaniAPIError.UserNotFound = $0 { return true } else { return false } }) {
                            ApplicationSettings.apiKey = nil
                            self.showAlertWithTitle("Invalid API Key", message: "The API key you entered is invalid.  Please check and try again.")
                        } else {
                            self.showAlertWithTitle("Unable to verify API Key",
                                message: "An error occurred when attempting to validate the API Key.\nDetails: \(errors)")
                        }
                    }
                }
            })
            
            DDLogVerbose("Checking API key...")
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let resolver = WaniKaniAPI.resourceResolverForAPIKey(apiKey)
            let operation = GetStudyQueueOperation(resolver: resolver, databaseQueue: delegate.databaseQueue, parseOnly: true)
            operation.addObserver(finishHandler)
            
            delegate.operationQueue.addOperation(operation)
        }
    }

    var aktfObserver: NSObjectProtocol?
    
    func observeTextField() {
        let center = NSNotificationCenter.defaultCenter()
        aktfObserver = center.addObserverForName(UITextFieldTextDidChangeNotification,
            object: apiKeyTextField,
            queue: NSOperationQueue.mainQueue()) { _ in
                if let text = self.apiKeyTextField?.text {
                    self.doneBarButton.enabled = !text.characters.isEmpty
                } else {
                    self.doneBarButton.enabled = false
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
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done(sender: UIBarButtonItem) {
        checkAPIKey()
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        checkAPIKey()
        return true
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        apiKeyTextField?.text = ApplicationSettings.apiKey
        observeTextField()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = aktfObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }
    
}
