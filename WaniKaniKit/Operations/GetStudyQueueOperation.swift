//
//  GetStudyQueueOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import FMDB
import OperationKit

public final class GetStudyQueueOperation: GetSingleItemResourceOperation<StudyQueueCoder> {
    private static let runTimeoutInSeconds = 20.0
    
    public init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver? = nil) {
        super.init(coder: StudyQueue.coder, resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        
        addObserver(TimeoutObserver(timeout: self.dynamicType.runTimeoutInSeconds))
    }
}
