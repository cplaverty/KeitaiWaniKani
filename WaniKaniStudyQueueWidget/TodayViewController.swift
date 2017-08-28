//
//  TodayViewController.swift
//  WaniKaniStudyQueueWidget
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import UIKit
import NotificationCenter
import WaniKaniKit

class TodayViewController: UITableViewController, NCWidgetProviding {
    
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
        
        let callback: CFNotificationCallback = { (_, observer, name, _, _) in
            NSLog("Got notification for \(name?.rawValue as String? ?? "<none>")")
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
    
    // MARK: - NCWidgetProviding
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        do {
            let changed = try updateStudyQueue()
            if changed {
                NSLog("Study queue updated")
                completionHandler(.newData)
            } else {
                NSLog("Study queue not updated")
                completionHandler(.noData)
            }
        } catch ResourceRepositoryError.noDatabase {
            NSLog("Database does not exist")
            completionHandler(.noData)
        } catch {
            NSLog("Error when refreshing study queue from today widget in completion handler: \(error)")
            completionHandler(.failed)
        }
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        NSLog("widgetActiveDisplayModeDidChange: activeDisplayMode = \(activeDisplayMode), maxSize = \(maxSize)")
        if activeDisplayMode == .compact {
            tableView.rowHeight = maxSize.height
            preferredContentSize = maxSize
        }
    }
    
    // MARK: - Implementation
    
    func updateStudyQueue() throws -> Bool {
        let databaseManager = DatabaseManager(factory: AppGroupDatabaseConnectionFactory())
        guard databaseManager.open(readOnly: true) else {
            return false
        }
        
        let resourceRepository = ResourceRepositoryReader(databaseManager: databaseManager)
        
        let studyQueue = try resourceRepository.studyQueue()
        if studyQueue != self.studyQueue {
            self.studyQueue = studyQueue
            return true
        }
        
        return false
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
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.extensionContext?.open(URL(string: "kwk://launch/reviews")!, completionHandler: nil)
        return nil
    }
    
}
