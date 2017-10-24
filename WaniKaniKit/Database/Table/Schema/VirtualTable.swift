//
//  VirtualTable.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

class VirtualTable {
    let name: String
    
    // We have to make these vars so that we can create the Mirror in the initialiser
    var columns: [Column]! = nil
    
    init(name: String) {
        self.name = name
        let mirror = Mirror(reflecting: self)
        var columns = [Column]()
        columns.reserveCapacity(Int(mirror.children.count))
        for child in mirror.children {
            if let column = child.value as? Column {
                column.table = self
                columns.append(column)
            }
        }
        self.columns = columns
    }
    
    class Column {
        let name: String
        let rank: Double
        
        weak var table: VirtualTable?
        
        init(name: String, rank: Double = 1.0) {
            self.name = name
            self.rank = rank
        }
    }
}

// MARK: - CustomStringConvertible
extension VirtualTable: CustomStringConvertible {
    var description: String {
        return name
    }
}

extension VirtualTable.Column: CustomStringConvertible {
    var description: String {
        guard let table = table else { return name }
        return "\(table.name).\(name)"
    }
}

// MARK: - TableProtocol
extension VirtualTable: TableProtocol {
    var sqlStatement: String {
        var query = "CREATE VIRTUAL TABLE \(name) USING fts5("
        query += columns.lazy.map({ $0.sqlStatement }).joined(separator: ", ")
        query += ", tokenize = porter);\n"
        query += "INSERT INTO \(name)(\(name), rank) VALUES('rank', 'bm25(\(columns.lazy.map({ String($0.rank) }).joined(separator: ", ")))');"
        
        return query
    }
}

// MARK: - SQLConvertible
extension VirtualTable.Column: SQLConvertible {
    var sqlStatement: String {
        return name
    }
}
