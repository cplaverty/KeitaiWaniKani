//
//  GetSRSDataItemOperation.swift
//  AlliCrab
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit
import WaniKaniKit

final class GetSRSDataItemOperation: GroupOperation, ProgressReporting {
    let radicalsOperation: GetRadicalsOperation
    let kanjiOperation: GetKanjiOperation
    let vocabularyOperation: GetVocabularyOperation
    
    let progress: Progress
    
    var fetchRequired: Bool {
        return radicalsOperation.fetchRequired || kanjiOperation.fetchRequired || vocabularyOperation.fetchRequired
    }
    
    init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver? = nil) {
        progress = Progress(totalUnitCount: 16)
        progress.localizedDescription = "Downloading SRS data"
        progress.localizedAdditionalDescription = "Waiting..."
        
        let downloadStrategy = DownloadStrategy(databaseQueue: databaseQueue, batchSizes: BatchSizes(vocabulary: 15))
        
        progress.becomeCurrent(withPendingUnitCount: 3)
        radicalsOperation = GetRadicalsOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        progress.resignCurrent()
        
        progress.becomeCurrent(withPendingUnitCount: 5)
        kanjiOperation = GetKanjiOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        progress.resignCurrent()
        
        progress.becomeCurrent(withPendingUnitCount: 8)
        vocabularyOperation = GetVocabularyOperation(resolver: resolver, databaseQueue: databaseQueue, downloadStrategy: downloadStrategy, networkObserver: networkObserver)
        progress.resignCurrent()
        
        super.init(operations: [radicalsOperation, kanjiOperation, vocabularyOperation])
        progress.cancellationHandler = { self.cancel() }
        
        name = "Get SRS Data"
    }
}
