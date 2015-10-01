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
    
    func loadFromJSON(json: JSON) -> SRSItemCounts? {
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
    
    lazy var columnNames: String = { self.columnNameList.joinWithSeparator(",") }()
    
    lazy var columnCount: Int = { self.columnNameList.count }()
    
    func loadSRSItemCountsForRow(resultSet: FMResultSet) throws -> SRSItemCounts {
        return SRSItemCounts(radicals: resultSet.longForColumn(Columns.radicals),
            kanji: resultSet.longForColumn(Columns.kanji),
            vocabulary: resultSet.longForColumn(Columns.vocabulary),
            total: resultSet.longForColumn(Columns.total))
    }
    
    func srsItemCountsColumnValues(data: SRSItemCounts) -> [AnyObject] {
        return [data.radicals, data.kanji, data.vocabulary, data.total]
    }
}
