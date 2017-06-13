//
//  UserSpecificSRSDataCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON

extension UserSpecificSRSData {
    static let coder = UserSpecificSRSDataCoder()
}

final class UserSpecificSRSDataCoder: JSONDecoder {
    
    // MARK: - JSONDecoder
    
    func load(from json: JSON) -> UserSpecificSRSData? {
        guard
            let srsLevelRawValue = json["srs"].string,
            let srsLevel = SRSLevel(rawValue: srsLevelRawValue) else {
                return nil
        }
        
        let meaningStats = createStats(json, prefixedBy: "meaning")
        let readingStats = createStats(json, prefixedBy: "reading")
        let userSynonyms = json["user_synonyms"].arrayObject as? [String]
        
        return UserSpecificSRSData(srsLevel: srsLevel,
                                   srsLevelNumeric: json["srs_numeric"].intValue,
                                   dateUnlocked: json["unlocked_date"].date,
                                   dateAvailable: json["available_date"].date,
                                   burned: json["burned"].boolValue,
                                   dateBurned: json["burned_date"].date,
                                   meaningStats: meaningStats,
                                   readingStats: readingStats,
                                   meaningNote: json["meaning_note"].string,
                                   readingNote: json["reading_note"].string,
                                   userSynonyms: userSynonyms)
    }
    
    private func createStats(_ json: JSON, prefixedBy prefix: String) -> ItemStats? {
        let correctCount = json["\(prefix)_correct"].int
        let incorrectCount = json["\(prefix)_incorrect"].int
        let maxStreakLength = json["\(prefix)_max_streak"].int
        let currentStreakLength = json["\(prefix)_current_streak"].int
        
        return ItemStats(correctCount: correctCount, incorrectCount: incorrectCount, maxStreakLength: maxStreakLength, currentStreakLength: currentStreakLength)
    }
}

public class SRSDataItemCoder {
    fileprivate typealias Columns = UserSpecificSRSDataColumns
    
    struct UserSpecificSRSDataColumns {
        static let srsLevel = "srs"
        static let srsLevelNumeric = "srs_numeric"
        static let dateUnlocked = "unlocked_date"
        static let dateAvailable = "available_date"
        static let burned = "burned"
        static let dateBurned = "burned_date"
        static let meaningCorrectCount = "meaning_correct"
        static let meaningIncorrectCount = "meaning_incorrect"
        static let meaningMaxStreakLength = "meaning_max_streak"
        static let meaningCurrentStreakLength = "meaning_current_streak"
        static let readingCorrectCount = "reading_correct"
        static let readingIncorrectCount = "reading_incorrect"
        static let readingMaxStreakLength = "reading_max_streak"
        static let readingCurrentStreakLength = "reading_current_streak"
        static let meaningNote = "meaning_note"
        static let readingNote = "reading_note"
        static let userSynonyms = "user_synonyms"
    }
    
    private static let columnCount = 17
    let tableName: String
    
    var columnDefinitions: String {
        return "\(Columns.srsLevel) TEXT, " +
            "\(Columns.srsLevelNumeric) INT, " +
            "\(Columns.dateUnlocked) INT, " +
            "\(Columns.dateAvailable) INT, " +
            "\(Columns.burned) INT, " +
            "\(Columns.dateBurned) INT, " +
            "\(Columns.meaningCorrectCount) INT, " +
            "\(Columns.meaningIncorrectCount) INT, " +
            "\(Columns.meaningMaxStreakLength) INT, " +
            "\(Columns.meaningCurrentStreakLength) INT, " +
            "\(Columns.readingCorrectCount) INT, " +
            "\(Columns.readingIncorrectCount) INT, " +
            "\(Columns.readingMaxStreakLength) INT, " +
            "\(Columns.readingCurrentStreakLength) INT, " +
            "\(Columns.meaningNote) TEXT, " +
            "\(Columns.readingNote) TEXT, " +
            "\(Columns.userSynonyms) TEXT"
    }
    
    var columnNameList: [String] {
        return [Columns.srsLevel,
                Columns.srsLevelNumeric,
                Columns.dateUnlocked,
                Columns.dateAvailable,
                Columns.burned,
                Columns.dateBurned,
                Columns.meaningCorrectCount,
                Columns.meaningIncorrectCount,
                Columns.meaningMaxStreakLength,
                Columns.meaningCurrentStreakLength,
                Columns.readingCorrectCount,
                Columns.readingIncorrectCount,
                Columns.readingMaxStreakLength,
                Columns.readingCurrentStreakLength,
                Columns.meaningNote,
                Columns.readingNote,
                Columns.userSynonyms]
    }
    
    lazy var columnNames: String = { self.columnNameList.joined(separator: ",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    var srsDataIndices: String {
        return "CREATE INDEX IF NOT EXISTS idx_\(tableName)_dateAvailable ON \(tableName) (\(Columns.dateAvailable));"
    }
    
    init(tableName: String) {
        self.tableName = tableName
    }
    
    func loadSRSDataForRow(_ resultSet: FMResultSet) throws -> UserSpecificSRSData? {
        guard
            let srsLevelRawValue = resultSet.string(forColumn: Columns.srsLevel),
            let srsLevel = SRSLevel(rawValue: srsLevelRawValue) else {
                return nil
        }
        
        // TODO: userSynonyms
        return UserSpecificSRSData(srsLevel: srsLevel,
                                   srsLevelNumeric: resultSet.long(forColumn: Columns.srsLevelNumeric),
                                   dateUnlocked: resultSet.date(forColumn: Columns.dateUnlocked),
                                   dateAvailable: resultSet.date(forColumn: Columns.dateAvailable),
                                   burned: resultSet.bool(forColumn: Columns.burned),
                                   dateBurned: resultSet.date(forColumn: Columns.dateBurned),
                                   meaningStats: ItemStats(correctCount: resultSet.longForColumnOptional(Columns.meaningCorrectCount),
                                                           incorrectCount: resultSet.longForColumnOptional(Columns.meaningIncorrectCount),
                                                           maxStreakLength: resultSet.longForColumnOptional(Columns.meaningMaxStreakLength),
                                                           currentStreakLength: resultSet.longForColumnOptional(Columns.meaningCurrentStreakLength)),
                                   readingStats: ItemStats(correctCount: resultSet.longForColumnOptional(Columns.readingCorrectCount),
                                                           incorrectCount: resultSet.longForColumnOptional(Columns.readingIncorrectCount),
                                                           maxStreakLength: resultSet.longForColumnOptional(Columns.readingMaxStreakLength),
                                                           currentStreakLength: resultSet.longForColumnOptional(Columns.readingCurrentStreakLength)),
                                   meaningNote: resultSet.string(forColumn: Columns.meaningNote),
                                   readingNote: resultSet.string(forColumn: Columns.readingNote),
                                   userSynonyms: nil)
    }
    
    func srsDataColumnValues(_ data: UserSpecificSRSData?) -> [AnyObject] {
        guard let data = data else {
            return [AnyObject](repeating: NSNull(), count: type(of: self).columnCount)
        }
        
        return [
            data.srsLevel.rawValue as NSString,
            data.srsLevelNumeric as NSNumber,
            data.dateUnlocked as NSDate? ?? NSNull(),
            data.dateAvailable as NSDate? ?? NSNull(),
            data.burned as NSNumber,
            data.dateBurned as NSDate? ?? NSNull(),
            data.meaningStats?.correctCount as NSNumber? ?? NSNull(),
            data.meaningStats?.incorrectCount as NSNumber? ?? NSNull(),
            data.meaningStats?.maxStreakLength as NSNumber? ?? NSNull(),
            data.meaningStats?.currentStreakLength as NSNumber? ?? NSNull(),
            data.readingStats?.correctCount as NSNumber? ?? NSNull(),
            data.readingStats?.incorrectCount as NSNumber? ?? NSNull(),
            data.readingStats?.maxStreakLength as NSNumber? ?? NSNull(),
            data.readingStats?.currentStreakLength as NSNumber? ?? NSNull(),
            data.meaningNote as NSString? ?? NSNull(),
            data.readingNote as NSString? ?? NSNull(),
            NSNull() // TODO userSynonyms
        ]
    }
}

extension SRSDataItemCoder {
    
    // TODO: The level column name needs to be parameterised somehow
    private static var levelColumnName: String { return "level" }
    
    /// Takes an out-of-date StudyQueue and projects what it would look like from the SRS data if no reviews or lessons have been done
    public static func projectedStudyQueue(_ database: FMDatabase, referenceDate now: Date = Date()) throws -> StudyQueue? {
        guard let studyQueue = try StudyQueue.coder.load(from: database) else {
            return nil
        }
        
        let reviews = try reviewTimeline(database, since: studyQueue.lastUpdateTimestamp)
        guard !reviews.isEmpty else {
            return studyQueue
        }
        
        let calendar = Calendar.autoupdatingCurrent
        let inOneHour = calendar.date(byAdding: .hour, value: 1, to: now)!
        let inOneDay = calendar.date(byAdding: .day, value: 1, to: now)!
        
        var reviewsAvailable = studyQueue.reviewsAvailable
        var reviewsAvailableNextHour = 0
        var reviewsAvailableNextDay = 0
        for review in reviews {
            if review.dateAvailable > studyQueue.lastUpdateTimestamp && review.dateAvailable <= now {
                reviewsAvailable += review.itemCounts.total
            }
            if review.dateAvailable > now && review.dateAvailable <= inOneHour {
                reviewsAvailableNextHour += review.itemCounts.total
            }
            if review.dateAvailable > now && review.dateAvailable <= inOneDay {
                reviewsAvailableNextDay += review.itemCounts.total
            }
        }
        
        return StudyQueue(lessonsAvailable: studyQueue.lessonsAvailable,
                          reviewsAvailable: reviewsAvailable,
                          nextReviewDate: studyQueue.nextReviewDate.map { max($0, now) },
                          reviewsAvailableNextHour: reviewsAvailableNextHour,
                          reviewsAvailableNextDay: reviewsAvailableNextDay,
                          lastUpdateTimestamp: now)
    }
    
    public static func reviewTimeline(_ database: FMDatabase, since: Date? = nil, forLevel level: Int? = nil, rowLimit limit: Int? = nil) throws -> [SRSReviewCounts] {
        let radicalColumn = "radicals"
        let kanjiColumn = "kanji"
        let vocabularyColumn = "vocabulary"
        var queryArgs: [String: AnyObject] = [:]
        var whereStatement = "WHERE \(Columns.dateAvailable) IS NOT NULL AND \(Columns.burned) = 0"
        if let level = level {
            whereStatement += " AND \(levelColumnName) = :level"
            queryArgs["level"] = level as NSNumber
        }
        let dateColumn: String
        if let since = since {
            dateColumn = "CASE WHEN \(Columns.dateAvailable) < :dateAvailable THEN 0 ELSE \(Columns.dateAvailable) END AS \(Columns.dateAvailable)"
            queryArgs["dateAvailable"] = since.timeIntervalSince1970 as NSNumber
        } else {
            dateColumn = Columns.dateAvailable
        }
        let radicalCountSQL = "SELECT \(dateColumn), 1, 0, 0 FROM \(Radical.coder.tableName) \(whereStatement)"
        let kanjiCountSQL = "SELECT \(dateColumn), 0, 1, 0 FROM \(Kanji.coder.tableName) \(whereStatement)"
        let vocabularyCountSQL = "SELECT \(dateColumn), 0, 0, 1 FROM \(Vocabulary.coder.tableName) \(whereStatement)"
        let limitStatement = limit != nil ? " LIMIT \(limit!)" : ""
        let sql = "WITH counts (\(Columns.dateAvailable), \(radicalColumn), \(kanjiColumn), \(vocabularyColumn)) AS " +
            "(\(radicalCountSQL) UNION ALL \(kanjiCountSQL) UNION ALL \(vocabularyCountSQL)) " +
            "SELECT \(Columns.dateAvailable), SUM(\(radicalColumn)) AS \(radicalColumn), SUM(\(kanjiColumn)) AS \(kanjiColumn), SUM(\(vocabularyColumn)) AS \(vocabularyColumn) " +
            "FROM counts GROUP BY \(Columns.dateAvailable) ORDER BY \(Columns.dateAvailable) ASC\(limitStatement)"
        
        guard let resultSet = database.executeQuery(sql, withParameterDictionary: queryArgs) else {
            throw database.lastError()
        }
        defer { resultSet.close() }
        
        var results = [SRSReviewCounts]()
        while resultSet.next() {
            results.append(
                SRSReviewCounts(dateAvailable: resultSet.date(forColumn: Columns.dateAvailable)!,
                                itemCounts: SRSItemCounts(
                                    radicals: resultSet.long(forColumn: radicalColumn),
                                    kanji: resultSet.long(forColumn: kanjiColumn),
                                    vocabulary: resultSet.long(forColumn: vocabularyColumn))))
        }
        
        return results
    }
    
    public static func reviewTimelineByDate(_ database: FMDatabase, since: Date? = nil, forLevel level: Int? = nil, rowLimit limit: Int? = nil) throws -> [(key: Date, value: [SRSReviewCounts])] {
        let reviewTimeline = try self.reviewTimeline(database, since: since, forLevel: level, rowLimit: limit)
        var reviewsByDate: [Date: [SRSReviewCounts]] = [:]
        
        for review in reviewTimeline {
            let date = self.dateAtStartOfDay(review.dateAvailable)
            if case nil = reviewsByDate[date]?.append(review) {
                reviewsByDate[date] = [review]
            }
        }
        
        return reviewsByDate.sorted { $0.0 < $1.0 }
    }
    
    public static func levelTimeline(_ database: FMDatabase) throws -> LevelData {
        guard let userInfo = try UserInformation.coder.load(from: database) else {
            return LevelData(detail: [], projectedCurrentLevel: nil)
        }
        
        let now = Date()
        
        var radicalUnlockDatesByLevel = try getUnlockDatesByLevel(tableName: Radical.coder.tableName, in: database)
        var kanjiUnlockDatesByLevel = try getUnlockDatesByLevel(tableName: Kanji.coder.tableName, in: database)
        
        var startDates = [Date]()
        startDates.reserveCapacity(userInfo.level)
        
        for level in 1...userInfo.level {
            let isAcceleratedLevel = WaniKaniAPI.isAccelerated(level: level)
            let radicalUnlockDates = radicalUnlockDatesByLevel[level] ?? []
            let kanjiUnlockDates = kanjiUnlockDatesByLevel[level] ?? []
            
            let startOfPreviousLevel = startDates.last ?? Date.distantPast
            let eariestPossibleGuruDate = WaniKaniAPI.minimumTime(fromSRSLevel: 1, to: SRSLevel.guru.numericLevelThreshold, fromDate: startOfPreviousLevel, isAcceleratedLevel: isAcceleratedLevel) ?? Date.distantPast
            
            let minStartDate = (radicalUnlockDates + kanjiUnlockDates).lazy.flatMap { $0 }.filter { $0 > eariestPossibleGuruDate }.min()
            startDates.append(minStartDate ?? now)
        }
        
        var levelInfos = [LevelInfo]()
        levelInfos.reserveCapacity(userInfo.level)
        
        for level in 1...userInfo.level {
            let startDate = startDates[level - 1]
            let endDate: Date? = startDates.count > level ? startDates[level] : nil
            levelInfos.append(LevelInfo(level: level, startDate: startDate, endDate: endDate))
        }
        
        let projectedCurrentLevel = try currentLevelProjection(database, forLevel: userInfo.level, startDate: startDates.last ?? now)
        
        return LevelData(detail: levelInfos, projectedCurrentLevel: projectedCurrentLevel)
    }
    
    private static func currentLevelProjection(_ database: FMDatabase, forLevel level: Int, startDate: Date) throws -> ProjectedLevelInfo? {
        let currentLevelKanji = try Kanji.coder.load(from: database, level: level).sorted(by: SRSDataItemSorting.byProgress)
        guard !currentLevelKanji.isEmpty else { return nil }
        
        let currentLevelRadicals = try Radical.coder.load(from: database, level: level).sorted(by: SRSDataItemSorting.byProgress)
        let now = Date()
        let earliestGuruDateForAllRadicals = currentLevelRadicals.first?.guruDate(now) ?? now
        
        // You guru a level once at least 90% of all kanji is at Guru level or above, so skip past the first 10% of items
        let guruThresholdIndex = currentLevelKanji.count / 10
        let earliestLevellingDate = currentLevelKanji[guruThresholdIndex].guruDate(earliestGuruDateForAllRadicals) ?? now
        let endDateBasedOnLockedItem = currentLevelKanji[guruThresholdIndex].userSpecificSRSData?.dateUnlocked == nil
        
        DDLogVerbose("currentLevelProjectionFromDatabase: startDate = \(startDate), earliestGuruDateForAllRadicals = \(earliestGuruDateForAllRadicals), earliestLevellingDate = \(earliestLevellingDate), endDateBasedOnLockedItem = \(endDateBasedOnLockedItem)")
        return ProjectedLevelInfo(level: level, startDate: startDate, endDate: earliestLevellingDate, endDateBasedOnLockedItem: endDateBasedOnLockedItem)
    }
    
    private static func getUnlockDatesByLevel(tableName: String, in database: FMDatabase) throws -> [Int: [Date?]] {
        let sql = "SELECT \(levelColumnName), \(Columns.dateUnlocked) FROM \(tableName) ORDER BY 1, 2"
        let resultSet = try database.executeQuery(sql)
        defer { resultSet.close() }
        
        var unlockDatesByLevel: [Int: [Date?]] = [:]
        while resultSet.next() {
            let level = resultSet.long(forColumn: levelColumnName)
            let dateUnlocked = resultSet.date(forColumn: Columns.dateUnlocked)
            if case nil = unlockDatesByLevel[level]?.append(dateUnlocked) {
                unlockDatesByLevel[level] = [dateUnlocked]
            }
        }
        return unlockDatesByLevel
    }
    
    private static func dateAtStartOfDay(_ date: Date) -> Date {
        if date.timeIntervalSince1970 == 0 { return date }
        
        let calendar = Calendar.autoupdatingCurrent
        let dateComponents = calendar.dateComponents([ .day, .month, .year, .era ], from: date)
        return calendar.date(from: dateComponents)!
    }
    
}
