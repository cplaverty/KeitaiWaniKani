//
//  UserScriptSettingsTableViewController.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import UIKit

class UserScriptSettingsTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case userScript = "UserScript"
        case forumTopicLink = "ForumTopicLink"
    }
    
    private enum TableViewSection: RawRepresentable {
        case userScript(UserScript)
        
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
            
            return nil
        }
        
        var rawValue: Int {
            switch self {
            case let .userScript(userScript):
                if let index = UserScriptDefinitions.community.firstIndex(where: { $0.name == userScript.name }) {
                    return index
                }
                if let index = UserScriptDefinitions.custom.firstIndex(where: { $0.name == userScript.name }) {
                    return index + UserScriptDefinitions.community.count
                }
                fatalError()
            }
        }
        
        static var count: Int {
            return UserScriptDefinitions.community.count + UserScriptDefinitions.custom.count
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSection.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            return userScript.forumLink == nil ? 1 : 2
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
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            return userScript.name
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableViewSection = TableViewSection(rawValue: section) else {
            fatalError("Invalid section index \(section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            var scriptFooter = userScript.description
            if let author = userScript.author {
                scriptFooter += " Created by \(author)."
            }
            if let updater = userScript.updater {
                scriptFooter += " Updated by \(updater)."
            }
            return scriptFooter
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tableViewSection = TableViewSection(rawValue: indexPath.section) else {
            fatalError("Invalid section index \(indexPath.section) requested")
        }
        
        switch tableViewSection {
        case let .userScript(userScript):
            if let forumLink = userScript.forumLink {
                presentSafariViewController(url: forumLink)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
