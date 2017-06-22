//
//  SettingsTableViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import MessageUI
import WebKit
import CocoaLumberjack

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    private enum TableViewSection: Int {
        case userScripts = 0, otherSettings, feedback, logOut
    }
    
    // MARK: - Properties
    
    private let userScripts = UserScriptDefinitions.community
    
    private let otherSettings = UserScriptDefinitions.custom
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .userScripts, .otherSettings:
            let cell = tableView.cellForRow(at: indexPath) as! UserScriptTableViewCell
            tableView.beginUpdates()
            UIView.animate(withDuration: 0.3) {
                cell.toggleDescriptionVisibility();
                cell.contentView.layoutIfNeeded()
            }
            tableView.endUpdates()
        case .feedback, .logOut: break;
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .userScripts: return userScripts.count
        case .otherSettings: return otherSettings.count
        case .feedback: return 2
        case .logOut: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .userScripts:
            return dequeueAndInitScriptCell(userScripts, forIndexPath: indexPath)
        case .otherSettings:
            return dequeueAndInitScriptCell(otherSettings, forIndexPath: indexPath)
        case .feedback:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Send Feedback"
            case 1:
                cell.textLabel?.text = "Leave a Review"
            default: fatalError("No cell defined for index path \(indexPath)")
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        case .logOut:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Basic", for: indexPath)
            cell.textLabel?.text = "Log Out"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .userScripts: return "User Scripts"
        case .otherSettings: return "Other Settings"
        case .feedback: return "Feedback"
        case .logOut: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .userScripts, .otherSettings: return nil
        case .feedback:
            return "App Store reviews are reset after every release.  Good reviews are always appreciated, but if you're experiencing any issues please email me through the Send Feedback link."
        case .logOut:
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .userScripts, .otherSettings: break
        case .feedback:
            switch indexPath.row {
            case 0: sendMail()
            case 1: leaveReview()
            default: fatalError("No cell defined for index path \(indexPath)")
            }
        case .logOut: confirmLogOut()
        }
        
        return nil
    }
    
    private func dequeueAndInitScriptCell(_ scriptDetails: [UserScript], forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserScript", for: indexPath) as! UserScriptTableViewCell
        let userScript = scriptDetails[indexPath.row]
        cell.userScript = userScript
        cell.accessoryType = .detailButton
        cell.setToDefault()
        cell.contentView.layoutIfNeeded()
        
        return cell
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DDLogDebug("MFMailComposeViewController finished with result \(result): \(String(describing: error))")
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Feedback
    
    private func sendMail() {
        if !MFMailComposeViewController.canSendMail() {
            self.showAlert(title: "Unable to send mail", message: "Your device is not configured to send e-mail.  Please set up an email account and try again.")
        } else {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            vc.setToRecipients(["allicrab@icloud.com"])
            let (product, version, build) = self.productAndVersion
            vc.setSubject("\(product) feedback (v\(version) b\(build))")
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    private func leaveReview() {
        if #available(iOS 10.0, *) {
            let reviewURL = URL(string: "itms-apps://itunes.apple.com/app/id1031055291?action=write-review")!
            UIApplication.shared.open(reviewURL) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showAlert(message: "Thank you for your interest in leaving a review. However, the review page failed to open.")
                    }
                }
            }
        } else {
            let reviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1031055291&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!
            UIApplication.shared.openURL(reviewURL)
        }
    }
    
    // MARK: - Log Out
    
    private func confirmLogOut() {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: "Please note that logging out will remove all web cookies and user data, and will reset all settings to default.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in self.performLogOut() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func performLogOut() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.performLogOut()
        
        // Pop to home screen
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    private var productAndVersion: (product: String, version: String, build: String) {
        let infoDictionary = Bundle.main.infoDictionary!
        let productName = infoDictionary["CFBundleName"]! as! String
        let appVersion = infoDictionary["CFBundleShortVersionString"]! as! String
        let buildNumber = infoDictionary["CFBundleVersion"]! as! String
        return (productName, appVersion, buildNumber)
    }
}
