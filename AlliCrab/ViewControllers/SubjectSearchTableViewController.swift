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
    
    private var subjectIDs = [Int]() {
        didSet {
            subjectsCache = Array(repeating: nil, count: subjectIDs.count)
            tableView.reloadData()
        }
    }
    
    private var subjectsCache = [Subject?]()
    
    private func subject(at index: Int) -> Subject {
        if let cached = subjectsCache[index] {
            return cached
        }
        
        let subject = try! repositoryReader.loadSubject(id: subjectIDs[index]).data as! Subject
        subjectsCache[index] = subject
        
        return subject
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subjectIDs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.subject.rawValue, for: indexPath) as! SubjectSearchTableViewCell
        
        let s = subject(at: indexPath.row)
        cell.subject = s
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let s = subject(at: indexPath.row)
        self.present(WebViewController.wrapped(url: s.documentURL), animated: true, completion: nil)
        return nil
    }
    
}

// MARK: - UISearchResultsUpdating
extension SubjectSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces), !searchText.isEmpty else {
            subjectIDs = []
            return
        }
        
        subjectIDs = try! repositoryReader.findSubjects(matching: searchText)
    }
}
