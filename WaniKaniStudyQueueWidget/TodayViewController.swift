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
    
    // MARK: - Properties
    
    private lazy var secureAppGroupPersistentStoreURL: NSURL = {
        let fm = NSFileManager.defaultManager()
        let directory = fm.containerURLForSecurityApplicationGroupIdentifier("group.uk.me.laverty.KeitaiWaniKani")!
        return directory.URLByAppendingPathComponent("WaniKaniData.sqlite")
    }()
    
    private var studyQueue: StudyQueue? {
        didSet {
            if studyQueue != oldValue {
                tableView.reloadData()
                preferredContentSize = tableView.contentSize
            }
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 95
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorEffect = UIVibrancyEffect.notificationCenterVibrancyEffect()
        
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
        
        CFNotificationCenterAddObserver(nc,
            observer,
            { (_, observer, name, _, _) in
                NSLog("Got notification for \(name)")
                let mySelf = Unmanaged<TodayViewController>.fromOpaque(COpaquePointer(observer)).takeUnretainedValue()
                dispatch_async(dispatch_get_main_queue()) {
                    mySelf.updateStudyQueue()
                }
            },
            WaniKaniDarwinNotificationCenter.notificationNameForModelObjectType("\(StudyQueue.self)"),
            nil,
            .DeliverImmediately)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateStudyQueue()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        preferredContentSize = tableView.contentSize
    }
    
    deinit {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveEveryObserver(nc, observer)
    }
    
    // MARK: - NCWidgetProviding
    
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
    
    // MARK: - Implementation
    
    func updateStudyQueue() {
        if let studyQueue = try? self.fetchStudyQueueFromDatabase() {
            self.studyQueue = studyQueue
        }
    }
    
    func fetchStudyQueueFromDatabase() throws -> StudyQueue? {
        let databasePath = secureAppGroupPersistentStoreURL.path!
        guard NSFileManager.defaultManager().fileExistsAtPath(databasePath) else {
            NSLog("No database exists at \(databasePath)")
            return nil
        }
        
        let database = FMDatabase(path: databasePath)
        guard database.open() else {
            let error = database.lastError()
            NSLog("Database failed to open! \(error)")
            throw error
        }
        defer { database.close() }
        
        NSLog("Fetching study queue from database")
        return try StudyQueue.coder.loadFromDatabase(database)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let studyQueue = self.studyQueue {
            let cell = tableView.dequeueReusableCellWithIdentifier("StudyQueue", forIndexPath: indexPath) as! StudyQueueTableViewCell
            cell.studyQueue = studyQueue
            
            return cell
        } else {
            return tableView.dequeueReusableCellWithIdentifier("NotLoggedIn", forIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.extensionContext?.openURL(NSURL(string: "kwk://launch/reviews")!, completionHandler: nil)
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
}
