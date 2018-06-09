//
//  TodayViewController.swift
//  WaniKaniStudyQueueWidget
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import NotificationCenter
import os
import UIKit
import WaniKaniKit

struct ApplicationURL {
    static let launchReviews = URL(string: "kwk://launch/reviews")!
}

class TodayViewController: UITableViewController {
    
    private enum ReuseIdentifier: String {
        case studyQueue = "StudyQueue"
        case notLoggedIn = "NotLoggedIn"
    }
    
    // MARK: - Properties
    
    private var studyQueue: StudyQueue? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.preferredContentSize = self.tableView.contentSize
            }
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let callback: CFNotificationCallback = { (_, observer, name, _, _) in
            os_log("Got notification for %@", type: .debug, name?.rawValue as String? ?? "<none>")
            let mySelf = Unmanaged<TodayViewController>.fromOpaque(observer!).takeUnretainedValue()
            _ = try? mySelf.updateStudyQueue()
        }
        
        CFNotificationCenterAddObserver(nc, observer, callback, CFNotificationName.waniKaniAssignmentsDidChange.rawValue, nil, .deliverImmediately)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _ = try? updateStudyQueue()
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
    
    // MARK: - Implementation
    
    private func latestStudyQueue() throws -> StudyQueue? {
        let databaseManager = DatabaseManager(factory: AppGroupDatabaseConnectionFactory())
        guard databaseManager.open(readOnly: true) else {
            return nil
        }
        
        let resourceRepository = ResourceRepositoryReader(databaseManager: databaseManager)
        guard try resourceRepository.hasStudyQueue() else {
            return nil
        }
        
        return try resourceRepository.studyQueue()
    }
    
    private func updateStudyQueue() throws -> Bool {
        let studyQueue = try latestStudyQueue()
        guard studyQueue != self.studyQueue else {
            return false
        }
        
        self.studyQueue = studyQueue
        return true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let studyQueue = self.studyQueue else {
            return tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.notLoggedIn.rawValue, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.studyQueue.rawValue, for: indexPath) as! StudyQueueTableViewCell
        cell.studyQueue = studyQueue
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.studyQueue != nil {
            self.extensionContext?.open(ApplicationURL.launchReviews, completionHandler: nil)
        }
        return nil
    }
    
}

// MARK: - NCWidgetProviding
extension TodayViewController: NCWidgetProviding {
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        do {
            let changed = try updateStudyQueue()
            if changed {
                os_log("Study queue updated", type: .debug)
                completionHandler(.newData)
            } else {
                os_log("Study queue not updated", type: .debug)
                completionHandler(.noData)
            }
        } catch ResourceRepositoryError.noDatabase {
            os_log("Database does not exist", type: .info)
            self.studyQueue = nil
            completionHandler(.noData)
        } catch {
            os_log("Error when refreshing study queue from today widget in completion handler: %@", type: .error, error as NSError)
            self.studyQueue = nil
            completionHandler(.failed)
        }
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        os_log("widgetActiveDisplayModeDidChange: activeDisplayMode = %i, maxSize = %@", type: .debug, activeDisplayMode.rawValue, maxSize.debugDescription)
        if activeDisplayMode == .compact {
            tableView.rowHeight = maxSize.height
            preferredContentSize = maxSize
        }
    }
}
