//
//  DownloadStrategy.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import CocoaLumberjack

public struct DownloadBatches {
    let description: String?
    let argument: String?
}

public struct DownloadStrategy {
    private struct State {
        let userInformation: UserInformation?
        let studyQueue: StudyQueue?
        let levelProgression: LevelProgression?
        let srsDistribution: SRSDistribution?
        
        init(databaseQueue: FMDatabaseQueue) {
            (userInformation, studyQueue, levelProgression, srsDistribution) = try! databaseQueue.withDatabase {
                (try UserInformation.coder.loadFromDatabase($0), try StudyQueue.coder.loadFromDatabase($0), try LevelProgression.coder.loadFromDatabase($0), try SRSDistribution.coder.loadFromDatabase($0))
            }
        }
    }
    
    public var levelFetchBatchSize: Int = 20
    // Intended as an override for unit tests, so they don't have to insert a UserInformation into the database
    var maxLevel: Int?
    
    private let databaseQueue: FMDatabaseQueue
    
    private let initialState: State
    
    public init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        self.initialState = State(databaseQueue: databaseQueue)
    }
    
    public func batchesForCoder(coder: RadicalCoder) -> [DownloadBatches] {
        return [DownloadBatches(description: nil, argument: nil)]
    }
    
    public func batchesForCoder(coder: KanjiCoder) -> [DownloadBatches] {
        return [DownloadBatches(description: nil, argument: nil)]
    }
    
    public func batchesForCoder(coder: VocabularyCoder) -> [DownloadBatches] {
        return levelRangeArgumentListsUsingBatchSize(levelFetchBatchSize)
    }
    
    private func levelRangeArgumentListsUsingBatchSize(batchSize: Int) -> [DownloadBatches] {
        assert(batchSize > 0, "Batch size must be a positive number")
        
        let currentState = State(databaseQueue: self.databaseQueue)
        guard let level = maxLevel ?? currentState.userInformation?.level else {
            return []
        }
        
        let stride = 1.stride(through: level, by: batchSize)
        
        return stride.map { start -> DownloadBatches in
            let end = min(level, start + batchSize - 1)
            return DownloadBatches(description: start == end ? "Level \(start)" : "Levels \(start)-\(end)", argument: (start...end).map { $0.description }.joinWithSeparator(","))
        }
    }
}
