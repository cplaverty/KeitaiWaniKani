//
//  ReviewTimelineTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

enum ReviewTimelineFilter: CaseIterable {
    case none, currentLevel, toBeBurned
}

enum ReviewTimelineCountMethod: CaseIterable {
    case histogram, cumulative
}

class ReviewTimelineTableViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case dateHeader = "DateHeader"
        case reviewDetail = "ReviewDetail"
        case noAssignments = "NoAssignments"
    }
    
    private enum SegueIdentifier: String {
        case reviewTimelineFilter = "ReviewTimelineFilter"
    }
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader? {
        didSet {
            try! updateReviewTimeline()
        }
    }
    
    private var filter: ReviewTimelineFilter = .none {
        didSet {
            try! updateReviewTimeline()
        }
    }
    
    private var countMethod: ReviewTimelineCountMethod = .histogram {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var histogramReviewTimelineByDate = [(date: Date, value: [SRSReviewCounts])]()
    private var cumulativeReviewTimelineByDate = [(date: Date, value: [SRSReviewCounts])]()
    
    private var reviewTimelineByDate: [(date: Date, value: [SRSReviewCounts])] {
        switch self.countMethod {
        case .histogram:
            return histogramReviewTimelineByDate
        case .cumulative:
            return cumulativeReviewTimelineByDate
        }
    }
    
    private var notificationObservers: [NSObjectProtocol]?
    
    // MARK: - Initialisers
    
    deinit {
        if let notificationObservers = notificationObservers {
            os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
            notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
        }
        notificationObservers = nil
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return max(reviewTimelineByDate.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !reviewTimelineByDate.isEmpty else {
            return 1
        }
        
        let (_, reviewCountsForDate) = reviewTimelineByDate[section]
        return reviewCountsForDate.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !reviewTimelineByDate.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.noAssignments.rawValue, for: indexPath)
            cell.frame = tableView.frame
            return cell
        }
        
        let (_, reviewCountsForDate) = reviewTimelineByDate[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.reviewDetail.rawValue, for: indexPath) as! ReviewTimelineEntryTableViewCell
        cell.reviewCounts = reviewCountsForDate[indexPath.row]
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.dateHeader.rawValue) as! ReviewTimelineHeaderFooterView
        view.updateHeader(date: Date(), totalForDay: 0)
        view.titleLabel.sizeToFit()
        let height = view.titleLabel.frame.height + view.layoutMargins.top + view.layoutMargins.bottom
        return height
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !histogramReviewTimelineByDate.isEmpty else {
            return nil
        }
        
        let (date, reviewCountsForDate) = histogramReviewTimelineByDate[section]
        let totalForDay = reviewCountsForDate.reduce(0) { $0 + $1.itemCounts.total }
        
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.dateHeader.rawValue) as! ReviewTimelineHeaderFooterView
        view.updateHeader(date: date, totalForDay: totalForDay)
        
        return view
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ReviewTimelineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifier.dateHeader.rawValue)
        
        notificationObservers = addNotificationObservers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            return
        }
        
        switch segueIdentifier {
        case .reviewTimelineFilter:
            let vc = segue.destination as! ReviewTimelineOptionsTableViewController
            vc.selectedFilterValue = filter
            vc.selectedCountMethodValue = countMethod
            vc.delegate = self
            
            if let popover = vc.popoverPresentationController {
                popover.delegate = vc
            }
        }
    }
    
    // MARK: - Update UI
    
    private func addNotificationObservers() -> [NSObjectProtocol] {
        os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [weak self] _ in
                try? self?.updateReviewTimeline()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [weak self] _ in
                try? self?.updateReviewTimeline()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [weak self] _ in
                try? self?.updateReviewTimeline()
            }
        ]
        
        return notificationObservers
    }
    
    private func updateReviewTimeline() throws {
        guard let repositoryReader = repositoryReader, try repositoryReader.hasReviewTimeline() else {
            return
        }
        
        os_log("Updating review timeline with filter %@", type: .debug, String(describing: filter))
        
        var level: Int? = nil
        var srsStage: SRSStage? = nil
        switch filter {
        case .none: break
        case .currentLevel:
            let user = try repositoryReader.userInformation()
            level = user?.level
        case .toBeBurned:
            srsStage = .enlightened
        }
        
        let reviewTimeline = try repositoryReader.reviewTimeline(level: level, srsStage: srsStage)
        
        let calendar = Calendar.current
        let pastDateMarker = Date.distantPast
        var histogramReviewTimelineByDate = [(date: Date, value: [SRSReviewCounts])]()
        
        var currentIndex = histogramReviewTimelineByDate.startIndex - 1
        
        for counts in reviewTimeline {
            let date = counts.dateAvailable
            let isDateInPast = date.timeIntervalSinceNow <= 0
            let key = isDateInPast ? pastDateMarker : calendar.startOfDay(for: date)
            
            if histogramReviewTimelineByDate.count > 0, histogramReviewTimelineByDate[currentIndex].date == key {
                var countsForKey = histogramReviewTimelineByDate[currentIndex].value
                accumulate(counts, into: &countsForKey, for: key, usingSum: isDateInPast)
                histogramReviewTimelineByDate[currentIndex].value = countsForKey
            } else {
                var countsForKey = [SRSReviewCounts]()
                accumulate(counts, into: &countsForKey, for: key, usingSum: isDateInPast)
                histogramReviewTimelineByDate.append((key, countsForKey))
                currentIndex += 1
            }
        }
        
        var cumulativeReviewTimelineByDate = [(date: Date, value: [SRSReviewCounts])]()
        cumulativeReviewTimelineByDate.reserveCapacity(histogramReviewTimelineByDate.count)
        
        var cumulativeTotal = SRSItemCounts.zero
        
        for (date, values) in histogramReviewTimelineByDate {
            var cumulativeCounts = [SRSReviewCounts]()
            cumulativeCounts.reserveCapacity(values.count)
            
            for counts in values {
                cumulativeTotal += counts.itemCounts
                cumulativeCounts.append(SRSReviewCounts(dateAvailable: counts.dateAvailable, itemCounts: cumulativeTotal))
            }
            
            cumulativeReviewTimelineByDate.append((date, cumulativeCounts))
        }
        
        self.histogramReviewTimelineByDate = histogramReviewTimelineByDate
        self.cumulativeReviewTimelineByDate = cumulativeReviewTimelineByDate
        
        tableView.reloadData()
    }
    
    private func accumulate(_ counts: SRSReviewCounts, into countsForKey: inout [SRSReviewCounts], for date: Date, usingSum sum: Bool) {
        guard sum else {
            countsForKey.append(counts)
            return
        }
        
        let itemCounts: SRSItemCounts
        if let current = countsForKey.first {
            itemCounts = counts.itemCounts + current.itemCounts
        } else {
            itemCounts = counts.itemCounts
        }
        countsForKey = [SRSReviewCounts(dateAvailable: date, itemCounts: itemCounts)]
    }
    
}

extension ReviewTimelineTableViewController: ReviewTimelineOptionsDelegate {
    func reviewTimelineCountMethod(didChangeTo newValue: ReviewTimelineCountMethod) {
        countMethod = newValue
    }
    
    func reviewTimelineFilter(didChangeTo newValue: ReviewTimelineFilter) {
        filter = newValue
    }
}
