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

public enum ModelObjectUpdateCheckConditionError: Error {
    case noUpdateRequired(String)
}

public typealias LastUpdatedDateDelegate = () -> Date?

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
    
    public func dependency(for operation: OperationKit.Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluate(for operation: OperationKit.Operation, completion: @escaping (OperationConditionResult) -> Void) {
        guard let lastUpdatedDate = self.lastUpdatedDate() else {
            DDLogDebug("\(type(of: self)) bypassing update check")
            completion(.satisfied)
            return
        }
        
        DDLogDebug("Checking whether \(Coder.self) reports update since \(lastUpdatedDate)")
        let fetchRequired: Bool = try! databaseQueue.withDatabase { database in
            do {
                return try !self.coder.hasBeenUpdated(since: lastUpdatedDate, in: database)
            } catch {
                DDLogWarn("\(Coder.self).hasBeenUpdatedSince(\(lastUpdatedDate)) threw error: \(error)")
                return true
            }
        }
        
        DDLogDebug("Fetch required for \(type(of: self))? \(fetchRequired)")
        if fetchRequired {
            completion(.satisfied)
        } else {
            completion(.failed(ModelObjectUpdateCheckConditionError.noUpdateRequired("\(Coder.self)")))
        }
    }
}
