//
//  ReviewTimelineTableViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import CocoaLumberjack
import WaniKaniKit

class ReviewTimelineTableViewController: UITableViewController {
    
    // MARK: Properties
    
    private let reviewDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .FullStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    
    private var reviewTimelineByDate: [(NSDate, [SRSReviewCounts])]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: Actions
    
    @IBAction func queryChanged(sender: UISegmentedControl) {
        loadReviewTimeline(sender.selectedSegmentIndex != 0)
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        var items = self.toolbarItems ?? []
        
        items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))

        let segmentedControl = UISegmentedControl(items: ["All Reviews", "Current Level Only"])
        segmentedControl.addTarget(self, action: "queryChanged:", forControlEvents: .ValueChanged)
        segmentedControl.selectedSegmentIndex = 0
        
        let segmentedControlBarButtonItem = UIBarButtonItem(customView: segmentedControl)
        items.append(segmentedControlBarButtonItem)
        
        items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
        
        self.setToolbarItems(items, animated: true)
        
        queryChanged(segmentedControl)
    }

    private func loadReviewTimeline(currentLevelOnly: Bool) {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            delegate.databaseQueue.inDatabase { [weak self] database in
                do {
                    let studyQueue = try StudyQueue.coder.loadFromDatabase(database)
                    var level: Int? = nil
                    if currentLevelOnly {
                        let userInformation = try UserInformation.coder.loadFromDatabase(database)
                        level = userInformation?.level
                    }
                    let result = try SRSDataItemCoder.reviewTimelineByDate(database, since: studyQueue?.lastUpdateTimestamp, forLevel: level)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.reviewTimelineByDate = result
                    }
                } catch {
                    self?.showAlertWithTitle("Failed to build review timeline", message: (error as NSError).localizedDescription)
                }
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return reviewTimelineByDate?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let reviewTimelineByDate = self.reviewTimelineByDate else {
            return 0
        }
        let (_, sectionRows) = reviewTimelineByDate[section]
        return sectionRows.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReviewDetail", forIndexPath: indexPath) as! ReviewTimelineEntryTableViewCell

        if let reviewTimelineByDate = self.reviewTimelineByDate {
            let (_, sectionRows) = reviewTimelineByDate[indexPath.section]
            cell.reviewCounts = sectionRows[indexPath.row]
        } else {
            DDLogWarn("Cell was dequeued for index path \(indexPath) before reviewTimelineByDate set")
            cell.reviewCounts = nil
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let reviewTimelineByDate = self.reviewTimelineByDate else {
            return nil
        }
        let (date, entries) = reviewTimelineByDate[section]
        if date.timeIntervalSince1970 == 0 {
            return "Currently Available"
        } else {
            let totalForDay = entries.reduce(0) { $0 + $1.itemCounts.total }
            let formattedDate = reviewDateFormatter.stringFromDate(date)
            let formattedTotal = NSNumberFormatter.localizedStringFromNumber(totalForDay, numberStyle: .DecimalStyle)
            return "\(formattedDate) (\(formattedTotal))"
        }
    }
    
}
