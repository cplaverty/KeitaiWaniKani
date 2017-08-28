//
//  ManualAPIKeyEntryViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class ManualAPIKeyEntryViewController: UIViewController {
    
    // MARK: - Properties
    
    private var textFieldTextChangedObserver: NSObjectProtocol?
    
    // MARK: - Outlets
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    @IBOutlet weak var apiKeyTextField: UITextField! {
        didSet {
            apiKeyTextField.delegate = self
        }
    }
    @IBOutlet weak var activityStatusView: UIVisualEffectView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Actions
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        validateAPIKey()
    }
    
    // MARK: - API Key Validation
    
    private func isAPIKeyValidFormat(_ apiKey: String) -> Bool {
        let parsed = UUID(uuidString: apiKey)
        return parsed != nil
    }
    
    @discardableResult private func validateAPIKey() -> Bool {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
            showAlert(title: "No API Key entered", message: "Please enter your API Key")
            return false
        }
        guard isAPIKeyValidFormat(apiKey) else {
            showAlert(title: "Invalid API Key", message: "Your API Key does not have a valid format.  Please ensure you are entering your version 2 API Key.")
            return false
        }
        
        startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let resourceRepository = appDelegate.makeResourceRepository(forAPIKey: apiKey)
        
        resourceRepository.updateUser(minimumFetchInterval: 0) { result in
            DispatchQueue.main.async {
                UIApplication.shared.endIgnoringInteractionEvents()
                self.stopAnimating()
                
                switch result {
                case .success, .noData:
                    if #available(iOS 10.0, *) {
                        os_log("API Key verified", type: .info)
                    }
                    ApplicationSettings.apiKey = apiKey
                    appDelegate.resourceRepository = resourceRepository
                    appDelegate.presentDashboardViewController(animated: true)
                case .error(WaniKaniAPIError.invalidAPIKey):
                    self.showAlert(title: "Invalid API Key", message: "The API key you entered is invalid.  Please check and try again.")
                case let .error(error):
                    if #available(iOS 10.0, *) {
                        os_log("Error when verifying API Key: %@", type: .error, error as NSError)
                    }
                    self.showAlert(title: "Unable to verify API Key", message: "An error occurred when attempting to validate the API Key.\nDetails: \(error.localizedDescription)")
                }
            }
        }
        
        return true
    }
    
    private func startAnimating() {
        activityStatusView.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func stopAnimating() {
        activityIndicator.stopAnimating()
        activityStatusView.isHidden = true
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apiKeyTextField.text = ApplicationSettings.apiKey
        apiKeyTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        textFieldTextChangedObserver = NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: apiKeyTextField, queue: .main) { _ in
            guard let apiKey = self.apiKeyTextField.text, !apiKey.isEmpty else { return }
            
            let isAPIKeyValidFormat = self.isAPIKeyValidFormat(apiKey)
            self.doneBarButton.isEnabled = isAPIKeyValidFormat
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let textFieldTextChangedObserver = self.textFieldTextChangedObserver {
            NotificationCenter.default.removeObserver(textFieldTextChangedObserver)
        }
        textFieldTextChangedObserver = nil
    }
    
}

// MARK: - UITextFieldDelegate
extension ManualAPIKeyEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if validateAPIKey() {
            textField.resignFirstResponder()
        }
        return false
    }
}
