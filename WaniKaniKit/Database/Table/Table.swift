//
//  Table.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

enum ColumnType: String {
    case int = "INTEGER"
    case float = "REAL"
    case numeric = "NUMERIC"
    case text = "TEXT"
    case blob = "BLOB"
}

class Column {
    let name: String
    let type: ColumnType
    let isNullable: Bool
    let isPrimaryKey: Bool
    let isUnique: Bool
    
    weak var table: Table?
    
    init(name: String, type: ColumnType, nullable: Bool = true, primaryKey: Bool = false, unique: Bool = false) {
        self.name = name
        self.type = type
        self.isNullable = nullable
        self.isPrimaryKey = primaryKey
        self.isUnique = unique
    }
}

extension Column: CustomStringConvertible {
    var description: String {
        guard let table = table else { return name }
        return "\(table.name).\(name)"
    }
}

class Table {
    let name: String
    
    // We have to make these vars so that we can create the Mirror in the initialiser
    var columns: [Column]! = nil
    var primaryKeys: [Column]? = nil
    var indexes: [TableIndex]? = nil
    
    init(name: String, indexes: [TableIndex]? = nil) {
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
        let primaryKeys = columns.filter { $0.isPrimaryKey }
        self.primaryKeys = primaryKeys.isEmpty ? nil : primaryKeys
        self.indexes = indexes
    }
    
    func createTableStatement() -> String {
        var query = "CREATE TABLE \(name) ("
        query += columns.lazy.map { column in
            var decl = "\(column.name) \(column.type.rawValue)"
            if !column.isNullable {
                decl += " NOT NULL"
            }
            
            if let primaryKeys = self.primaryKeys, primaryKeys.count == 1, column.isPrimaryKey {
                decl += " PRIMARY KEY"
            } else if column.isUnique {
                decl += " UNIQUE"
            }
            
            return decl
            }.joined(separator: ", ")
        if let primaryKeys = primaryKeys, primaryKeys.count > 1 {
            query += ", PRIMARY KEY ("
            query += primaryKeys.lazy.map { $0.name }.joined(separator: ", ")
            query += ")"
        }
        query += ");"
        
        if let indexes = indexes, !indexes.isEmpty {
            query += "\n"
            query += indexes.lazy.map { index in
                return (index.isUnique ? "CREATE UNIQUE INDEX" : "CREATE INDEX")
                    + " \(index.name) ON \(self.name) (\(index.columns.lazy.map { $0.name }.joined(separator: ", ")));"
                }.joined(separator: "\n")
        }
        return query
    }
}

extension Table: CustomStringConvertible {
    var description: String {
        return name
    }
}

class TableIndex {
    let name: String
    let columns: [Column]
    let isUnique: Bool
    
    init(name: String, columns: [Column], unique: Bool = false) {
        self.name = name
        self.columns = columns
        self.isUnique = unique
    }
}
