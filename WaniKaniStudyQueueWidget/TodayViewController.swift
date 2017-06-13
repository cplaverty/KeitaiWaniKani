//
//  TodayViewController.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import NotificationCenter
import FMDB
import WaniKaniKit

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    // MARK: - Properties
    
    private lazy var secureAppGroupPersistentStoreURL: URL = {
        let fm = FileManager.default
        let directory = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.uk.me.laverty.KeitaiWaniKani")!
        return directory.appendingPathComponent("WaniKaniData.sqlite")
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
        if #available(iOSApplicationExtension 10.0, *) {
            // No table separator for iOS 10
            tableView.separatorStyle = .none
            tableView.separatorEffect = nil
        } else {
            tableView.separatorStyle = .singleLine
            tableView.separatorEffect = UIVibrancyEffect.notificationCenter()
        }
        
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        CFNotificationCenterAddObserver(nc,
                                        observer,
                                        { (_, observer, name, _, _) in
                                            NSLog("Got notification for \(String(describing: name))")
                                            let mySelf = Unmanaged<TodayViewController>.fromOpaque(observer!).takeUnretainedValue()
                                            mySelf.updateStudyQueue()
                                        },
                                        WaniKaniDarwinNotificationCenter.notificationNameForModelObjectType("\(StudyQueue.self)"),
                                        nil,
                                        .deliverImmediately)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateStudyQueue()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        preferredContentSize = tableView.contentSize
    }
    
    deinit {
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveEveryObserver(nc, observer)
    }
    
    // MARK: - NCWidgetProviding
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        do {
            let oldStudyQueue = self.studyQueue
            studyQueue = try fetchStudyQueueFromDatabase()
            if studyQueue == oldStudyQueue {
                NSLog("Study queue not updated")
                completionHandler(.noData)
            } else {
                NSLog("Study queue updated")
                completionHandler(.newData)
            }
        } catch {
            NSLog("Error when refreshing study queue from today widget in completion handler: \(error)")
            completionHandler(.failed)
        }
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        NSLog("widgetActiveDisplayModeDidChange: \(activeDisplayMode) - \(maxSize)")
        if activeDisplayMode == .compact {
            tableView.rowHeight = maxSize.height
            preferredContentSize = maxSize
        }
    }
    
    // MARK: - Implementation
    
    func updateStudyQueue() {
        assert(Thread.isMainThread, "Study queue update must be done on the main thread")
        if let studyQueue = try? self.fetchStudyQueueFromDatabase() {
            self.studyQueue = studyQueue
        }
    }
    
    func fetchStudyQueueFromDatabase() throws -> StudyQueue? {
        let databasePath = secureAppGroupPersistentStoreURL.path
        guard FileManager.default.fileExists(atPath: databasePath) else {
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
        return try SRSDataItemCoder.projectedStudyQueue(database)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier: String
        if let studyQueue = self.studyQueue {
            if #available(iOSApplicationExtension 10.0, *) {
                identifier = "StudyQueueLight"
            } else {
                identifier = "StudyQueueDark"
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! StudyQueueTableViewCell
            cell.studyQueue = studyQueue
            
            return cell
        } else {
            if #available(iOSApplicationExtension 10.0, *) {
                identifier = "NotLoggedInLight"
            } else {
                identifier = "NotLoggedInDark"
            }
            return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.extensionContext?.open(URL(string: "kwk://launch/reviews")!, completionHandler: nil)
        DispatchQueue.main.async {
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
}
