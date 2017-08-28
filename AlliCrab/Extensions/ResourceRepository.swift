//
//  ResourceRepository.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import WaniKaniKit

extension ResourceRepository {
    var lastAppDataUpdateDate: Date? {
        return try! getEarliestLastUpdateDate(for: [.user, .assignments, .subjects])
    }
    
    @discardableResult func updateAppData(minimumFetchInterval: TimeInterval, completionHandler: @escaping (ResourceRefreshResult) -> Void) -> Progress {
        let expectedResultCount = 3
        
        var results = [ResourceRefreshResult]()
        results.reserveCapacity(expectedResultCount)
        
        let progress = Progress(totalUnitCount: 10)
        progress.completedUnitCount = 1
        
        let sharedCompletionHandler: (ResourceRefreshResult) -> Void = { result in
            switch result {
            case .success, .noData:
                results.append(result)
                if results.count == expectedResultCount {
                    if #available(iOS 10, *) {
                        os_log("All resources received.  Notifying completion.", type: .debug)
                    }
                    if results.contains(.success) {
                        completionHandler(.success)
                    } else {
                        completionHandler(.noData)
                    }
                } else if results.count > expectedResultCount {
                    fatalError("Received more results than expected!")
                }
            case .error(_):
                guard !progress.isCancelled else {
                    break
                }
                progress.cancel()
                completionHandler(result)
            }
        }
        
        progress.addChild(
            updateUser(minimumFetchInterval: minimumFetchInterval, completionHandler: sharedCompletionHandler),
            withPendingUnitCount: 1)
        progress.addChild(
            updateAssignments(minimumFetchInterval: minimumFetchInterval, completionHandler: sharedCompletionHandler),
            withPendingUnitCount: 4)
        progress.addChild(
            updateSubjects(minimumFetchInterval: minimumFetchInterval, completionHandler: sharedCompletionHandler),
            withPendingUnitCount: 4)
        
        return progress
    }
}
