//
//  ReviewTimelineTableViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import WaniKaniKit

class ReviewTimelineTableViewController: UITableViewController {
    
    // MARK: Properties
    
    private let reviewDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    private var reviewTimelineByDate: [(key: Date, value: [SRSReviewCounts])]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: Actions
    
    @IBAction func queryChanged(_ sender: UISegmentedControl) {
        loadReviewTimeline(currentLevelOnly: sender.selectedSegmentIndex != 0)
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        var items = self.toolbarItems ?? []
        
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        let segmentedControl = UISegmentedControl(items: ["All Reviews", "Current Level Only"])
        segmentedControl.addTarget(self, action: #selector(queryChanged(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        
        let segmentedControlBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        items.append(segmentedControlBarButtonItem)
        
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        self.setToolbarItems(items, animated: true)
        
        queryChanged(segmentedControl)
    }
    
    private func loadReviewTimeline(currentLevelOnly: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let databaseQueue = delegate.databaseQueue
        DispatchQueue.global(qos: .userInitiated).async {
            databaseQueue.inDatabase { [weak self] database in
                do {
                    let studyQueue = try StudyQueue.coder.load(from: database)
                    var level: Int? = nil
                    if currentLevelOnly {
                        let userInformation = try UserInformation.coder.load(from: database)
                        level = userInformation?.level
                    }
                    let result = try SRSDataItemCoder.reviewTimelineByDate(database, since: studyQueue?.lastUpdateTimestamp, forLevel: level)
                    
                    DispatchQueue.main.async {
                        self?.reviewTimelineByDate = result
                    }
                } catch {
                    self?.showAlert(title: "Failed to build review timeline", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return reviewTimelineByDate?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let reviewTimelineByDate = self.reviewTimelineByDate else {
            return 0
        }
        let (_, sectionRows) = reviewTimelineByDate[section]
        return sectionRows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewDetail", for: indexPath) as! ReviewTimelineEntryTableViewCell
        
        if let reviewTimelineByDate = self.reviewTimelineByDate {
            let (_, sectionRows) = reviewTimelineByDate[indexPath.section]
            cell.reviewCounts = sectionRows[indexPath.row]
        } else {
            DDLogWarn("Cell was dequeued for index path \(indexPath) before reviewTimelineByDate set")
            cell.reviewCounts = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let reviewTimelineByDate = self.reviewTimelineByDate else {
            return nil
        }
        let (date, entries) = reviewTimelineByDate[section]
        if date.timeIntervalSince1970 == 0 {
            return "Currently Available"
        } else {
            let totalForDay = entries.reduce(0) { $0 + $1.itemCounts.total }
            let formattedDate = reviewDateFormatter.string(from: date)
            let formattedTotal = NumberFormatter.localizedString(from: NSNumber(value: totalForDay), number: .decimal)
            return "\(formattedDate) (\(formattedTotal))"
        }
    }
    
}
