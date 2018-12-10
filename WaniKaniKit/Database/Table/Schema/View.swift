//
//  View.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

class View {
    let name: String
    
    // We have to make these vars so that we can create the Mirror in the initialiser
    var columns: [Column]! = nil
    private let selectStatement: String
    
    init(name: String, selectStatement: String) {
        self.name = name
        self.selectStatement = selectStatement
        let mirror = Mirror(reflecting: self)
        var columns = [Column]()
        columns.reserveCapacity(Int(mirror.children.count))
        for child in mirror.children {
            if let column = child.value as? Column {
                column.view = self
                columns.append(column)
            }
        }
        self.columns = columns
    }
    
    class Column {
        let name: String
        
        weak var view: View?
        
        init(name: String) {
            self.name = name
        }
    }
}

// MARK: - CustomStringConvertible
extension View: CustomStringConvertible {
    var description: String {
        return name
    }
}

extension View.Column: CustomStringConvertible {
    var description: String {
        guard let view = view else { return name }
        return "\(view.name).\(name)"
    }
}

// MARK: - TableProtocol
extension View: TableProtocol {
    var sqlStatement: String {
        var query = "CREATE VIEW \(name) ("
        query += columns.lazy.map({ $0.sqlStatement }).joined(separator: ", ")
        query += ") AS \(selectStatement)"
        
        return query
    }
}

// MARK: - ColumnProtocol
extension View.Column: ColumnProtocol {
    var sqlStatement: String {
        return name
    }
}
