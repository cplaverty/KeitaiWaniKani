//
//  SubjectSearchTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class SubjectSearchTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case subject = "Subject"
    }
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader!
    
    private var subjects = [Subject]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.subject.rawValue, for: indexPath) as! SubjectSearchTableViewCell
        
        let subject = subjects[indexPath.row]
        cell.subject = subject
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let subject = subjects[indexPath.row]
        self.present(WebViewController.wrapped(url: subject.documentURL), animated: true, completion: nil)
        return nil
    }
    
}

// MARK: - UISearchResultsUpdating
extension SubjectSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces), !searchText.isEmpty else {
            subjects = []
            return
        }
        
        subjects = try! repositoryReader.findSubjects(matching: searchText).map({ $0.data as! Subject })
    }
}
