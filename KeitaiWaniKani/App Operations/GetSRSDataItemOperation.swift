//
//  GetSRSDataItemOperation.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit
import WaniKaniKit

final class GetSRSDataItemOperation: GroupOperation, NSProgressReporting {
    let radicalsOperation: GetRadicalsOperation
    let kanjiOperation: GetKanjiOperation
    let vocabularyOperation: GetVocabularyOperation
    let reviewCountNotificationOperation: ReviewCountNotificationOperation
    
    let progress: NSProgress
    
    var fetchRequired: Bool {
        return radicalsOperation.fetchRequired || kanjiOperation.fetchRequired || vocabularyOperation.fetchRequired
    }
    
    init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver? = nil) {
        progress = NSProgress(totalUnitCount: 16)
        progress.localizedDescription = "Downloading SRS data from WaniKani"
        progress.localizedAdditionalDescription = "Waiting..."
        
        let downloadStrategy = DownloadStrategy(databaseQueue: databaseQueue)
        
        progress.becomeCurrentWithPendingUnitCount(3)
        radicalsOperation = GetRadicalsOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        radicalsOperation.addProgressListenerForDestinationProgress(progress)
        progress.resignCurrent()
        
        progress.becomeCurrentWithPendingUnitCount(5)
        kanjiOperation = GetKanjiOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        kanjiOperation.addProgressListenerForDestinationProgress(progress)
        progress.resignCurrent()
        
        progress.becomeCurrentWithPendingUnitCount(8)
        vocabularyOperation = GetVocabularyOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        vocabularyOperation.addProgressListenerForDestinationProgress(progress)
        progress.resignCurrent()
        
        kanjiOperation.addDependency(radicalsOperation)
        vocabularyOperation.addDependency(kanjiOperation)
        
        reviewCountNotificationOperation = ReviewCountNotificationOperation(databaseQueue: databaseQueue)
        reviewCountNotificationOperation.addDependencies([radicalsOperation, kanjiOperation, vocabularyOperation])
        
        super.init(operations: [radicalsOperation, kanjiOperation, vocabularyOperation, reviewCountNotificationOperation])
        progress.cancellationHandler = { self.cancel() }
        
        name = "Get SRS Data"
    }
}
