//
//  GetLevelProgressionOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit

public final class GetLevelProgressionOperation: GetSingleItemResourceOperation<LevelProgressionCoder> {
    private static let runTimeoutInSeconds = 20.0
    
    public init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver? = nil) {
        super.init(coder: LevelProgression.coder, resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        
        addObserver(TimeoutObserver(timeout: self.dynamicType.runTimeoutInSeconds))
    }
}
