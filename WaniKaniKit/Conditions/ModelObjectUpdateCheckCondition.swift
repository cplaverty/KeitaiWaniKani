//
//  ModelObjectUpdateCheckCondition.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import OperationKit

public enum ModelObjectUpdateCheckConditionError: ErrorType {
    case NoUpdateRequired(String)
}

public typealias LastUpdatedDateDelegate = () -> NSDate?

public struct ModelObjectUpdateCheckCondition<Coder: DatabaseCoder>: OperationCondition {
    public static var isMutuallyExclusive: Bool { return false }
    
    private let lastUpdatedDate: LastUpdatedDateDelegate
    private let coder: Coder
    private let databaseQueue: FMDatabaseQueue
    
    public init(lastUpdatedDate: LastUpdatedDateDelegate, coder: Coder, databaseQueue: FMDatabaseQueue) {
        self.lastUpdatedDate = lastUpdatedDate
        self.coder = coder
        self.databaseQueue = databaseQueue
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        guard let lastUpdatedDate = self.lastUpdatedDate() else {
            DDLogDebug("\(self.dynamicType) bypassing update check")
            completion(.Satisfied)
            return
        }
        
        DDLogDebug("Checking whether \(Coder.self) reports update since \(lastUpdatedDate)")
        let fetchRequired: Bool = try! databaseQueue.withDatabase { database in
            do {
                return try !self.coder.hasBeenUpdatedSince(lastUpdatedDate, inDatabase: database)
            } catch {
                DDLogWarn("\(Coder.self).hasBeenUpdatedSince(\(lastUpdatedDate)) threw error: \(error)")
                return true
            }
        }
        
        DDLogDebug("Fetch required for \(self.dynamicType)? \(fetchRequired)")
        if fetchRequired {
            completion(.Satisfied)
        } else {
            completion(.Failed(ModelObjectUpdateCheckConditionError.NoUpdateRequired("\(Coder.self)")))
        }
    }
}
