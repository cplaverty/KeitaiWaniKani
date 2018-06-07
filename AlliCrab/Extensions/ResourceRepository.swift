//
//  ResourceRepository.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import Foundation
import os
import WaniKaniKit

private var currentFetchRequest: Progress?
private let fetchRequestLock = NSLock()

extension ResourceRepository {
    var lastAppDataUpdateDate: Date? {
        return try! getEarliestLastUpdateDate(for: [ .assignments, .levelProgression, .reviewStatistics, .studyMaterials, .subjects, .user ])
    }
    
    @discardableResult func updateAppData(minimumFetchInterval: TimeInterval, completionHandler: @escaping (ResourceRefreshResult) -> Void) -> Progress {
        fetchRequestLock.lock()
        defer { fetchRequestLock.unlock() }
        
        if let currentFetchRequest = currentFetchRequest {
            os_log("Resource fetch requested but returning currently executing fetch request", type: .debug)
            return currentFetchRequest
        }
        
        let weightedUpdateOperations = [
            (Int64(4), updateAssignments),
            (Int64(1), updateLevelProgression),
            (Int64(2), updateReviewStatistics),
            (Int64(2), updateStudyMaterials),
            (Int64(4), updateSubjects),
            (Int64(1), updateUser),
            ]
        
        let expectedResultCount = weightedUpdateOperations.count
        let expectedTotalUnitCount = weightedUpdateOperations.reduce(1, { $0 + $1.0 })
        
        os_log("Scheduling resource fetch request", type: .debug)
        
        var results = [ResourceRefreshResult]()
        results.reserveCapacity(expectedResultCount)
        
        let progress = Progress(totalUnitCount: expectedTotalUnitCount)
        progress.completedUnitCount = 1
        
        let sharedCompletionHandler: (ResourceRefreshResult) -> Void = { result in
            switch result {
            case .success, .noData:
                results.append(result)
                if results.count == expectedResultCount {
                    os_log("All resources received.  Notifying completion.", type: .debug)
                    currentFetchRequest = nil
                    if results.contains(.success) {
                        completionHandler(.success)
                    } else {
                        completionHandler(.noData)
                    }
                } else if results.count > expectedResultCount {
                    fatalError("Received more results than expected!")
                }
            case .error(_):
                os_log("Received error on resource fetch.  Cancelling request and notifying completion.", type: .debug)
                currentFetchRequest = nil
                guard !progress.isCancelled else {
                    break
                }
                progress.cancel()
                completionHandler(result)
            }
        }
        
        for (weight, operation) in weightedUpdateOperations {
            progress.addChild(
                operation(minimumFetchInterval, sharedCompletionHandler),
                withPendingUnitCount: weight)
        }
        
        return progress
    }
}
