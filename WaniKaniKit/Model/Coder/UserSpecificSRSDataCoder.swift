//
//  UserSpecificSRSDataCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

extension UserSpecificSRSData {
    static let coder = UserSpecificSRSDataCoder()
}

final class UserSpecificSRSDataCoder: JSONDecoder {
    
    // MARK: - JSONDecoder
    
    func loadFromJSON(json: JSON) -> UserSpecificSRSData? {
        guard let srsLevelRawValue = json["srs"].string,
            srsLevel = SRSLevel(rawValue: srsLevelRawValue) else {
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
    
    private func createStats(json: JSON, prefixedBy prefix: String) -> ItemStats? {
        let correctCount = json["\(prefix)_correct"].int
        let incorrectCount = json["\(prefix)_incorrect"].int
        let maxStreakLength = json["\(prefix)_max_streak"].int
        let currentStreakLength = json["\(prefix)_current_streak"].int
        
        return ItemStats(correctCount: correctCount, incorrectCount: incorrectCount, maxStreakLength: maxStreakLength, currentStreakLength: currentStreakLength)
    }
}

public class SRSDataItemCoder {
    private struct Columns {
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
    
    lazy var columnNames: String = { self.columnNameList.joinWithSeparator(",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    var srsDataIndices: String {
        return "CREATE INDEX IF NOT EXISTS idx_\(tableName)_dateAvailable ON \(tableName) (\(Columns.dateAvailable));"
    }
    
    init(tableName: String) {
        self.tableName = tableName
    }
    
    func loadSRSDataForRow(resultSet: FMResultSet) throws -> UserSpecificSRSData? {
        guard let srsLevelRawValue = resultSet.stringForColumn(Columns.srsLevel),
            srsLevel = SRSLevel(rawValue: srsLevelRawValue) else {
                return nil
        }
        
        // TODO: userSynonyms
        return UserSpecificSRSData(srsLevel: srsLevel,
            srsLevelNumeric: resultSet.longForColumn(Columns.srsLevelNumeric),
            dateUnlocked: resultSet.dateForColumn(Columns.dateUnlocked),
            dateAvailable: resultSet.dateForColumn(Columns.dateAvailable),
            burned: resultSet.boolForColumn(Columns.burned),
            dateBurned: resultSet.dateForColumn(Columns.dateBurned),
            meaningStats: ItemStats(correctCount: resultSet.longForColumnOptional(Columns.meaningCorrectCount),
                incorrectCount: resultSet.longForColumnOptional(Columns.meaningIncorrectCount),
                maxStreakLength: resultSet.longForColumnOptional(Columns.meaningMaxStreakLength),
                currentStreakLength: resultSet.longForColumnOptional(Columns.meaningCurrentStreakLength)),
            readingStats: ItemStats(correctCount: resultSet.longForColumnOptional(Columns.readingCorrectCount),
                incorrectCount: resultSet.longForColumnOptional(Columns.readingIncorrectCount),
                maxStreakLength: resultSet.longForColumnOptional(Columns.readingMaxStreakLength),
                currentStreakLength: resultSet.longForColumnOptional(Columns.readingCurrentStreakLength)),
            meaningNote: resultSet.stringForColumn(Columns.meaningNote) as String?,
            readingNote: resultSet.stringForColumn(Columns.readingNote) as String?,
            userSynonyms: nil)
    }
    
    func srsDataColumnValues(data: UserSpecificSRSData?) -> [AnyObject] {
        guard let data = data else {
            return [AnyObject](count: self.dynamicType.columnCount, repeatedValue: NSNull())
        }
        
        return [
            data.srsLevel.rawValue,
            data.srsLevelNumeric,
            data.dateUnlocked ?? NSNull(),
            data.dateAvailable ?? NSNull(),
            data.burned,
            data.dateBurned ?? NSNull(),
            data.meaningStats?.correctCount ?? NSNull(),
            data.meaningStats?.incorrectCount ?? NSNull(),
            data.meaningStats?.maxStreakLength ?? NSNull(),
            data.meaningStats?.currentStreakLength ?? NSNull(),
            data.readingStats?.correctCount ?? NSNull(),
            data.readingStats?.incorrectCount ?? NSNull(),
            data.readingStats?.maxStreakLength ?? NSNull(),
            data.readingStats?.currentStreakLength ?? NSNull(),
            data.meaningNote ?? NSNull(),
            data.readingNote ?? NSNull(),
            NSNull() // TODO userSynonyms
        ]
    }
}

extension SRSDataItemCoder {
    
    /// Takes an out-of-date StudyQueue and projects what it would look like from the SRS data if no reviews or lessons have been done
    public static func projectedStudyQueue(database: FMDatabase, referenceDate now: NSDate = NSDate()) throws -> StudyQueue? {
        guard let studyQueue = try StudyQueue.coder.loadFromDatabase(database) else {
            return nil
        }
        
        // Row limit of 101 represents the number of 15-minute intervals in a day, plus one for the "Now"
        let reviews = try reviewTimeline(database, since: studyQueue.lastUpdateTimestamp, rowLimit: 101)
        
        guard !reviews.isEmpty else {
            return studyQueue
        }
        
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let inOneHour = calendar.dateByAddingUnit(.Hour, value: 1, toDate: now, options: [])
        let inOneDay = calendar.dateByAddingUnit(.Day, value: 1, toDate: now, options: [])
        
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
            nextReviewDate: studyQueue.nextReviewDate?.laterDate(now),
            reviewsAvailableNextHour: reviewsAvailableNextHour,
            reviewsAvailableNextDay: reviewsAvailableNextDay,
            lastUpdateTimestamp: now)
    }
    
    public static func reviewTimeline(database: FMDatabase, since: NSDate? = nil, forLevel level: Int? = nil, rowLimit limit: Int? = nil) throws -> [SRSReviewCounts] {
        let radicalColumn = "radicals"
        let kanjiColumn = "kanji"
        let vocabularyColumn = "vocabulary"
        var queryArgs: [String: AnyObject] = [:]
        var whereStatement = "WHERE \(Columns.dateAvailable) IS NOT NULL AND \(Columns.burned) == 0"
        if let level = level {
            // TODO: The level column name needs to be parameterised somehow
            whereStatement += " AND level = :level"
            queryArgs["level"] = level
        }
        let dateColumn: String
        if let since = since {
            dateColumn = "CASE WHEN \(Columns.dateAvailable) < :dateAvailable THEN 0 ELSE \(Columns.dateAvailable) END AS \(Columns.dateAvailable)"
            queryArgs["dateAvailable"] = since.timeIntervalSince1970
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
        
        var results = [SRSReviewCounts]()
        while resultSet.next() {
            results.append(
                SRSReviewCounts(dateAvailable: resultSet.dateForColumn(Columns.dateAvailable),
                    itemCounts: SRSItemCounts(
                        radicals: resultSet.longForColumn(radicalColumn),
                        kanji: resultSet.longForColumn(kanjiColumn),
                        vocabulary: resultSet.longForColumn(vocabularyColumn))))
        }
        
        return results
    }

    public static func reviewTimelineByDate(database: FMDatabase, since: NSDate? = nil, forLevel level: Int? = nil, rowLimit limit: Int? = nil) throws -> [(NSDate, [SRSReviewCounts])] {
        let reviewTimeline = try self.reviewTimeline(database, since: since, forLevel: level, rowLimit: limit)
        var reviewsByDate: [NSDate: [SRSReviewCounts]] = [:]
        
        for review in reviewTimeline {
            let date = self.dateAtStartOfDayForDate(review.dateAvailable)
            var currentItems = reviewsByDate[date] ?? []
            currentItems.append(review)
            reviewsByDate[date] = currentItems
        }
        
        return reviewsByDate.sort { $0.0 < $1.0 }
    }
    
    private static func dateAtStartOfDayForDate(date: NSDate) -> NSDate {
        if date.timeIntervalSince1970 == 0 { return date }
        
        let dayCalendarUnits: NSCalendarUnit = [ .Day, .Month, .Year, .Era ]
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let dateComponents = calendar.components(dayCalendarUnits, fromDate: date)
        return calendar.dateFromComponents(dateComponents)!
    }
}
