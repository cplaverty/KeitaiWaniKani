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
        
        init(databaseQueue: FMDatabaseQueue) {
            (userInformation, studyQueue) = try! databaseQueue.withDatabase {
                (try UserInformation.coder.load(from: $0), try StudyQueue.coder.load(from: $0))
            }
        }
    }
    
    public var levelFetchBatchSize = 20
    
    // Intended as an override for unit tests, so they don't have to insert a UserInformation into the database
    var maxLevel: Int?
    
    private let databaseQueue: FMDatabaseQueue
    
    public init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
    }
    
    public func batches(coder: RadicalCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        guard let levelRange = staleLevels(coder: coder, currentState: currentState) else {
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
    
    public func batches(coder: KanjiCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        guard let levelRange = staleLevels(coder: coder, currentState: currentState) else {
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
    
    public func batches(coder: VocabularyCoder) -> [DownloadBatches] {
        let currentState = State(databaseQueue: self.databaseQueue)
        let levelRange = staleLevels(coder: coder, currentState: currentState) ?? Array(1...(maxLevel ?? currentState.userInformation!.level))
        
        let arguments = stride(from: 0, to: levelRange.count, by: levelFetchBatchSize).map { start -> String in
            let end = min(levelRange.count - 1, start + levelFetchBatchSize - 1)
            return levelArrayToArgument(levelRange[start...end])
        }
        
        if arguments.isEmpty {
            DDLogDebug("All vocabulary levels up to date")
            return []
        } else {
            DDLogDebug("Will fetch vocabulary with batches \(arguments)")
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
        databaseQueue.inDatabase {
            do {
                var staleLevels = try coder.levelsNotUpdated(since: staleDate, in: $0!)
                staleLevels.formUnion(try coder.possiblyStaleLevels(since: studyQueue.lastUpdateTimestamp, in: $0!))
                staleLevels.insert(currentLevel)
                let maxSavedLevel = try coder.maxLevel(in: $0!)
                if maxSavedLevel < currentLevel {
                    staleLevels.formUnion((maxSavedLevel + 1)...currentLevel)
                } else {
                    staleLevels.insert(currentLevel)
                }
                levelRange = staleLevels.sorted()
            } catch {
                DDLogError("Failed to determine reduced fetch set for \(Coder.self.dynamicType): \(error)")
            }
        }
        
        return levelRange
    }
    
    private func levelArrayToArgument<T: Collection>(_ levels: T) -> String where T.Iterator.Element == Int {
        return levels.map { $0.description }.joined(separator: ",")
    }
}
