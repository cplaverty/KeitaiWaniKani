//
//  GetDashboardDataOperation.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

final class GetDashboardDataOperation: GroupOperation, NSProgressReporting {
    
    let studyQueueOperation: GetStudyQueueOperation
    let levelProgressionOperation: GetLevelProgressionOperation
    let srsDistributionOperation: GetSRSDistributionOperation
    let srsDataItemOperation: GetSRSDataItemOperation
    
    let reviewTimeNotificationOperation: ReviewTimeNotificationOperation
    let reviewCountNotificationOperation: ReviewCountNotificationOperation
    
    let progress: NSProgress
    
    var fetchRequired: Bool {
        return studyQueueOperation.fetchRequired || levelProgressionOperation.fetchRequired || srsDistributionOperation.fetchRequired || srsDataItemOperation.fetchRequired
    }
    
    private var hasProducedAlert = false
    private let interactive: Bool
    
    init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, forcedFetch forced: Bool, isInteractive interactive: Bool, initialDelay delay: NSTimeInterval? = nil) {
        self.interactive = interactive
        let networkObserver = NetworkObserver()
        
        // Dummy op to prompt for notification permissions
        let dummy = BlockOperation {}
        dummy.addCondition(UserNotificationCondition(settings: UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil), application: UIApplication.sharedApplication()))
        
        progress = NSProgress(totalUnitCount: 10)
        progress.localizedDescription = "Downloading data from WaniKani"
        progress.localizedAdditionalDescription = "Waiting..."
        
        progress.becomeCurrentWithPendingUnitCount(1)
        studyQueueOperation = GetStudyQueueOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        if !forced {
            studyQueueOperation.addCondition(ModelObjectUpdateCheckCondition(lastUpdatedDate: WaniKaniAPI.lastRefreshTimeFromNow, coder: StudyQueue.coder, databaseQueue: databaseQueue))
        }
        
        let studyQueueIsUpdatedCondition = StudyQueueIsUpdatedCondition(databaseQueue: databaseQueue)
        
        progress.becomeCurrentWithPendingUnitCount(1)
        levelProgressionOperation = GetLevelProgressionOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        levelProgressionOperation.addCondition(NoCancelledDependencies())
        levelProgressionOperation.addCondition(studyQueueIsUpdatedCondition)
        
        progress.becomeCurrentWithPendingUnitCount(1)
        srsDistributionOperation = GetSRSDistributionOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        srsDistributionOperation.addCondition(NoCancelledDependencies())
        srsDistributionOperation.addCondition(studyQueueIsUpdatedCondition)
        
        progress.becomeCurrentWithPendingUnitCount(7)
        srsDataItemOperation = GetSRSDataItemOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        srsDataItemOperation.addCondition(NoCancelledDependencies())
        srsDataItemOperation.addCondition(studyQueueIsUpdatedCondition)
        
        reviewTimeNotificationOperation = ReviewTimeNotificationOperation(databaseQueue: databaseQueue)
        reviewTimeNotificationOperation.addDependency(studyQueueOperation)
        reviewCountNotificationOperation = ReviewCountNotificationOperation(databaseQueue: databaseQueue)
        reviewCountNotificationOperation.addDependency(srsDataItemOperation)
        
        levelProgressionOperation.addDependency(studyQueueOperation)
        srsDistributionOperation.addDependency(studyQueueOperation)
        srsDataItemOperation.addDependency(studyQueueOperation)
        
        super.init(operations: [dummy, studyQueueOperation, levelProgressionOperation, srsDistributionOperation, srsDataItemOperation, reviewTimeNotificationOperation, reviewCountNotificationOperation])
        progress.cancellationHandler = { self.cancel() }
        
        studyQueueOperation.addObserver(
            BlockObserver(
                startHandler: { _ in
                    self.progress.localizedDescription = "Downloading data from WaniKani"
                    self.progress.localizedAdditionalDescription = "Checking for update..."
                },
                finishHandler:{ _, _ in
                    let maybeStudyQueue = self.studyQueueOperation.parsed ?? { () -> StudyQueue? in
                        do {
                            return try databaseQueue.withDatabase { try SRSDataItemCoder.projectedStudyQueue($0) }
                        } catch {
                            DDLogWarn("Failed to calculate projectedStudyQueue to badge app icon: \(error)")
                            return nil
                        }
                        }()
                    guard let studyQueue = maybeStudyQueue else { return }
                    
                    DDLogDebug("Badging app icon: \(studyQueue.reviewsAvailable)")
                    let application = UIApplication.sharedApplication()
                    application.applicationIconBadgeNumber = studyQueue.reviewsAvailable
                }
            ))

        srsDataItemOperation.addObserver(
            BlockObserver(
                startHandler: { _ in
                    self.progress.localizedAdditionalDescription = "Downloading..."
                },
                finishHandler:{ _, _ in
                    self.progress.localizedAdditionalDescription = "Done!"
                }
            ))

        if let delay = delay {
            progress.totalUnitCount += 1
            let delayOperation = DelayOperation(interval: delay)
            progress.becomeCurrentWithPendingUnitCount(1)
            let countdownObserver = DelayOperationIntervalCountdownObserver(notificationInterval: 1)
            progress.resignCurrent()
            delayOperation.addObserver(countdownObserver)
            delayOperation.addProgressListenerForDestinationProgress(progress, sourceProgress: countdownObserver.progress)
            studyQueueOperation.addDependency(delayOperation)
            addOperation(delayOperation)
        }
        
        name = "Get Dashboard Data"
    }
    
    override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        guard interactive else { return }
        guard let firstError = errors.filterNonFatalErrors().first else {
            return
        }
        
        produceAlert(firstError)
    }
    
    private func produceAlert(error: ErrorType) {
        /*
        We only want to show the first error, since subsequent errors might
        be caused by the first.
        */
        if hasProducedAlert { return }
        
        let alert = AlertOperation()
        
        switch error {
        case ReachabilityConditionError.FailedToReachHost(host: let host):
            // We failed because the network isn't reachable.
            alert.title = "Unable to Connect"
            alert.message = "Cannot connect to \(host). Make sure your device is connected to the internet and try again."
            
        case NSCocoaError.PropertyListReadCorruptError:
            // We failed because the JSON was malformed.
            alert.title = "Unable to Download"
            alert.message = "Cannot download WaniKani API data. Try again later."
            
        case DownloadFileOperationError.InvalidHTTPResponse(URL: _, code: let code, message: let message):
            // We failed because the WaniKani site returned a non-2xx return code
            alert.title = "Invalid Response Code"
            alert.message = "WaniKani site returned an error code \(code) (\(message)). Try again later."

        case TimeoutObserverError.TimeoutOccurred(interval: _):
            alert.title = "Operation Timed Out"
            alert.message = "A timeout occurred downloading data from the WaniKani site. Please try the operation again."
            
        default:
            DDLogWarn("No error message for fatal error \(error)")
            return
        }
        
        produceOperation(alert)
        hasProducedAlert = true
    }
    
    override func finished(errors: [ErrorType]) {
        super.finished(errors)
        
        let fatalErrors = errors.filterNonFatalErrors()
        if !cancelled && fatalErrors.isEmpty {
            DDLogDebug("Updating last refresh time")
            ApplicationSettings.lastRefreshTime = NSDate()
            ApplicationSettings.forceRefresh = false
        } else {
            DDLogDebug("Not updating last refresh time due to fatal operation errors: \(fatalErrors)")
        }
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
    private func projectedStudyQueue(databaseQueue: FMDatabaseQueue) -> StudyQueue? {
        do {
            return try databaseQueue.withDatabase { try SRSDataItemCoder.projectedStudyQueue($0) }
        } catch {
            DDLogWarn("Failed to calculate projectedStudyQueue to badge app icon: \(error)")
            return nil
        }
    }
}

class DelayOperationIntervalCountdownObserver: NSObject, OperationObserver, NSProgressReporting {
    let progress: NSProgress = NSProgress(totalUnitCount: 1)
    
    private let formatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = .Abbreviated
        return formatter
        }()
    private let notificationInterval: NSTimeInterval
    private var notificationTimer: NSTimer?
    private var endDate: NSDate?
    
    init(notificationInterval: NSTimeInterval) {
        self.notificationInterval = notificationInterval
    }
    
    func operationDidStart(operation: Operation) {
        guard let delayOperation = operation as? DelayOperation else { return }
        
        switch delayOperation.delay {
        case .Interval(let interval): self.endDate = NSDate(timeIntervalSinceNow: interval)
        case .Date(let endDate): self.endDate = endDate
        }
        
        notificationTimer = NSTimer(timeInterval: notificationInterval, target: self, selector: #selector(timerTick(_:)), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(notificationTimer!, forMode: NSDefaultRunLoopMode)
        notificationTimer!.fire()
    }
    
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {}
    
    func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        progress.completedUnitCount = 1
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    func timerTick(timer: NSTimer) {
        guard let endDate = endDate, let formattedTimeRemaining = formatter.stringFromTimeInterval(endDate.timeIntervalSinceNow + 1) else { return }
        progress.localizedDescription = "WaniKani data download starting in \(formattedTimeRemaining)..."
    }
    
}
