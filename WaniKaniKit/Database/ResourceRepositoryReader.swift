//
//  ResourceRepositoryReader.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import os

public enum ResourceRepositoryError: Error {
    case noDatabase
}

public class ResourceRepositoryReader {
    private let databaseManager: DatabaseManager
    
    var databaseQueue: FMDatabaseQueue? {
        return databaseManager.databaseQueue
    }
    
    public init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    public func loadResource(id: Int) throws -> ResourceCollectionItem {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try ResourceCollectionItem(from: database, id: id)
        }
    }
    
    public func loadResources(ids: [Int]) throws -> [ResourceCollectionItem] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try ResourceCollectionItem.read(from: database, ids: ids)
        }
    }
    
    public func hasUserInformation() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func userInformation() throws -> UserInformation? {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try UserInformation(from: database)
        }
    }
    
    public func hasStudyQueue() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
                && ResourceType.assignments.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func studyQueue() throws -> StudyQueue {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            guard let userInfo = try UserInformation(from: database), userInfo.currentVacationStartedAt == nil else {
                return StudyQueue(lessonsAvailable: 0, reviewsAvailable: 0, nextReviewDate: nil, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
            }
            
            let asOf = Date()
            
            let table = Tables.assignments
            
            let lessonsAvailable = try database.longForQuery("SELECT COUNT(*) FROM \(table) WHERE \(table.srsStage) = \(SRSStage.initiate.numericLevelRange.upperBound)")!
            let reviewsAvailable = try database.longForQuery("SELECT COUNT(*) FROM \(table) WHERE \(table.srsStage) BETWEEN \(SRSStage.apprentice.numericLevelRange.lowerBound) and \(SRSStage.enlightened.numericLevelRange.upperBound) AND \(table.availableAt) <= ? AND \(table.burnedAt) IS NULL", values: [asOf])!
            let nextReviewDate = try database.dateForQuery("SELECT MIN(\(table.availableAt)) FROM \(table) WHERE \(table.availableAt) > ?", values: [asOf])
            
            let reviewsAvailableNextHour = try database.longForQuery("SELECT COUNT(*) FROM \(table) WHERE \(table.availableAt) BETWEEN ? AND ?",
                values: [asOf, asOf.addingTimeInterval(.oneHour)])!
            let reviewsAvailableNextDay = try database.longForQuery("SELECT COUNT(*) FROM \(table) WHERE \(table.availableAt) BETWEEN ? AND ?",
                values: [asOf, asOf.addingTimeInterval(.oneDay)])!
            
            return StudyQueue(lessonsAvailable: lessonsAvailable, reviewsAvailable: reviewsAvailable, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: reviewsAvailableNextHour, reviewsAvailableNextDay: reviewsAvailableNextDay)
        }
    }
    
    public func hasLevelProgression() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
                && ResourceType.assignments.getLastUpdateDate(in: database) != nil
                && ResourceType.subjects.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func levelProgression() throws -> CurrentLevelProgression {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let user = Tables.userInformation
            let assignments = Tables.assignments
            let radicals = Tables.radicals
            let kanji = Tables.kanji
            
            guard let userInformation = try UserInformation(from: database) else {
                return CurrentLevelProgression(radicalsProgress: 0, radicalsTotal: 0, radicalSubjectIDs: [], kanjiProgress: 0, kanjiTotal: 0, kanjiSubjectIDs: [])
            }
            
            let query = """
            SELECT \(radicals.id), '\(SubjectType.radical.rawValue)' AS \(assignments.subjectType.name), coalesce(\(assignments.isPassed), 0) AS \(assignments.isPassed.name)
            FROM \(radicals) LEFT JOIN \(assignments) ON \(radicals.id) = \(assignments.subjectID)
            WHERE \(radicals.level) = :level
            UNION ALL
            SELECT \(kanji.id), '\(SubjectType.kanji.rawValue)' AS \(assignments.subjectType.name), coalesce(\(assignments.isPassed), 0) AS \(assignments.isPassed.name)
            FROM \(kanji) LEFT JOIN \(assignments) ON \(kanji.id) = \(assignments.subjectID)
            WHERE \(kanji.level) = :level
            """
            
            guard let resultSet = database.executeQuery(query, withParameterDictionary: ["level": userInformation.level]) else {
                throw database.lastError()
            }
            defer { resultSet.close() }
            
            var radicalsProgress = 0
            var radicalsTotal = 0
            var radicalSubjectIDs = [Int]()
            var kanjiProgress = 0
            var kanjiTotal = 0
            var kanjiSubjectIDs = [Int]()
            
            while resultSet.next() {
                let passed = resultSet.bool(forColumn: assignments.isPassed.name)
                switch resultSet.rawValue(SubjectType.self, forColumn: assignments.subjectType.name)! {
                case .radical:
                    radicalSubjectIDs.append(resultSet.long(forColumn: radicals.id.name))
                    if passed {
                        radicalsProgress += 1
                    }
                    radicalsTotal += 1
                case .kanji:
                    kanjiSubjectIDs.append(resultSet.long(forColumn: kanji.id.name))
                    if passed {
                        kanjiProgress += 1
                    }
                    kanjiTotal += 1
                case .vocabulary:
                    fatalError()
                }
            }
            
            return CurrentLevelProgression(radicalsProgress: radicalsProgress, radicalsTotal: radicalsTotal, radicalSubjectIDs: radicalSubjectIDs, kanjiProgress: kanjiProgress, kanjiTotal: kanjiTotal, kanjiSubjectIDs: kanjiSubjectIDs)
        }
    }
    
    public func subjectProgression(type subjectType: SubjectType, forLevel level: Int) throws -> [SubjectProgression] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let items: [ResourceCollectionItem]
            let dependencies: [ResourceCollectionItem]
            
            switch subjectType {
            case .radical:
                items = try Radical.read(from: database, level: level)
                dependencies = []
            case .kanji:
                items = try Kanji.read(from: database, level: level)
                dependencies = try Radical.read(from: database, level: level)
            case .vocabulary:
                fatalError("Vocabulary progression not supported")
            }
            
            let allSubjects = items + dependencies
            let subjectsByID = allSubjects.reduce(into: [:]) { result, item in
                result[item.id] = item
            }
            let requiredAssigmentSubjectIDs = subjectsByID.keys + allSubjects.lazy.flatMap({ ($0.data as! Subject).componentSubjectIDs })
            let assignmentsBySubjectID = try Assignment.read(from: database, subjectIDs: requiredAssigmentSubjectIDs)
            
            return items.map({ item in
                SubjectProgression(subject: item.data as! Subject,
                                   assignment: assignmentsBySubjectID[item.id],
                                   getAssignmentForSubjectID: { subjectID in assignmentsBySubjectID[subjectID] })
            })
        }
    }
    
    public func hasSRSDistribution() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.assignments.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func srsDistribution() throws -> SRSDistribution {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let table = Tables.assignments
            
            let radicalColumn = "radicals"
            let kanjiColumn = "kanji"
            let vocabularyColumn = "vocabulary"
            
            let query = """
            WITH counts(\(table.srsStage.name), \(radicalColumn), \(kanjiColumn), \(vocabularyColumn))
            AS (
            SELECT \(table.srsStage),
            CASE \(table.subjectType) WHEN '\(SubjectType.radical.rawValue)' THEN 1 ELSE 0 END,
            CASE \(table.subjectType) WHEN '\(SubjectType.kanji.rawValue)' THEN 1 ELSE 0 END,
            CASE \(table.subjectType) WHEN '\(SubjectType.vocabulary.rawValue)' THEN 1 ELSE 0 END
            FROM \(table)
            WHERE \(table.srsStage) > 0
            )
            SELECT \(table.srsStage.name),
            SUM(\(radicalColumn)) AS \(radicalColumn),
            SUM(\(kanjiColumn)) AS \(kanjiColumn),
            SUM(\(vocabularyColumn)) AS \(vocabularyColumn)
            FROM counts
            GROUP BY 1
            """
            
            let resultSet = try database.executeQuery(query, values: nil)
            defer { resultSet.close() }
            
            var countsBySRSStage = [SRSStage: SRSItemCounts]()
            while resultSet.next() {
                let srsStageNumeric = resultSet.long(forColumn: table.srsStage.name)
                
                guard let srsStage = SRSStage(numericLevel: srsStageNumeric) else {
                    if #available(iOS 10.0, *) {
                        os_log("Returned unexpected numeric srs stage %d", type: .info, srsStageNumeric)
                    }
                    continue
                }
                
                let currentCount = countsBySRSStage[srsStage] ?? SRSItemCounts.zero
                let newCount = SRSItemCounts(radicals: resultSet.long(forColumn: radicalColumn),
                                             kanji: resultSet.long(forColumn: kanjiColumn),
                                             vocabulary: resultSet.long(forColumn: vocabularyColumn))
                countsBySRSStage[srsStage] = currentCount + newCount
            }
            
            return SRSDistribution(countsBySRSStage: countsBySRSStage)
        }
    }
    
    public func reviewTimeline(forLevel level: Int? = nil, forSRSStage srsStage: SRSStage? = nil) throws -> [SRSReviewCounts] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            guard let userInformation = try UserInformation(from: database), userInformation.currentVacationStartedAt == nil else {
                return []
            }
            
            let table = Tables.assignments
            
            let radicalColumn = "radicals"
            let kanjiColumn = "kanji"
            let vocabularyColumn = "vocabulary"
            
            var queryArgs = [String: Any]()
            
            if let srsStage = srsStage {
                queryArgs["srsStageLower"] = srsStage.numericLevelRange.lowerBound
                queryArgs["srsStageUpper"] = srsStage.numericLevelRange.upperBound
            } else {
                queryArgs["srsStageLower"] = SRSStage.apprentice.numericLevelRange.lowerBound
                queryArgs["srsStageUpper"] = SRSStage.enlightened.numericLevelRange.upperBound
            }
            
            var additionalCriteria = ""
            if let level = level {
                additionalCriteria += "AND \(table.level) = :level\n"
                queryArgs["level"] = level
            }
            
            let query = """
            WITH counts(\(table.availableAt.name), \(radicalColumn), \(kanjiColumn), \(vocabularyColumn))
            AS (
            SELECT \(table.availableAt),
            CASE \(table.subjectType) WHEN '\(SubjectType.radical.rawValue)' THEN 1 ELSE 0 END,
            CASE \(table.subjectType) WHEN '\(SubjectType.kanji.rawValue)' THEN 1 ELSE 0 END,
            CASE \(table.subjectType) WHEN '\(SubjectType.vocabulary.rawValue)' THEN 1 ELSE 0 END
            FROM \(table)
            WHERE \(table.availableAt) IS NOT NULL
            AND \(table.srsStage) BETWEEN :srsStageLower AND :srsStageUpper
            \(additionalCriteria)
            )
            SELECT \(table.availableAt.name),
            SUM(\(radicalColumn)) AS \(radicalColumn),
            SUM(\(kanjiColumn)) AS \(kanjiColumn),
            SUM(\(vocabularyColumn)) AS \(vocabularyColumn)
            FROM counts
            GROUP BY 1
            ORDER BY 1 ASC
            """
            
            guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
                throw database.lastError()
            }
            defer { resultSet.close() }
            
            var results = [SRSReviewCounts]()
            while resultSet.next() {
                results.append(
                    SRSReviewCounts(dateAvailable: resultSet.date(forColumn: table.availableAt.name)!,
                                    itemCounts: SRSItemCounts(
                                        radicals: resultSet.long(forColumn: radicalColumn),
                                        kanji: resultSet.long(forColumn: kanjiColumn),
                                        vocabulary: resultSet.long(forColumn: vocabularyColumn))))
            }
            
            return results
        }
    }
    
    public func hasLevelTimeline() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
                && ResourceType.assignments.getLastUpdateDate(in: database) != nil
                && ResourceType.subjects.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func levelTimeline() throws -> LevelData {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            guard let userInfo = try UserInformation(from: database) else {
                return LevelData(detail: [], projectedCurrentLevel: nil)
            }
            
            var radicalUnlockDatesByLevel = try getUnlockDatesByLevel(for: .radical, from: database)
            var kanjiUnlockDatesByLevel = try getUnlockDatesByLevel(for: .kanji, from: database)
            guard !radicalUnlockDatesByLevel.isEmpty && !kanjiUnlockDatesByLevel.isEmpty else {
                return LevelData(detail: [], projectedCurrentLevel: nil)
            }
            
            let now = Date()
            
            var startDates = [Date]()
            startDates.reserveCapacity(userInfo.level)
            
            for level in 1...userInfo.level {
                let earliestPossibleGuruDate = startDates.last.flatMap({ startOfPreviousLevel in
                    Assignment.earliestDate(from: startOfPreviousLevel,
                                            forItemAtSRSStage: SRSStage.apprentice.numericLevelRange.lowerBound,
                                            toSRSStage: SRSStage.guru.numericLevelRange.lowerBound,
                                            subjectType: .kanji,
                                            level: level)
                }) ?? Date.distantPast
                
                let unlockDates: [Date]
                if let radicalUnlockDates = radicalUnlockDatesByLevel[level], !radicalUnlockDates.isEmpty {
                    unlockDates = radicalUnlockDates
                } else if let kanjiUnlockDates = kanjiUnlockDatesByLevel[level], !kanjiUnlockDates.isEmpty {
                    unlockDates = kanjiUnlockDates
                } else {
                    unlockDates = []
                }
                
                let minStartDate = unlockDates.lazy.filter({ $0 > earliestPossibleGuruDate }).min() ?? now
                if #available(iOS 10.0, *) {
                    os_log("levelTimeline: level = %d, earliestPossibleGuruDate = %@, minStartDate = %@", type: .debug, level, earliestPossibleGuruDate as NSDate, minStartDate as NSDate)
                }
                startDates.append(minStartDate)
            }
            
            var levelProgressions = [LevelProgression]()
            levelProgressions.reserveCapacity(userInfo.level)
            
            for level in 1...userInfo.level {
                let startDate = startDates[level - 1]
                let endDate = startDates.count > level ? startDates[level] : nil
                let levelProgress = LevelProgression(level: level, createdAt: startDate, unlockedAt: startDate, startedAt: startDate, passedAt: endDate, completedAt: nil, abandonedAt: nil)
                levelProgressions.append(levelProgress)
            }
            
            let projectedCurrentLevel = try projectedLevel(userInfo.level, startDate: startDates.last!, from: database)
            
            return LevelData(detail: levelProgressions, projectedCurrentLevel: projectedCurrentLevel)
        }
    }
    
    public func subjects(ids: [Int]) throws -> [(subject: Subject, assignment: Assignment?)] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let subjectItems = try ResourceCollectionItem.read(from: database, ids: ids)
            let assignmentsBySubjectID = try Assignment.read(from: database, subjectIDs: ids)
            
            return subjectItems.map({ item in
                (item.data as! Subject, assignmentsBySubjectID[item.id])
            })
        }
    }
    
    public func subjects(srsStage: SRSStage) throws -> [(subject: Subject, assignment: Assignment)] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let assignmentsBySubjectID = try Assignment.read(from: database, srsStage: srsStage).values.reduce(into: [:], { (result, assignment) in
                result[assignment.subjectID] = assignment
            })
            let subjectItems = try ResourceCollectionItem.read(from: database, ids: Array(assignmentsBySubjectID.keys))
            
            return subjectItems.map({ item in
                (item.data as! Subject, assignmentsBySubjectID[item.id]!)
            })
        }
    }
    
    public func findSubjects(matching query: String) throws -> [ResourceCollectionItem] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            guard let userInfo = try UserInformation(from: database) else {
                return []
            }
            
            return try SubjectSearch.read(from: database, searchQuery: query, maxLevel: userInfo.maxLevelGrantedBySubscription)
        }
    }
    
    private func projectedLevel(_ level: Int, startDate: Date, from database: FMDatabase) throws -> ProjectedLevelInfo? {
        let kanji = try Kanji.read(from: database, level: level)
        guard !kanji.isEmpty else { return nil }
        
        let subjectIDs = kanji.map({ $0.id })
        let componentSubjectIDs = kanji.flatMap({ ($0.data as! Subject).componentSubjectIDs })
        
        let assignmentsBySubjectID = try Assignment.read(from: database, subjectIDs: subjectIDs + componentSubjectIDs)
        
        let now = Date()
        let itemProgression = kanji.map({ item -> (assignment: Assignment?, guruDate: Date) in
            let subject = item.data as! Subject
            let assignment = assignmentsBySubjectID[item.id]
            let guruDate = subject.earliestGuruDate(assignment: assignment, getAssignmentForSubjectID: { subjectID in assignmentsBySubjectID[subjectID] }) ?? now
            return (assignment, guruDate)
        }).sorted { (lhs, rhs) in
            lhs.guruDate > rhs.guruDate
        }
        
        // You guru a level once at least 90% of all kanji is at Guru level or above, so skip past the first 10% of items
        let guruThresholdIndex = kanji.count / 10
        let guruThresholdItem = itemProgression[guruThresholdIndex]
        let earliestLevellingDate = guruThresholdItem.guruDate
        let isEndDateBasedOnLockedItem = guruThresholdItem.assignment?.unlockedAt == nil
        
        return ProjectedLevelInfo(level: level, startDate: startDate, endDate: earliestLevellingDate, isEndDateBasedOnLockedItem: isEndDateBasedOnLockedItem)
    }
    
    private func getUnlockDatesByLevel(for subjectType: SubjectType, from database: FMDatabase) throws -> [Int: [Date]] {
        let table = Tables.assignments
        let query = """
        SELECT \(table.level), \(table.unlockedAt)
        FROM \(table)
        WHERE \(table.unlockedAt) IS NOT NULL
        AND \(table.subjectType) = ?
        ORDER BY 1, 2
        """
        
        let resultSet = try database.executeQuery(query, values: [subjectType.rawValue])
        defer { resultSet.close() }
        
        var unlockDatesByLevel = [Int: [Date]]()
        while resultSet.next() {
            let level = resultSet.long(forColumn: table.level.name)
            let dateUnlocked = resultSet.date(forColumn: table.unlockedAt.name)!
            if unlockDatesByLevel[level]?.append(dateUnlocked) == nil {
                unlockDatesByLevel[level] = [dateUnlocked]
            }
        }
        
        return unlockDatesByLevel
    }
    
}
