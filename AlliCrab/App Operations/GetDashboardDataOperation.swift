//
//  GetDashboardDataOperation.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import OperationKit
import WaniKaniKit

final class GetDashboardDataOperation: GroupOperation, ProgressReporting {
    
    let studyQueueOperation: GetStudyQueueOperation
    let levelProgressionOperation: GetLevelProgressionOperation
    let srsDistributionOperation: GetSRSDistributionOperation
    let srsDataItemOperation: GetSRSDataItemOperation
    
    let reviewTimeNotificationOperation: ReviewTimeNotificationOperation
    let reviewCountNotificationOperation: ReviewCountNotificationOperation
    
    let progress: Progress
    
    var fetchRequired: Bool {
        return studyQueueOperation.fetchRequired || levelProgressionOperation.fetchRequired || srsDistributionOperation.fetchRequired || srsDataItemOperation.fetchRequired
    }
    
    private var hasProducedAlert = false
    private let interactive: Bool
    
    init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, forcedFetch forced: Bool, isInteractive interactive: Bool, initialDelay delay: TimeInterval? = nil) {
        self.interactive = interactive
        let networkObserver = NetworkObserver()
        
        // Dummy op to prompt for notification permissions
        let dummy = OperationKit.BlockOperation {}
        dummy.addCondition(UserNotificationCondition(settings: UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil), application: UIApplication.shared))
        
        progress = Progress(totalUnitCount: 10)
        progress.localizedDescription = "Downloading data from WaniKani"
        progress.localizedAdditionalDescription = "Waiting..."
        
        progress.becomeCurrent(withPendingUnitCount: 1)
        studyQueueOperation = GetStudyQueueOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        if !forced {
            studyQueueOperation.addCondition(ModelObjectUpdateCheckCondition(lastUpdatedDate: WaniKaniAPI.lastRefreshTimeFromNow, coder: StudyQueue.coder, databaseQueue: databaseQueue))
        }
        
        let studyQueueIsUpdatedCondition = StudyQueueIsUpdatedCondition(databaseQueue: databaseQueue)
        
        progress.becomeCurrent(withPendingUnitCount: 1)
        levelProgressionOperation = GetLevelProgressionOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        levelProgressionOperation.addCondition(NoCancelledDependencies())
        levelProgressionOperation.addCondition(studyQueueIsUpdatedCondition)
        
        progress.becomeCurrent(withPendingUnitCount: 1)
        srsDistributionOperation = GetSRSDistributionOperation(resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        progress.resignCurrent()
        srsDistributionOperation.addCondition(NoCancelledDependencies())
        srsDistributionOperation.addCondition(studyQueueIsUpdatedCondition)
        
        progress.becomeCurrent(withPendingUnitCount: 7)
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
                    
                    DispatchQueue.main.async {
                        DDLogDebug("Badging app icon: \(studyQueue.reviewsAvailable)")
                        UIApplication.shared.applicationIconBadgeNumber = studyQueue.reviewsAvailable
                    }
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
            progress.becomeCurrent(withPendingUnitCount: 1)
            let countdownObserver = DelayOperationIntervalCountdownObserver(notificationInterval: 1)
            progress.resignCurrent()
            delayOperation.addObserver(countdownObserver)
            delayOperation.addProgressListener(copyingTo: progress, from: countdownObserver.progress)
            studyQueueOperation.addDependency(delayOperation)
            add(delayOperation)
        }
        
        name = "Get Dashboard Data"
    }
    
    override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) {
        guard interactive else { return }
        guard let firstError = errors.filterNonFatalErrors().first else {
            return
        }
        
        produceAlert(firstError)
    }
    
    private func produceAlert(_ error: Error) {
        /*
         We only want to show the first error, since subsequent errors might
         be caused by the first.
         */
        if hasProducedAlert { return }
        
        let alert = AlertOperation()
        
        switch error {
        case ReachabilityConditionError.failedToReachHost(host: let host):
            // We failed because the network isn't reachable.
            alert.title = "Unable to Connect"
            alert.message = "Cannot connect to \(host). Make sure your device is connected to the internet and try again."
            
        case CocoaError.propertyListReadCorrupt:
            // We failed because the JSON was malformed.
            alert.title = "Unable to Download"
            alert.message = "Cannot download WaniKani API data. Try again later."
            
        case DownloadFileOperationError.invalidHTTPResponse(url: _, code: let code, message: let message):
            // We failed because the WaniKani site returned a non-2xx return code
            alert.title = "Invalid Response Code"
            alert.message = "WaniKani site returned an error code \(code) (\(message)). Try again later."
            
        case TimeoutObserverError.timeoutOccurred(interval: _):
            alert.title = "Operation Timed Out"
            alert.message = "A timeout occurred downloading data from the WaniKani site. Please try the operation again."
            
        default:
            DDLogWarn("No error message for fatal error \(error)")
            return
        }
        
        produce(alert)
        hasProducedAlert = true
    }
    
    override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        let fatalErrors = errors.filterNonFatalErrors()
        if !isCancelled && fatalErrors.isEmpty {
            DDLogDebug("Updating last refresh time")
            ApplicationSettings.lastRefreshTime = Date()
            ApplicationSettings.forceRefresh = false
        } else {
            DDLogDebug("Not updating last refresh time due to fatal operation errors: \(fatalErrors)")
        }
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
    private func projectedStudyQueue(_ databaseQueue: FMDatabaseQueue) -> StudyQueue? {
        do {
            return try databaseQueue.withDatabase { try SRSDataItemCoder.projectedStudyQueue($0) }
        } catch {
            DDLogWarn("Failed to calculate projectedStudyQueue to badge app icon: \(error)")
            return nil
        }
    }
}

class DelayOperationIntervalCountdownObserver: NSObject, OperationObserver, ProgressReporting {
    let progress: Progress = Progress(totalUnitCount: 1)
    
    private let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    private let notificationInterval: TimeInterval
    private var notificationTimer: Timer?
    private var endDate: Date?
    
    init(notificationInterval: TimeInterval) {
        self.notificationInterval = notificationInterval
    }
    
    func operationDidStart(_ operation: OperationKit.Operation) {
        guard let delayOperation = operation as? DelayOperation else { return }
        
        switch delayOperation.delay {
        case .interval(let interval): self.endDate = Date(timeIntervalSinceNow: interval)
        case .date(let endDate): self.endDate = endDate
        }
        
        notificationTimer = Timer(timeInterval: notificationInterval, target: self, selector: #selector(timerTick(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(notificationTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        notificationTimer!.fire()
    }
    
    func operation(_ operation: OperationKit.Operation, didProduceOperation newOperation: Foundation.Operation) {}
    
    func operationDidFinish(_ operation: OperationKit.Operation, errors: [Error]) {
        progress.completedUnitCount = 1
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    func timerTick(_ timer: Timer) {
        guard let endDate = endDate, let formattedTimeRemaining = formatter.string(from: endDate.timeIntervalSinceNow + 1) else { return }
        progress.localizedDescription = "WaniKani data download starting in \(formattedTimeRemaining)..."
    }
    
}
