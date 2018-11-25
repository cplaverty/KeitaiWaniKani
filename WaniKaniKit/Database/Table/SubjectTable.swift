//
//  SubjectTable.swift
//  WaniKaniKit
//
//  Copyright © 2018 Chris Laverty. All rights reserved.
//

protocol SubjectTable {
    var id: Table.Column { get }
    var level: Table.Column { get }
    var createdAt: Table.Column { get }
    var slug: Table.Column { get }
    var characters: Table.Column { get }
    var documentURL: Table.Column { get }
    var hiddenAt: Table.Column { get }
}
