//
//  SRSItemCountsCoder.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

extension SRSItemCounts {
    static let coder = SRSItemCountsCoder()
}

final class SRSItemCountsCoder: JSONDecoder {
    
    // MARK: - JSONDecoder
    
    func load(from json: JSON) -> SRSItemCounts? {
        let radicals = json["radicals"].intValue
        let kanji = json["kanji"].intValue
        let vocabulary = json["vocabulary"].intValue
        let total = json["total"].intValue
        
        return SRSItemCounts(radicals: radicals, kanji: kanji, vocabulary: vocabulary, total: total)
    }
}

public class SRSItemCountsItem {
    private struct Columns {
        static let radicals = "radicals"
        static let kanji = "kanji"
        static let vocabulary = "vocabulary"
        static let total = "total"
    }
    
    var columnDefinitions: String {
        return "\(Columns.radicals) INT NOT NULL, " +
            "\(Columns.kanji) INT NOT NULL, " +
            "\(Columns.vocabulary) INT NOT NULL, " +
            "\(Columns.total) INT NOT NULL"
    }
    
    var columnNameList: [String] {
        return [Columns.radicals, Columns.kanji, Columns.vocabulary, Columns.total]
    }
    
    lazy var columnNames: String = { self.columnNameList.joined(separator: ",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    func loadSRSItemCountsForRow(_ resultSet: FMResultSet) throws -> SRSItemCounts {
        return SRSItemCounts(radicals: resultSet.long(forColumn: Columns.radicals),
                             kanji: resultSet.long(forColumn: Columns.kanji),
                             vocabulary: resultSet.long(forColumn: Columns.vocabulary),
                             total: resultSet.long(forColumn: Columns.total))
    }
    
    func srsItemCountsColumnValues(_ data: SRSItemCounts) -> [AnyObject] {
        return [data.radicals as NSNumber,
                data.kanji as NSNumber,
                data.vocabulary as NSNumber,
                data.total as NSNumber]
    }
}
