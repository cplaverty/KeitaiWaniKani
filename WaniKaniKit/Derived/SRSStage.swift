//
//  SRSStage.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum SRSStage: String {
    case initiate = "Initiate"
    case apprentice = "Apprentice"
    case guru = "Guru"
    case master = "Master"
    case enlightened = "Enlightened"
    case burned = "Burned"
    
    public init?(numericLevel: Int) {
        switch numericLevel {
        case 0:
            self = .initiate
        case 1...4:
            self = .apprentice
        case 5...6:
            self = .guru
        case 7:
            self = .master
        case 8:
            self = .enlightened
        case 9:
            self = .burned
        default:
            return nil
        }
    }
    
    public var numericLevelRange: CountableClosedRange<Int> {
        switch self {
        case .initiate:
            return 0...0
        case .apprentice:
            return 1...4
        case .guru:
            return 5...6
        case .master:
            return 7...7
        case .enlightened:
            return 8...8
        case .burned:
            return 9...9
        }
    }
}

extension SRSStage: Comparable {
    public static func <(lhs: SRSStage, rhs: SRSStage) -> Bool {
        return lhs.numericLevelRange.lowerBound < rhs.numericLevelRange.lowerBound
    }
    
    public static func >(lhs: SRSStage, rhs: SRSStage) -> Bool {
        return lhs.numericLevelRange.lowerBound > rhs.numericLevelRange.lowerBound
    }
}

extension SRSStage: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

extension SRSStage {
    public var backgroundColor: UIColor {
        switch self {
        case .initiate:
            return .clear
        case .apprentice:
            return .waniKaniApprentice
        case .guru:
            return .waniKaniGuru
        case .master:
            return .waniKaniMaster
        case .enlightened:
            return .waniKaniEnlightened
        case .burned:
            return .waniKaniBurned
        }
    }
}
