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
    
    public func loadResource(id: Int, type: ResourceCollectionItemObjectType) throws -> ResourceCollectionItem {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try ResourceCollectionItem(from: database, id: id, type: type)
        }
    }
    
    public func loadResources(ids: [Int], type: ResourceCollectionItemObjectType) throws -> [ResourceCollectionItem] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try ResourceCollectionItem.read(from: database, ids: ids, type: type)
        }
    }
    
    public func loadSubjects(ids: [Int]) throws -> [ResourceCollectionItem] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            try ResourceCollectionItem.readSubjects(from: database, ids: ids)
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
                && ResourceType.subjects.getLastUpdateDate(in: database) != nil
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
            
            let assignments = Tables.assignments
            let subjects = Tables.subjectsView
            
            let lessonsAvailable = try database.longForQuery("""
                SELECT COUNT(*)
                FROM \(subjects) INNER JOIN \(assignments) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
                WHERE \(subjects.level) <= ?
                AND \(subjects.hiddenAt) IS NULL
                AND \(assignments.srsStage) = \(SRSStage.initiate.numericLevelRange.upperBound)
                AND \(assignments.unlockedAt) IS NOT NULL
                AND \(assignments.isHidden) = 0
                """,
                values: [userInfo.level])!
            let reviewsAvailable = try database.longForQuery("""
                SELECT COUNT(*)
                FROM \(assignments) INNER JOIN \(subjects) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
                WHERE \(subjects.level) <= ?
                AND \(subjects.hiddenAt) IS NULL
                AND \(assignments.srsStage) BETWEEN \(SRSStage.apprentice.numericLevelRange.lowerBound)
                AND \(SRSStage.enlightened.numericLevelRange.upperBound)
                AND \(assignments.availableAt) <= ?
                AND (\(assignments.burnedAt) IS NULL OR \(assignments.isResurrected) = 1)
                AND \(assignments.isHidden) = 0
                """,
                values: [userInfo.level, asOf])!
            let nextReviewDate = try database.dateForQuery("""
                SELECT MIN(\(assignments.availableAt))
                FROM \(assignments) INNER JOIN \(subjects) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
                WHERE \(subjects.level) <= ?
                AND \(subjects.hiddenAt) IS NULL
                AND \(assignments.availableAt) > ? AND \(assignments.isHidden) = 0
                """,
                values: [userInfo.level, asOf])
            
            let reviewsAvailableNextHour = try database.longForQuery("""
                SELECT COUNT(*)
                FROM \(assignments) INNER JOIN \(subjects) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
                WHERE \(subjects.level) <= ?
                AND \(subjects.hiddenAt) IS NULL
                AND \(assignments.availableAt) BETWEEN ? AND ?
                """,
                values: [userInfo.level, asOf, asOf.addingTimeInterval(.oneHour)])!
            let reviewsAvailableNextDay = try database.longForQuery("""
                SELECT COUNT(*)
                FROM \(assignments) INNER JOIN \(subjects) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
                WHERE \(subjects.level) <= ?
                AND \(assignments.availableAt) BETWEEN ? AND ?
                """,
                values: [userInfo.level, asOf, asOf.addingTimeInterval(.oneDay)])!
            
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
            let subjects = Tables.subjectsView
            
            guard let userInformation = try UserInformation(from: database) else {
                return CurrentLevelProgression(radicalsProgress: 0, radicalsTotal: 0, radicalSubjectIDs: [], kanjiProgress: 0, kanjiTotal: 0, kanjiSubjectIDs: [])
            }
            
            let query = """
            SELECT \(subjects.id), \(subjects.subjectType), coalesce(\(assignments.isPassed), 0) AS \(assignments.isPassed.name)
            FROM \(subjects) LEFT JOIN \(assignments) ON \(subjects.id) = \(assignments.subjectID)
            WHERE \(subjects.level) = :level
            AND \(subjects.subjectType) IN ('\(SubjectType.radical.rawValue)', '\(SubjectType.kanji.rawValue)')
            AND \(subjects.hiddenAt) IS NULL
            AND (\(assignments.isHidden) IS NULL OR \(assignments.isHidden) = 0)
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
                let subjectId = resultSet.long(forColumn: subjects.id.name)
                let passed = resultSet.bool(forColumn: assignments.isPassed.name)
                switch resultSet.rawValue(SubjectType.self, forColumn: subjects.subjectType.name)! {
                case .radical:
                    radicalSubjectIDs.append(subjectId)
                    if passed {
                        radicalsProgress += 1
                    }
                    radicalsTotal += 1
                case .kanji:
                    kanjiSubjectIDs.append(subjectId)
                    if passed {
                        kanjiProgress += 1
                    }
                    kanjiTotal += 1
                case .vocabulary:
                    fatalError("Only radicals and kanji contribute to levelling.  Getting this error suggests the query used is incorrect.")
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
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
                && ResourceType.assignments.getLastUpdateDate(in: database) != nil
        }
    }
    
    public func srsDistribution() throws -> SRSDistribution {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            guard let userInformation = try UserInformation(from: database) else {
                return SRSDistribution(countsBySRSStage: [:])
            }
            
            let assignments = Tables.assignments
            let subjects = Tables.subjectsView
            
            let radicalColumn = "radicals"
            let kanjiColumn = "kanji"
            let vocabularyColumn = "vocabulary"
            
            let query = """
            WITH counts(\(assignments.srsStage.name), \(radicalColumn), \(kanjiColumn), \(vocabularyColumn))
            AS (
            SELECT \(assignments.srsStage),
            CASE \(assignments.subjectType) WHEN '\(SubjectType.radical.rawValue)' THEN 1 ELSE 0 END,
            CASE \(assignments.subjectType) WHEN '\(SubjectType.kanji.rawValue)' THEN 1 ELSE 0 END,
            CASE \(assignments.subjectType) WHEN '\(SubjectType.vocabulary.rawValue)' THEN 1 ELSE 0 END
            FROM \(assignments) INNER JOIN \(subjects) ON \(assignments.subjectID) = \(subjects.id) AND \(assignments.subjectType) = \(subjects.subjectType)
            WHERE \(subjects.level) <= ?
            AND \(subjects.hiddenAt) IS NULL
            AND \(assignments.srsStage) > 0
            )
            SELECT \(assignments.srsStage.name),
            SUM(\(radicalColumn)) AS \(radicalColumn),
            SUM(\(kanjiColumn)) AS \(kanjiColumn),
            SUM(\(vocabularyColumn)) AS \(vocabularyColumn)
            FROM counts
            GROUP BY 1
            """
            
            let resultSet = try database.executeQuery(query, values: [userInformation.level])
            defer { resultSet.close() }
            
            var countsBySRSStage = [SRSStage: SRSItemCounts]()
            while resultSet.next() {
                let srsStageNumeric = resultSet.long(forColumn: assignments.srsStage.name)
                
                guard let srsStage = SRSStage(numericLevel: srsStageNumeric) else {
                    os_log("Returned unexpected numeric srs stage %d", type: .info, srsStageNumeric)
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
    
    public func hasReviewTimeline() throws -> Bool {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            return try ResourceType.user.getLastUpdateDate(in: database) != nil
                && ResourceType.assignments.getLastUpdateDate(in: database) != nil
                && ResourceType.subjects.getLastUpdateDate(in: database) != nil
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
            
            let radicalCounts = try itemCounts(for: .radical, userInformation: userInformation, level: level, srsStage: srsStage, from: database)
            let kanjiCounts = try itemCounts(for: .kanji, userInformation: userInformation, level: level, srsStage: srsStage, from: database)
            let vocabularyCounts = try itemCounts(for: .vocabulary, userInformation: userInformation, level: level, srsStage: srsStage, from: database)
            
            let totalCounts = radicalCounts
                .merging(kanjiCounts, uniquingKeysWith: +)
                .merging(vocabularyCounts, uniquingKeysWith: +)
                .map({ SRSReviewCounts(dateAvailable: $0.key, itemCounts: $0.value) })
                .sorted(by: { $0.dateAvailable < $1.dateAvailable })
            
            return totalCounts
        }
    }
    
    private func itemCounts(for subjectType: SubjectType, userInformation: UserInformation, level: Int?, srsStage: SRSStage?, from database: FMDatabase) throws -> [Date: SRSItemCounts] {
        let assignments = Tables.assignments
        let subjects = Tables.subjectTable(for: subjectType)
        
        var queryArgs = [String: Any]()
        queryArgs["subjectType"] = subjectType.rawValue
        
        var additionalCriteria = ""
        
        if let srsStage = srsStage {
            additionalCriteria += "\nAND \(assignments.srsStage) BETWEEN :srsStageLower AND :srsStageUpper"
            queryArgs["srsStageLower"] = srsStage.numericLevelRange.lowerBound
            queryArgs["srsStageUpper"] = srsStage.numericLevelRange.upperBound
        }
        
        if let level = level {
            additionalCriteria += "\nAND \(subjects.level) = :level"
            queryArgs["level"] = level
        } else {
            additionalCriteria += "\nAND \(subjects.level) <= :level"
            queryArgs["level"] = userInformation.level
        }
        
        let query = """
        SELECT \(assignments.availableAt), COUNT(*) AS count
        FROM \(assignments) INNER JOIN \(subjects) ON \(subjects.id) = \(assignments.subjectID)
        WHERE \(subjects.hiddenAt) IS NULL
        AND \(assignments.availableAt) IS NOT NULL
        AND \(assignments.isHidden) = 0
        AND \(assignments.subjectType) = :subjectType
        \(additionalCriteria)
        GROUP BY 1
        ORDER BY 1 ASC
        """
        
        guard let resultSet = database.executeQuery(query, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var results = [Date: SRSItemCounts]()
        while resultSet.next() {
            let dateAvailable = resultSet.date(forColumn: assignments.availableAt.name)!
            let count = resultSet.long(forColumn: "count")
            
            let itemCounts: SRSItemCounts;
            switch subjectType {
            case .radical:
                itemCounts = SRSItemCounts(radicals: count, kanji: 0, vocabulary: 0)
            case .kanji:
                itemCounts = SRSItemCounts(radicals: 0, kanji: count, vocabulary: 0)
            case .vocabulary:
                itemCounts = SRSItemCounts(radicals: 0, kanji: 0, vocabulary: count)
            }
            
            results[dateAvailable] = itemCounts
        }
        
        return results
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
            
            var levelProgressions = try LevelProgression.read(from: database).filter({ progress -> Bool in
                progress.abandonedAt == nil
            })
            
            let maxLevelToInfer = levelProgressions.first.map({ $0.level - 1 }) ?? userInfo.level
            if maxLevelToInfer > 0 {
                let maxInferredLevelEndDate = levelProgressions.first.flatMap({ $0.unlockedAt })
                let inferredLevelProgressions = try inferLevelProgressionFromSubjects(toLevel: maxLevelToInfer, toLevelStartDate: maxInferredLevelEndDate, from: database)
                
                // Let's not return partial results
                guard !inferredLevelProgressions.isEmpty else {
                    return LevelData(detail: [], projectedCurrentLevel: nil)
                }
                
                levelProgressions = inferredLevelProgressions + levelProgressions
            }
            
            let currentLevelStartDate = levelProgressions.last?.startedAt ?? Date()
            let projectedCurrentLevel = try projectedLevel(userInfo.level, startDate: currentLevelStartDate, from: database)
            
            return LevelData(detail: levelProgressions, projectedCurrentLevel: projectedCurrentLevel)
        }
    }
    
    private func inferLevelProgressionFromSubjects(toLevel maxLevel: Int, toLevelStartDate: Date?, from database: FMDatabase) throws -> [LevelProgression] {
        let radicalUnlockDatesByLevel = try getUnlockDatesByLevel(for: .radical, from: database)
        let kanjiUnlockDatesByLevel = try getUnlockDatesByLevel(for: .kanji, from: database)
        guard !radicalUnlockDatesByLevel.isEmpty && !kanjiUnlockDatesByLevel.isEmpty else {
            return []
        }
        
        let now = Date()
        
        var startDates = [Date]()
        startDates.reserveCapacity(maxLevel)
        
        for level in 1...maxLevel {
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
            os_log("Inferred level timeline: level = %d, earliestPossibleGuruDate = %@, minStartDate = %@", type: .debug, level, earliestPossibleGuruDate as NSDate, minStartDate as NSDate)
            startDates.append(minStartDate)
        }
        
        if let toLevelStartDate = toLevelStartDate {
            startDates.append(toLevelStartDate)
        }
        
        var levelProgressions = [LevelProgression]()
        levelProgressions.reserveCapacity(maxLevel)
        
        for level in 1...maxLevel {
            let startDate = startDates[level - 1]
            let endDate = startDates.count > level ? startDates[level] : nil
            let levelProgress = LevelProgression(level: level, createdAt: startDate, unlockedAt: startDate, startedAt: startDate, passedAt: endDate, completedAt: nil, abandonedAt: nil)
            levelProgressions.append(levelProgress)
        }
        
        return levelProgressions
    }
    
    public func subjects(srsStage: SRSStage) throws -> [(subject: Subject, assignment: Assignment)] {
        guard let databaseQueue = self.databaseQueue else {
            throw ResourceRepositoryError.noDatabase
        }
        
        return try databaseQueue.inDatabase { database in
            let assignmentsBySubjectID = try Assignment.read(from: database, srsStage: srsStage).values.reduce(into: [:], { (result, assignment) in
                result[assignment.subjectID] = assignment
            })
            let subjectItems = try ResourceCollectionItem.readSubjects(from: database, ids: Array(assignmentsBySubjectID.keys))
            
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
            
            return try SubjectSearch.read(from: database, searchQuery: query, maxLevel: userInfo.subscription.maxLevelGranted)
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
        }).sorted(by: { (lhs, rhs) in
            lhs.guruDate > rhs.guruDate
        })
        
        // You guru a level once at least 90% of all kanji is at Guru level or above, so skip past the first 10% of items
        let guruThresholdIndex = kanji.count / 10
        let guruThresholdItem = itemProgression[guruThresholdIndex]
        let earliestLevellingDate = guruThresholdItem.guruDate
        let isEndDateBasedOnLockedItem = guruThresholdItem.assignment?.unlockedAt == nil
        
        return ProjectedLevelInfo(level: level, startDate: startDate, endDate: earliestLevellingDate, isEndDateBasedOnLockedItem: isEndDateBasedOnLockedItem)
    }
    
    private func getUnlockDatesByLevel(for subjectType: SubjectType, from database: FMDatabase) throws -> [Int: [Date]] {
        let assignments = Tables.assignments
        let subjects = Tables.subjectTable(for: subjectType)
        
        let query = """
        SELECT \(subjects.level), \(assignments.unlockedAt)
        FROM \(subjects) INNER JOIN \(assignments) ON \(subjects.id) = \(assignments.subjectID)
        WHERE \(assignments.unlockedAt) IS NOT NULL
        ORDER BY 1, 2
        """
        
        let resultSet = try database.executeQuery(query, values: nil)
        defer { resultSet.close() }
        
        var unlockDatesByLevel = [Int: [Date]]()
        while resultSet.next() {
            let level = resultSet.long(forColumn: subjects.level.name)
            let dateUnlocked = resultSet.date(forColumn: assignments.unlockedAt.name)!
            if unlockDatesByLevel[level]?.append(dateUnlocked) == nil {
                unlockDatesByLevel[level] = [dateUnlocked]
            }
        }
        
        return unlockDatesByLevel
    }
    
}
