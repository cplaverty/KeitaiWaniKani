//
//  LevelProgression.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public struct LevelProgression: Equatable {
    public let radicalsProgress: Int
    public let radicalsTotal: Int
    public let radicalSubjectIDs: [Int]
    public let kanjiProgress: Int
    public let kanjiTotal: Int
    public let kanjiSubjectIDs: [Int]
    
    public var radicalsFractionComplete: Double {
        return radicalsTotal == 0 ? 1.0 : Double(radicalsProgress) / Double(radicalsTotal)
    }
    
    public var kanjiFractionComplete: Double {
        return kanjiTotal == 0 ? 1.0 : Double(kanjiProgress) / Double(kanjiTotal)
    }
    
    public init(radicalsProgress: Int, radicalsTotal: Int, radicalSubjectIDs: [Int], kanjiProgress: Int, kanjiTotal: Int, kanjiSubjectIDs: [Int]) {
        self.radicalsProgress = radicalsProgress
        self.radicalsTotal = radicalsTotal
        self.radicalSubjectIDs = radicalSubjectIDs
        self.kanjiProgress = kanjiProgress
        self.kanjiTotal = kanjiTotal
        self.kanjiSubjectIDs = kanjiSubjectIDs
    }
}

extension LevelProgression {
    public static func ==(lhs: LevelProgression, rhs: LevelProgression) -> Bool {
        return lhs.radicalsProgress == rhs.radicalsProgress
            && lhs.radicalsTotal == rhs.radicalsTotal
            && lhs.radicalSubjectIDs == rhs.radicalSubjectIDs
            && lhs.kanjiProgress == rhs.kanjiProgress
            && lhs.kanjiTotal == rhs.kanjiTotal
            && lhs.kanjiSubjectIDs == rhs.kanjiSubjectIDs
    }
}
