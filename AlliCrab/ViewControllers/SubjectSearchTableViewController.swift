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
    
    private enum SegueIdentifier: String {
        case subjectDetail = "SubjectDetail"
    }
    
    // MARK: - Properties
    
    private var cachingSubjectLoader: CachingSubjectLoader!
    
    var repositoryReader: ResourceRepositoryReader! {
        didSet {
            cachingSubjectLoader = CachingSubjectLoader(repositoryReader: repositoryReader)
        }
    }
    
    private var subjectIDs: [Int] {
        get { return cachingSubjectLoader.subjectIDs }
        set {
            cachingSubjectLoader.subjectIDs = newValue
            tableView.reloadData()
        }
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
        
        cell.subjectID = subjectIDs[indexPath.row]
        cell.subject = cachingSubjectLoader.subject(at: indexPath.row)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            return
        }
        
        os_log("Preparing segue %@", type: .debug, identifier)
        
        switch segueIdentifier {
        case .subjectDetail:
            let vc = (segue.destination as! UINavigationController).viewControllers[0] as! SubjectDetailViewController
            let cell = sender as! SubjectSearchTableViewCell
            vc.repositoryReader = repositoryReader
            vc.subjectID = cell.subjectID
        }
    }
    
    @IBAction func unwindToSubjectDetailPresenter(_ unwindSegue: UIStoryboardSegue) {
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
