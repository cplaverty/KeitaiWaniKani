//
//  StudyQueueIsUpdatedCondition.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit

public enum StudyQueueIsUpdatedConditionError: Error {
    case missing, notUpdated
}

public struct StudyQueueIsUpdatedCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    
    private let databaseQueue: FMDatabaseQueue
    private let projectedStudyQueue: StudyQueue?
    
    public init(databaseQueue: FMDatabaseQueue) {
        self.databaseQueue = databaseQueue
        self.projectedStudyQueue = self.dynamicType.projectedStudyQueue(databaseQueue)
    }
    
    public func dependency(forOperation operation: OperationKit.Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluate(forOperation operation: OperationKit.Operation, completion: (OperationConditionResult) -> Void) {
        guard let studyQueue = try! databaseQueue.withDatabase({ try StudyQueue.coder.load(from: $0) }) else {
            completion(.failed(StudyQueueIsUpdatedConditionError.missing))
            return
        }
        
        if studyQueue == projectedStudyQueue {
            completion(.failed(StudyQueueIsUpdatedConditionError.notUpdated))
        } else {
            completion(.satisfied)
        }
    }
    
    private static func projectedStudyQueue(_ databaseQueue: FMDatabaseQueue) -> StudyQueue? {
        return (try? databaseQueue.withDatabase { try SRSDataItemCoder.projectedStudyQueue($0) }) ?? nil
    }
}
