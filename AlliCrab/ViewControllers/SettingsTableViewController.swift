//
//  SettingsTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

class SettingsTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case basic = "Basic"
        case forumTopicLink = "ForumTopicLink"
    }
    
    private enum TableViewSection: Int, CaseIterable {
        case notification, userScripts, feedback, logOut
    }
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader?
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .notification:
            return 2
        case .userScripts, .feedback, .logOut:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .notification:
            let notificationStrategy = ApplicationSettings.notificationStrategy
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "First Review Session"
                cell.accessoryType = notificationStrategy == .firstReviewSession ? .checkmark : .none
            case 1:
                cell.textLabel?.text = "Every Review Session"
                cell.accessoryType = notificationStrategy == .everyReviewSession ? .checkmark : .none
            default: fatalError()
            }
            
            return cell
        case .userScripts:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
            cell.textLabel?.text = "User Scripts"
            
            return cell
        case .feedback:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.forumTopicLink.rawValue, for: indexPath)
            cell.detailTextLabel?.text = WaniKaniURL.appForumTopic.absoluteString.removingPercentEncoding
            
            return cell
        case .logOut:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
            cell.textLabel?.text = "Log Out"
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .notification: return "Notifications"
        case .feedback: return "Feedback"
        case .userScripts, .logOut: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case .notification, .userScripts: return nil
        case .feedback:
            return "Please check the app forum topic for the latest news and support."
        case .logOut:
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case .notification:
            let previousSelection = IndexPath(row: NotificationStrategy.allCases.firstIndex(of: ApplicationSettings.notificationStrategy)!, section: indexPath.section)
            
            let selectedNotificationStrategy = NotificationStrategy.allCases[indexPath.row]
            if ApplicationSettings.notificationStrategy != selectedNotificationStrategy {
                ApplicationSettings.notificationStrategy = selectedNotificationStrategy
                
                if let repositoryReader = repositoryReader {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.notificationManager.scheduleNotifications(resourceRepository: repositoryReader)
                }
            }
            
            tableView.reloadRows(at: [previousSelection, indexPath], with: .automatic)
        case .userScripts:
            let vc = storyboard?.instantiateViewController(withIdentifier: "UserScriptSettings") as! UserScriptSettingsTableViewController
            navigationController?.pushViewController(vc, animated: true)
        case .feedback:
            presentSafariViewController(url: WaniKaniURL.appForumTopic)
        case .logOut: confirmLogOut()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
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
        delegate.logOut()
    }
    
    private var productAndVersion: (product: String, version: String, build: String) {
        let infoDictionary = Bundle.main.infoDictionary!
        let productName = infoDictionary["CFBundleName"]! as! String
        let appVersion = infoDictionary["CFBundleShortVersionString"]! as! String
        let buildNumber = infoDictionary["CFBundleVersion"]! as! String
        return (productName, appVersion, buildNumber)
    }
    
}
