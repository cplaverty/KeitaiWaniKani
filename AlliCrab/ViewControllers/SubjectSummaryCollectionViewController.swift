//
//  SubjectSummaryCollectionViewController.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class SubjectSummaryCollectionViewController: UICollectionViewController {
    
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
    
    var subjectIDs: [Int] {
        get { return cachingSubjectLoader.subjectIDs }
        set {
            cachingSubjectLoader.subjectIDs = newValue
            collectionView.reloadData()
        }
    }
    
    private var contentSizeChangedObserver: NSObjectProtocol?
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subjectIDs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier.subject.rawValue, for: indexPath) as! SubjectCollectionViewCell
        
        let subjectID = subjectIDs[indexPath.row]
        let subject = cachingSubjectLoader.subject(at: indexPath.row)
        cell.setSubject(subject, id: subjectID)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentSizeChangedObserver = collectionView.observe(\.contentSize) { [weak self] collectionView, _ in
            self?.preferredContentSize = collectionView.contentSize
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            return
        }
        
        os_log("Preparing segue %@", type: .debug, identifier)
        
        switch segueIdentifier {
        case .subjectDetail:
            let vc = segue.destination as! SubjectDetailViewController
            let cell = sender as! SubjectCollectionViewCell
            vc.repositoryReader = repositoryReader
            vc.subjectID = cell.subjectID
        }
    }
    
}
