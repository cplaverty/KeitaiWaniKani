//
//  StudyQueueIsUpdatedCondition.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit

public enum StudyQueueIsUpdatedConditionError: ErrorType {
    case NotUpdated
}

public struct StudyQueueIsUpdatedCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    
    private let databaseQueue: FMDatabaseQueue
    private let projectedStudyQueue: StudyQueue?
    
    public init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        self.projectedStudyQueue = self.dynamicType.projectedStudyQueue(databaseQueue)
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if let studyQueue = try? databaseQueue.withDatabase({ try StudyQueue.coder.loadFromDatabase($0) }) where studyQueue == projectedStudyQueue {
            completion(.Failed(StudyQueueIsUpdatedConditionError.NotUpdated))
        } else {
            completion(.Satisfied)
        }
    }
    
    private static func projectedStudyQueue(databaseQueue: FMDatabaseQueue) -> StudyQueue? {
        return (try? databaseQueue.withDatabase { try SRSDataItemCoder.projectedStudyQueue($0) }) ?? nil
    }
}
