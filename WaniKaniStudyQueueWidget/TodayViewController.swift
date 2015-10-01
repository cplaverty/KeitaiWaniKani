//
//  TodayViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import NotificationCenter
import FMDB
import WaniKaniKit

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    // MARK: Properties
    
    private lazy var secureAppGroupPersistentStoreURL: NSURL = {
        let fm = NSFileManager.defaultManager()
        let directory = fm.containerURLForSecurityApplicationGroupIdentifier("group.uk.me.laverty.KeitaiWaniKani")!
        return directory.URLByAppendingPathComponent("WaniKaniData.sqlite")
        }()
    
    private var studyQueue: StudyQueue? {
        didSet {
            if studyQueue != oldValue {
                tableView.reloadData()
            }
        }
    }
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 95
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorEffect = UIVibrancyEffect.notificationCenterVibrancyEffect()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let studyQueue = try? fetchStudyQueueFromDatabase() {
            self.studyQueue = studyQueue
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        preferredContentSize = tableView.contentSize
    }
    
    // MARK: NCWidgetProviding
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        do {
            let oldStudyQueue = self.studyQueue
            studyQueue = try fetchStudyQueueFromDatabase()
            if studyQueue == oldStudyQueue {
                NSLog("Study queue not updated")
                completionHandler(.NoData)
            } else {
                NSLog("Study queue updated")
                completionHandler(.NewData)
            }
        } catch {
            NSLog("Error when refreshing study queue from today widget in completion handler: \(error)")
            completionHandler(.Failed)
        }
    }
    
    // MARK: Implementation
    
    func fetchStudyQueueFromDatabase() throws -> StudyQueue? {
        let databasePath = secureAppGroupPersistentStoreURL.path!
        guard NSFileManager.defaultManager().fileExistsAtPath(databasePath) else {
            NSLog("No database exists at \(databasePath)")
            return nil
        }
        
        let database = FMDatabase(path: databasePath)
        guard database.open() else {
            NSLog("Database failed to open! \(database.lastError())")
            throw database.lastError()
        }
        
        NSLog("Fetching study queue from database")
        return try StudyQueue.coder.loadFromDatabase(database)
    }
    
    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("StudyQueue", forIndexPath: indexPath) as! StudyQueueTableViewCell
        cell.studyQueue = self.studyQueue
        
        return cell
    }
    
}
