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

public struct BatchSizes {
    let radicals: Int?
    let kanji: Int?
    let vocabulary: Int?
    
    public init(radicals: Int? = nil, kanji: Int? = nil, vocabulary: Int? = nil) {
        self.radicals = radicals
        self.kanji = kanji
        self.vocabulary = vocabulary
    }
}

public struct DownloadStrategy {
    private struct State {
        let userInformation: UserInformation?
        let studyQueue: StudyQueue?
        
        init(databaseQueue: FMDatabaseQueue) {
            (userInformation, studyQueue) = try! databaseQueue.withDatabase {
                (try UserInformation.coder.load(from: $0), try StudyQueue.coder.load(from: $0))
            }
        }
    }
    
    // Intended as an override for unit tests, so they don't have to insert a UserInformation into the database
    var maxLevel: Int?
    
    private let databaseQueue: FMDatabaseQueue
    private let batchSizes: BatchSizes
    
    public init(databaseQueue: FMDatabaseQueue, batchSizes: BatchSizes) {
        self.databaseQueue = databaseQueue
        self.batchSizes = batchSizes
    }
    
    public func batches(coder: RadicalCoder) -> [DownloadBatches] {
        return calculateBatches(coder: coder, withMaxBatchSize: batchSizes.radicals)
    }
    
    public func batches(coder: KanjiCoder) -> [DownloadBatches] {
        return calculateBatches(coder: coder, withMaxBatchSize: batchSizes.kanji)
    }
    
    public func batches(coder: VocabularyCoder) -> [DownloadBatches] {
        return calculateBatches(coder: coder, withMaxBatchSize: batchSizes.vocabulary)
    }
    
    private func calculateBatches<Coder: ListItemDatabaseCoder>(coder: Coder, withMaxBatchSize batchSize: Int?) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        let levels = staleLevels(coder: coder, currentState: currentState) ?? Array(1...(maxLevel ?? currentState.userInformation!.level))
        let arguments: [String]
        if let batchSize = batchSize, batchSize < levels.count {
            arguments = stride(from: 0, to: levels.count, by: batchSize).map { start -> String in
                let end = min(levels.count - 1, start + batchSize - 1)
                return levelArrayToArgument(levels[start...end])
            }
        } else {
            arguments = [levelArrayToArgument(levels)]
        }
        
        if arguments.isEmpty {
            return []
        } else {
            return arguments.enumerated().map { (index, element) in
                DownloadBatches(description: arguments.count == 1 ? nil : "(batch \(index + 1) of \(arguments.count))", argument: element)
            }
        }
    }
    
    private func staleLevels<Coder: ListItemDatabaseCoder>(coder: Coder, currentState: State) -> [Int]? {
        guard let studyQueue = currentState.studyQueue, let userInformation = currentState.userInformation else { return nil }
        
        let currentLevel = userInformation.level
        let referenceDate = studyQueue.lastUpdateTimestamp
        let staleDate = Calendar.autoupdatingCurrent.date(byAdding: .weekOfYear, value: -2, to: referenceDate)!
        
        var levelRange: [Int]? = nil
        databaseQueue.inDatabase { db in
            do {
                var staleLevels = try coder.levelsNotUpdated(since: staleDate, in: db)
                staleLevels.formUnion(try coder.possiblyStaleLevels(since: studyQueue.lastUpdateTimestamp, in: db))
                staleLevels.insert(currentLevel)
                let maxSavedLevel = try coder.maxLevel(in: db)
                if maxSavedLevel < currentLevel {
                    staleLevels.formUnion((maxSavedLevel + 1)...currentLevel)
                } else {
                    staleLevels.insert(currentLevel)
                }
                levelRange = staleLevels.sorted()
            } catch {
                DDLogError("Failed to determine reduced fetch set for \(type(of: Coder.self)): \(error)")
            }
        }
        
        return levelRange
    }
    
    private func levelArrayToArgument<T: Collection>(_ levels: T) -> String where T.Iterator.Element == Int {
        return levels.map { $0.description }.joined(separator: ",")
    }
}
