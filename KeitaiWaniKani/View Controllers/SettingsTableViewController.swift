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

private let reviewURL = NSURL(string: "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1031055291&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software")!

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    private enum TableViewSections: Int {
        case UserScripts = 0, OtherSettings, Feedback, LogOut
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
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts, .OtherSettings:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! UserScriptTableViewCell
            tableView.beginUpdates()
            UIView.animateWithDuration(0.3) {
                cell.toggleDescriptionVisibility();
                cell.contentView.layoutIfNeeded()
            }
            tableView.endUpdates()
        case .Feedback, .LogOut: break;
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts: return userScripts.count
        case .OtherSettings: return otherSettings.count
        case .Feedback: return 2
        case .LogOut: return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts:
            return dequeueAndInitScriptCell(userScripts, forIndexPath: indexPath)
        case .OtherSettings:
            return dequeueAndInitScriptCell(otherSettings, forIndexPath: indexPath)
        case .Feedback:
            let cell = tableView.dequeueReusableCellWithIdentifier("Basic", forIndexPath: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Send Feedback"
            case 1:
                cell.textLabel?.text = "Leave a Review"
            default: fatalError("No cell defined for index path \(indexPath)")
            }
            cell.accessoryType = .DisclosureIndicator
            return cell
        case .LogOut:
            let cell = tableView.dequeueReusableCellWithIdentifier("Basic", forIndexPath: indexPath)
            cell.textLabel?.text = "Log Out"
            cell.accessoryType = .DisclosureIndicator
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts: return "User Scripts"
        case .OtherSettings: return "Other Settings"
        case .Feedback: return "Feedback"
        case .LogOut: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts, .OtherSettings: return nil
        case .Feedback:
            return "App Store reviews are reset after every release.  Good reviews are appreciated, but please email me through the Send Feedback link if you're having any issues.  It's difficult to help you otherwise!"
        case .LogOut:
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts, .OtherSettings: break
        case .Feedback:
            switch indexPath.row {
            case 0: sendMail()
            case 1: leaveReview()
            default: fatalError("No cell defined for index path \(indexPath)")
            }
        case .LogOut: confirmLogOut()
        }
        
        return nil
    }
    
    private func dequeueAndInitScriptCell(scriptDetails: [ScriptInfo], forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserScript", forIndexPath: indexPath) as! UserScriptTableViewCell
        let userScript = scriptDetails[indexPath.row]
        cell.settingName = userScript.name
        cell.settingDescription = userScript.description
        cell.applicationSettingKey = userScript.settingKey
        cell.accessoryType = .DetailButton
        cell.setToDefault()
        cell.contentView.layoutIfNeeded()
        
        return cell
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        DDLogDebug("MFMailComposeViewController finished with result \(result): \(error)")
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Feedback
    
    private func sendMail() {
        if !MFMailComposeViewController.canSendMail() {
            self.showAlertWithTitle("Unable to send mail", message: "Your device is not configured to send e-mail.  Please set up an email account and try again.")
        } else {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            vc.setToRecipients(["allicrab@icloud.com"])
            let (product, version, build) = self.productAndVersion
            vc.setSubject("\(product) feedback (v\(version) b\(build))")
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    private func leaveReview() {
        UIApplication.sharedApplication().openURL(reviewURL)
    }
    
    // MARK: - Log Out
    
    private func confirmLogOut() {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: "Please note that logging out will remove all web cookies and user data, and will reset all settings to default.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .Destructive) { _ in self.performLogOut() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func performLogOut() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Reset app settings
        ApplicationSettings.resetToDefaults()
        
        // Purge database
        delegate.databaseManager.recreateDatabase()
        
        // Clear web cookies
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = cookieStorage.cookies {
            for cookie in cookies
            {
                cookieStorage.deleteCookie(cookie)
            }
        }
        
        if #available(iOS 9.0, *) {
            WKWebsiteDataStore.defaultDataStore().removeDataOfTypes(WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: NSDate(timeIntervalSince1970: 0), completionHandler: {})
        } else {
            do {
                let fm = NSFileManager.defaultManager()
                let libraryPath = try fm.URLForDirectory(.LibraryDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
                try fm.removeItemAtURL(NSURL(string: "Cookies", relativeToURL: libraryPath)!)
                try fm.removeItemAtURL(NSURL(string: "WebKit", relativeToURL: libraryPath)!)
            } catch {
                DDLogWarn("Failed to remove cookies folder: \(error)")
            }
        }
        
        delegate.webKitProcessPool = WKProcessPool()
        
        // Notifications
        let application = UIApplication.sharedApplication()
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        
        // Pop to home screen
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private var productAndVersion: (product: String, version: String, build: String) {
        let infoDictionary = NSBundle.mainBundle().infoDictionary!
        let productName = infoDictionary["CFBundleName"]! as! String
        let appVersion = infoDictionary["CFBundleShortVersionString"]! as! String
        let buildNumber = infoDictionary["CFBundleVersion"]! as! String
        return (productName, appVersion, buildNumber)
    }
}
