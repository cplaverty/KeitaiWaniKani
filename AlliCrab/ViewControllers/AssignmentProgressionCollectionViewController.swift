//
//  SubjectLevelProgressionCollectionViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class AssignmentProgressionCollectionViewController: UICollectionViewController {
    
    private struct Section {
        let title: String
        let items: [SubjectProgression]
    }
    
    private enum ReuseIdentifier: String {
        case header = "Header"
        case subject = "Subject"
    }
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader? {
        didSet {
            updateUI()
        }
    }
    
    var subjectType: SubjectType? {
        didSet {
            guard let subjectType = subjectType else {
                return
            }
            
            switch subjectType {
            case .radical:
                navigationItem.title = "Radicals"
            case .kanji:
                navigationItem.title = "Kanji"
            case .vocabulary:
                fatalError()
            }
            
            updateUI()
        }
    }
    
    private var sections = [Section]() {
        didSet {
            collectionView!.reloadData()
        }
    }
    
    private var updateUITimer: Timer?
    private var notificationObservers: [NSObjectProtocol]?
    
    // MARK: - Initialisers
    
    deinit {
        if let notificationObservers = notificationObservers {
            if #available(iOS 10.0, *) {
                os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
            }
            notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
        }
        notificationObservers = nil
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier.subject.rawValue, for: indexPath) as! AssignmentProgressionCollectionViewCell
        
        cell.subject = item.subject
        cell.isLocked = item.isLocked
        cell.availableAt = item.availableAt
        cell.guruTime = item.guruTime
        cell.percentComplete = item.percentComplete
        cell.updateUI()
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReuseIdentifier.header.rawValue, for: indexPath) as! AssignmentProgressionCollectionReusableView
        
        if kind == UICollectionElementKindSectionHeader {
            let section = sections[indexPath.section]
            view.headerLabel.text = section.title
        } else {
            view.headerLabel.text = nil
        }
        
        return view
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! AssignmentProgressionCollectionViewCell
        self.present(WebViewController.wrapped(url: cell.documentURL), animated: true, completion: nil)
    }
    
    // MARK: - Timer
    
    private func makeUpdateTimer() -> Timer {
        let nextFireTime = Calendar.current.nextDate(after: Date(),
                                                     matching: DateComponents(second: 0, nanosecond: 0),
                                                     matchingPolicy: .nextTime)!
        if #available(iOS 10, *) {
            os_log("%@ update timer will fire at %@", type: .debug, String(describing: type(of: self)), nextFireTime as NSDate)
        }
        let timer = Timer(fireAt: nextFireTime, interval: .oneMinute, target: self, selector: #selector(updateUITimerDidFire(_:)), userInfo: nil, repeats: true)
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        
        return timer
    }
    
    @objc func updateUITimerDidFire(_ timer: Timer) {
        if #available(iOS 10, *) {
            os_log("%@ timer fire", type: .debug, String(describing: type(of: self)))
        }
        
        let now = Date()
        let isStartOfHour = now.timeIntervalSince(Calendar.current.startOfHour(for: now)) < .oneMinute
        if isStartOfHour {
            collectionView?.reloadData()
            return
        }
        
        let indexPathsNeedingRefresh = sections.lazy.enumerated().flatMap { (sectionIndex, section) -> [IndexPath] in
            let cellsNeedingRefresh = section.items.lazy.enumerated().filter { (_, item) in
                if case let .date(date) = item.availableAt, date.timeIntervalSinceNow < .oneDay + .oneHour {
                    return true
                }
                if case let .date(date) = item.guruTime, date.timeIntervalSinceNow < .oneDay + .oneHour {
                    return true
                }
                return false
                }.map { (itemIndex, _) in itemIndex }
            return cellsNeedingRefresh.map { itemIndex in IndexPath(item: itemIndex, section: sectionIndex) }
        }
        
        if #available(iOS 10, *) {
            os_log("Refreshing %d cells", type: .debug, indexPathsNeedingRefresh.count)
        }
        
        collectionView?.reloadItems(at: indexPathsNeedingRefresh)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.estimatedItemSize = flowLayout.itemSize
        if #available(iOS 11.0, *) {
            flowLayout.sectionInsetReference = .fromSafeArea
        }
        
        notificationObservers = addNotificationObservers()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            collectionView!.backgroundView = BlurredImageView(frame: collectionView!.frame, imageNamed: "Art03", style: .extraLight)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUITimer = makeUpdateTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        updateUITimer?.invalidate()
        updateUITimer = nil
    }
    
    // MARK: - Update UI
    
    private func addNotificationObservers() -> [NSObjectProtocol] {
        if #available(iOS 10.0, *) {
            os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        }
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.updateUI()
            }
        ]
        
        return notificationObservers
    }
    
    private func updateUI() {
        guard let repositoryReader = repositoryReader, let subjectType = subjectType else {
            return
        }
        
        if #available(iOS 10.0, *) {
            os_log("Updating assignment guru progression for subject type %@", type: .info, String(describing: subjectType))
        }
        
        guard let userInformation = try! repositoryReader.userInformation() else {
            return
        }
        
        var progression = try! repositoryReader.subjectProgression(type: subjectType, forLevel: userInformation.level)
        
        var sections = [Section]()
        sections.reserveCapacity(2)
        
        let switchIndex = progression.partition(by: { item in item.isPassed })
        let unpassed = progression[..<switchIndex]
        let passed = progression[switchIndex...]
        
        if #available(iOS 10.0, *) {
            os_log("Item count: remainingToLevel = %d, passed = %d", type: .debug, unpassed.count, passed.count)
        }
        if !unpassed.isEmpty {
            sections.append(Section(title: "Remaining to Level",
                                    items: unpassed.sorted(by: { Assignment.Sorting.byProgress($0.assignment, $1.assignment) })))
        }
        if !passed.isEmpty {
            sections.append(Section(title: "Complete",
                                    items: passed.sorted(by: { Assignment.Sorting.byProgress($0.assignment, $1.assignment) })))
        }
        
        self.sections = sections
    }
    
}

extension AssignmentProgressionCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let view = AssignmentProgressionCollectionReusableView(frame: .zero)
        let section = sections[section]
        view.headerLabel.text = section.title
        view.headerLabel.sizeToFit()
        
        let insets = (collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        return CGSize(width: collectionView.bounds.width, height: view.headerLabel.bounds.height + insets.top + insets.bottom)
    }
}
