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

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    private enum TableViewSections: Int {
        case UserScripts = 0, Feedback = 1, LogOut = 2
    }
    
    // MARK: - Properties
    
    let userScripts: [(name: String, description: String, settingKey: String)] = [
        (name: "WaniKani Double Check",
            description: "Adds a thumbs up/down button that permits incorrect answers to be marked correct, and correct answers to be marked incorrect.  PLEASE USE RESPONSIBLY!  This script is intended to be used to correct genuine mistakes, like typographical errors.  Original script written by Ethan.",
            settingKey: ApplicationSettingKeys.userScriptIgnoreAnswerEnabled),
        (name: "WaniKani Improve",
            description: "Auto forward to the next item if the answer was correct (\"lightning mode\").  Original script written by Seiji.",
            settingKey: ApplicationSettingKeys.userScriptWaniKaniImproveEnabled)
    ]
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts: return userScripts.count
        case .Feedback: return 1
        case .LogOut: return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts:
            let cell = tableView.dequeueReusableCellWithIdentifier("UserScript", forIndexPath: indexPath) as! UserScriptTableViewCell
            let userScript = userScripts[indexPath.row]
            cell.settingName = userScript.name
            cell.settingDescription = userScript.description
            cell.applicationSettingKey = userScript.settingKey
            cell.accessoryType = .None
            cell.layoutIfNeeded()
            
            return cell
        case .Feedback:
            let cell = tableView.dequeueReusableCellWithIdentifier("Basic", forIndexPath: indexPath)
            cell.textLabel?.text = "Send Feedback"
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
        case .Feedback: return "Feedback"
        case .LogOut: return "Log Out"
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSections(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        if tableViewSection == TableViewSections.LogOut {
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard let tableViewSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .UserScripts: break
        case .Feedback: sendMail()
        case .LogOut: confirmLogOut()
        }
        
        return nil
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        DDLogDebug("MFMailComposeViewController finished with result \(result): \(error)")
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Send Mail
    
    private func sendMail() {
        if !MFMailComposeViewController.canSendMail() {
            self.showAlertWithTitle("Unable to send mail", message: "Your device is not configured to send e-mail.  Please set up an email account and try again.")
        } else {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            vc.setToRecipients(["KeitaiWaniKani@icloud.com"])
            let (product, version, build) = self.productAndVersion
            vc.setSubject("\(product) feedback (v\(version) b\(build))")
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Log Out
    
    private func confirmLogOut() {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: "Please note that logging out will remove all web cookies and user data, and will reset all settings to default.", preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .Destructive) { _ in self.performLogOut() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func performLogOut() {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Reset app settings
        ApplicationSettings.resetToDefaults()
        
        // Purge database
        delegate.recreateDatabase()
        
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
