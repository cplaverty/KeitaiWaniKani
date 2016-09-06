//
//  SettingsTableViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import MessageUI
import WebKit
import CocoaLumberjack

private let reviewURL = URL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1031055291&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    private enum TableViewSections: Int {
        case userScripts = 0, otherSettings, feedback, logOut
    }
    
    private struct ScriptInfo {
        let name: String
        let description: String
        let settingKey: String
    }
    
    // MARK: - Properties
    
    private let userScripts: [ScriptInfo] = [
        ScriptInfo(name: "Jitai",
            description: "Display WaniKani reviews in randomised fonts, for more varied reading training.  Original script written by obskyr.",
            settingKey: ApplicationSettingKeys.userScriptJitaiEnabled),
        ScriptInfo(name: "WaniKani Override",
            description: "Adds an \"Ignore Answer\" button to the bottom of WaniKani review pages, permitting incorrect answers to be ignored.  PLEASE USE RESPONSIBLY!  This script is intended to be used to correct genuine mistakes, like typographical errors.  Original script written by ruipgpinheiro.",
            settingKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled),
        ScriptInfo(name: "WaniKani Double Check",
            description: "Adds a thumbs up/down button that permits incorrect answers to be marked correct, and correct answers to be marked incorrect.  PLEASE USE RESPONSIBLY!  This script is intended to be used to correct genuine mistakes, like typographical errors.  Original script written by Ethan.",
            settingKey: ApplicationSettingKeys.userScriptDoubleCheckEnabled),
        ScriptInfo(name: "WaniKani Improve",
            description: "Automatically moves to the next item if the answer was correct (also known as \"lightning mode\").  Original script written by Seiji.",
            settingKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled),
        ScriptInfo(name: "Markdown Notes",
            description: "Allows you to write Markdown in the notes, which will be rendered as HTML when the page loads.  Original script written by rfindley.",
            settingKey: ApplicationSettingKeys.userScriptMarkdownNotesEnabled),
        ScriptInfo(name: "WaniKani Hide Mnemonics",
            description: "Allows you to hide the reading and meaning mnemonics on the site.  Original script written by nibarius.",
            settingKey: ApplicationSettingKeys.userScriptHideMnemonicsEnabled),
//        ScriptInfo(name: "WaniKani Reorder Ultimate",
//            description: "Allows you to reorder your lessons and reviews by type and level, and also force reading/meaning first.  PLEASE USE RESPONSIBLY!  Original script written by xMunch.",
//            settingKey: ApplicationSettingKeys.userScriptReorderUltimateEnabled),
        ]
    
    private let otherSettings: [ScriptInfo] = [
        ScriptInfo(name: "Disable Lesson Swipe",
            description: "Disables the horizontal swipe gesture on the info text during lessons to prevent it being accidentally triggered while scrolling.",
            settingKey: ApplicationSettingKeys.disableLessonSwipe),
        ]
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
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
        guard let tableViewSection = TableViewSections(rawValue: section) else {
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
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
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
        guard let tableViewSection = TableViewSections(rawValue: section) else {
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
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .userScripts, .otherSettings: return nil
        case .feedback:
            return "App Store reviews are reset after every release.  Good reviews are appreciated, but please email me through the Send Feedback link if you're having any issues.  It's difficult to help you otherwise!"
        case .logOut:
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
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
    
    private func dequeueAndInitScriptCell(_ scriptDetails: [ScriptInfo], forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserScript", for: indexPath) as! UserScriptTableViewCell
        let userScript = scriptDetails[indexPath.row]
        cell.settingName = userScript.name
        cell.settingDescription = userScript.description
        cell.applicationSettingKey = userScript.settingKey
        cell.accessoryType = .detailButton
        cell.setToDefault()
        cell.contentView.layoutIfNeeded()
        
        return cell
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        DDLogDebug("MFMailComposeViewController finished with result \(result): \(error)")
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
        UIApplication.shared.openURL(reviewURL)
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
        
        // Reset app settings
        ApplicationSettings.resetToDefaults()
        
        // Purge database
        delegate.databaseManager.recreateDatabase()
        
        // Clear web cookies
        let cookieStorage = HTTPCookieStorage.shared
        if let cookies = cookieStorage.cookies {
            for cookie in cookies
            {
                cookieStorage.deleteCookie(cookie)
            }
        }
        
        if #available(iOS 9.0, *) {
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0), completionHandler: {})
        } else {
            do {
                let fm = FileManager.default
                let libraryPath = try fm.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                try fm.removeItem(at: URL(string: "Cookies", relativeTo: libraryPath)!)
                try fm.removeItem(at: URL(string: "WebKit", relativeTo: libraryPath)!)
            } catch {
                DDLogWarn("Failed to remove cookies folder: \(error)")
            }
        }
        
        delegate.webKitProcessPool = WKProcessPool()
        
        // Notifications
        let application = UIApplication.shared
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        
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
