//
//  GetRadicalsOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit

public final class GetRadicalsOperation: GetListItemResourceOperation<RadicalCoder> {
    private static let runTimeoutInSeconds = 60.0
    
    public init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, downloadStrategy: DownloadStrategy, networkObserver: OperationObserver? = nil) {
        super.init(coder: Radical.coder, resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver, batchesForCoder: downloadStrategy.batches)
        
        addObserver(TimeoutObserver(timeout: self.dynamicType.runTimeoutInSeconds))
    }
}
