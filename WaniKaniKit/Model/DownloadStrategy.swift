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
    
    public init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
    }
    
    public func batchesForCoder(coder: RadicalCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        guard let levelRange = staleLevelsForCoder(coder, currentState: currentState) else {
            // Download everything
            return [DownloadBatches(description: nil, argument: nil)]
        }
        
        if levelRange.isEmpty {
            DDLogDebug("All radical levels up to date")
            return []
        } else {
            let argument = levelArrayToArgument(levelRange)
            DDLogDebug("Will fetch radicals for levels \(argument)")
            return [DownloadBatches(description: nil, argument: argument)]
        }
    }
    
    public func batchesForCoder(coder: KanjiCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        guard let levelRange = staleLevelsForCoder(coder, currentState: currentState) else {
            // Download everything
            return [DownloadBatches(description: nil, argument: nil)]
        }
        
        if levelRange.isEmpty {
            DDLogDebug("All kanji levels up to date")
            return []
        } else {
            let argument = levelArrayToArgument(levelRange)
            DDLogDebug("Will fetch kanji for levels \(argument)")
            return [DownloadBatches(description: nil, argument: argument)]
        }
    }
    
    public func batchesForCoder(coder: VocabularyCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        let levelRange = staleLevelsForCoder(coder, currentState: currentState) ?? Array(1...(maxLevel ?? currentState.userInformation!.level))
        let stride = 0.stride(to: levelRange.count, by: levelFetchBatchSize)
        
        let arguments = stride.map { start -> String in
            let end = min(levelRange.count - 1, start + levelFetchBatchSize - 1)
            return levelArrayToArgument(levelRange[start...end])
        }
        
        if arguments.isEmpty {
            DDLogDebug("All vocabulary levels up to date")
            return []
        } else {
            DDLogDebug("Will fetch vocabulary with batches \(arguments)")
            var batchNumber = 1
            return arguments.map { DownloadBatches(description: arguments.count == 1 ? nil : "(batch \(batchNumber++) of \(arguments.count))", argument: $0) }
        }
    }
    
    private func staleLevelsForCoder<Coder: ListItemDatabaseCoder>(coder: Coder, currentState: State) -> [Int]? {
        guard let studyQueue = currentState.studyQueue, userInformation = currentState.userInformation else { return nil }
        
        var levelRange: [Int]? = nil
        databaseQueue.inDatabase {
            do {
                let outstandingLessons = try coder.lessonsOutstanding($0).map {$0.level}
                let outstandingReviews = try coder.reviewsDueBefore(studyQueue.lastUpdateTimestamp, database: $0).map {$0.level}
                let currentLevel = userInformation.level
                let maxSavedLevel = coder.maxLevel($0)
                let missingLevels = maxSavedLevel < currentLevel ? ((maxSavedLevel + 1)...currentLevel) : currentLevel..<currentLevel
                levelRange = Set(outstandingLessons + outstandingReviews + missingLevels).sort()
            } catch {
                DDLogWarn("Failed to determine reduced fetch set for \(Coder.self.dynamicType): \(error)")
            }
        }
        
        return levelRange
    }
    
    private func levelArrayToArgument<T: CollectionType where T.Generator.Element == Int>(levels: T) -> String {
        return levels.map { $0.description }.joinWithSeparator(",")
    }
}
