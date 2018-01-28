//
//  SettingsTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class SettingsTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case userScript = "UserScript"
        case forumTopicLink = "ForumTopicLink"
        case basic = "Basic"
    }
    
    private enum TableViewSection: RawRepresentable {
        case userScript(UserScript), feedback, logOut, count
        
        init?(rawValue: Int) {
            var section = rawValue
            if section < UserScriptDefinitions.community.count {
                self = .userScript(UserScriptDefinitions.community[section])
                return
            }
            section -= UserScriptDefinitions.community.count
            
            if section < UserScriptDefinitions.custom.count {
                self = .userScript(UserScriptDefinitions.custom[section])
                return
            }
            section -= UserScriptDefinitions.custom.count
            
            switch section {
            case 0:
                self = .feedback
            case 1:
                self = .logOut
            default:
                return nil
            }
        }
        
        var rawValue: Int {
            let firstNonScriptIndex = UserScriptDefinitions.community.count + UserScriptDefinitions.custom.count
            switch self {
            case let .userScript(userScript):
                if let index = UserScriptDefinitions.community.index(where: { $0.name == userScript.name }) {
                    return index
                }
                if let index = UserScriptDefinitions.custom.index(where: { $0.name == userScript.name }) {
                    return index + UserScriptDefinitions.community.count
                }
                fatalError()
            case .feedback:
                return firstNonScriptIndex
            case .logOut:
                return firstNonScriptIndex + 1
            case .count:
                return firstNonScriptIndex + 2
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.count.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript): return userScript.forumLink == nil ? 1 : 2
        case .feedback: return 1
        case .logOut: return 1
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.userScript.rawValue, for: indexPath) as! UserScriptTableViewCell
                cell.userScript = userScript
                
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.forumTopicLink.rawValue, for: indexPath)
                cell.detailTextLabel?.text = userScript.forumLink?.absoluteString.removingPercentEncoding
                
                return cell
            default: fatalError()
            }
        case .feedback:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.forumTopicLink.rawValue, for: indexPath)
            cell.detailTextLabel?.text = WaniKaniURL.appForumTopic.absoluteString.removingPercentEncoding
            
            return cell
        case .logOut:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.basic.rawValue, for: indexPath)
            cell.textLabel?.text = "Log Out"
            
            return cell
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript): return "Script: \(userScript.name)"
        case .feedback: return "Feedback"
        case .logOut: return nil
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            guard let author = userScript.author else {
                return nil
            }
            return "Script by \(author)"
        case .feedback:
            return "Please check the app forum topic for the latest news and support"
        case .logOut:
            let (product, version, build) = self.productAndVersion
            return "\(product) version \(version) (build \(build))"
        case .count: fatalError("This is a placeholder and not a real section")
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            if let forumLink = userScript.forumLink {
                let vc = WebViewController.wrapped(url: forumLink)
                present(vc, animated: true, completion: nil)
            }
        case .feedback:
            let vc = WebViewController.wrapped(url: WaniKaniURL.appForumTopic)
            present(vc, animated: true, completion: nil)
        case .logOut: confirmLogOut()
        case .count: fatalError("This is a placeholder and not a real section")
        }
        
        return nil
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
