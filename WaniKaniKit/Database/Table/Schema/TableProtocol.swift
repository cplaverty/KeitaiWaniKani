//
//  TableProtocol.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

protocol TableProtocol: SQLConvertible, CustomStringConvertible {
    var name: String { get }
}

protocol ColumnProtocol: SQLConvertible, CustomStringConvertible {
    var name: String { get }
}
