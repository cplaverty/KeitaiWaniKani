//
//  ReviewTimelineTableViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

enum ReviewTimelineFilter {
    case none, currentLevel, toBeBurned
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
    
    private static let reviewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
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
    
    private var reviewTimelineByDate = [(key: Date, value: [SRSReviewCounts])]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var assignmentsChangeObserver: NSObjectProtocol?
    
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
        guard !reviewTimelineByDate.isEmpty else {
            return nil
        }
        
        let (date, reviewCountsForDate) = reviewTimelineByDate[section]
        let totalForDay = reviewCountsForDate.reduce(0) { $0 + $1.itemCounts.total }
        
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseIdentifier.dateHeader.rawValue) as! ReviewTimelineHeaderFooterView
        view.updateHeader(date: date, totalForDay: totalForDay)
        
        return view
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ReviewTimelineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: ReuseIdentifier.dateHeader.rawValue)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        assignmentsChangeObserver = NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { _ in
            try! self.updateReviewTimeline()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let assignmentsChangeObserver = assignmentsChangeObserver {
            NotificationCenter.default.removeObserver(assignmentsChangeObserver)
        }
        assignmentsChangeObserver = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let segueIdentifier = SegueIdentifier(rawValue: identifier) else {
            return
        }
        
        switch segueIdentifier {
        case .reviewTimelineFilter:
            let vc = segue.destination as! ReviewTimelineFilterTableViewController
            vc.selectedValue = filter
            vc.delegate = self
            
            if let popover = vc.popoverPresentationController {
                popover.delegate = vc
            }
        }
    }
    
    // MARK: - Update UI
    
    private func updateReviewTimeline() throws {
        guard let repositoryReader = repositoryReader else {
            return
        }
        
        if #available(iOS 10.0, *) {
            os_log("Updating review timeline with filter %@", type: .info, String(describing: filter))
        }
        
        var level: Int? = nil
        var srsStage: SRSStage? = nil
        switch filter {
        case .none: break
        case .currentLevel:
            let user = try self.repositoryReader?.userInformation()
            level = user?.level
        case .toBeBurned:
            srsStage = .enlightened
        }
        
        let reviewTimeline = try repositoryReader.reviewTimeline(forLevel: level, forSRSStage: srsStage)
        
        let calendar = Calendar.current
        let pastDateMarker = Date(timeIntervalSince1970: 0)
        var reviewTimelineByDate = reviewTimeline.group { counts -> Date in
            let date = counts.dateAvailable
            return date.timeIntervalSinceNow <= 0 ? pastDateMarker : calendar.startOfDay(for: date)
        }
        
        if let pastReviewCounts = reviewTimelineByDate[pastDateMarker] {
            let aggregatedItemCounts = pastReviewCounts.lazy.map { $0.itemCounts }.reduce(.zero, +)
            reviewTimelineByDate[pastDateMarker] = [SRSReviewCounts(dateAvailable: pastDateMarker, itemCounts: aggregatedItemCounts)]
        }
        
        self.reviewTimelineByDate = reviewTimelineByDate.sorted { $0.key < $1.key }
    }
    
}

extension ReviewTimelineTableViewController: ReviewTimelineFilterDelegate {
    func reviewTimelineFilter(didChangeTo newValue: ReviewTimelineFilter) {
        filter = newValue
    }
}
