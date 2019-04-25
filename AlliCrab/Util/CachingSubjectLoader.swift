//
//  CachingSubjectLoader.swift
//  AlliCrab
//
//  Copyright © 2019 Chris Laverty. All rights reserved.
//

import WaniKaniKit

class CachingSubjectLoader {
    private let repositoryReader: ResourceRepositoryReader
    private var subjectsCache = [Subject?]()
    
    init(repositoryReader: ResourceRepositoryReader) {
        self.repositoryReader = repositoryReader
    }
    
    public var subjectIDs = [Int]() {
        didSet {
            subjectsCache = Array(repeating: nil, count: subjectIDs.count)
        }
    }
    
    public func subject(at index: Int) -> Subject {
        if let cached = subjectsCache[index] {
            return cached
        }
        
        let subject = try! repositoryReader.loadSubject(id: subjectIDs[index]).data as! Subject
        subjectsCache[index] = subject
        
        return subject
    }
}
