//
//  Table.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

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
        let primaryKeys = columns.filter({ $0.isPrimaryKey })
        self.primaryKeys = primaryKeys.isEmpty ? nil : primaryKeys
        self.indexes = indexes
        indexes?.forEach({ $0.table = self })
    }
    
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
    
    class TableIndex {
        let name: String
        let columns: [Column]
        let isUnique: Bool
        
        weak var table: Table?
        
        init(name: String, columns: [Column], unique: Bool = false) {
            self.name = name
            self.columns = columns
            self.isUnique = unique
        }
    }
}

// MARK: - CustomStringConvertible
extension Table: CustomStringConvertible {
    var description: String {
        return name
    }
}

extension Table.Column: CustomStringConvertible {
    var description: String {
        guard let table = table else { return name }
        return "\(table.name).\(name)"
    }
}

// MARK: - TableProtocol
extension Table: TableProtocol {
    var sqlStatement: String {
        var query = "CREATE TABLE \(name) ("
        query += columns.lazy.map({ $0.sqlStatement }).joined(separator: ", ")
        if let primaryKeys = primaryKeys {
            query += ", PRIMARY KEY ("
            query += primaryKeys.lazy.map({ $0.name }).joined(separator: ", ")
            query += ")"
        }
        query += ");"
        
        if let indexes = indexes, !indexes.isEmpty {
            query += "\n"
            query += indexes.lazy.map({ $0.sqlStatement }).joined(separator: "\n")
        }
        return query
    }
}

// MARK: - SQLConvertible
extension Table.Column: SQLConvertible {
    var sqlStatement: String {
        var decl = "\(name) \(type.rawValue)"
        if !isNullable {
            decl += " NOT NULL"
        }
        if isUnique {
            decl += " UNIQUE"
        }
        
        return decl
    }
}

extension Table.TableIndex: SQLConvertible {
    var sqlStatement: String {
        guard let table = table else {
            fatalError("Index not attached to a table!")
        }
        
        return (isUnique ? "CREATE UNIQUE INDEX" : "CREATE INDEX")
            + " \(name) ON \(table.name) (\(columns.lazy.map({ $0.name }).joined(separator: ", ")));"
    }
}
