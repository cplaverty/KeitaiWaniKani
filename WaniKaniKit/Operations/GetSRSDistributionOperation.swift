//
//  GetSRSDistributionOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import FMDB
import OperationKit

public final class GetSRSDistributionOperation: GetSingleItemResourceOperation<SRSDistributionCoder> {
    private static let runTimeoutInSeconds = 20.0
    
    public init(resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver? = nil) {
        super.init(coder: SRSDistribution.coder, resolver: resolver, databaseQueue: databaseQueue, networkObserver: networkObserver)
        
        addObserver(TimeoutObserver(timeout: type(of: self).runTimeoutInSeconds))
    }
}
