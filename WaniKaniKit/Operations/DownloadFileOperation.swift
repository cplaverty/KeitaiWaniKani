//
//  DownloadFileOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import Alamofire
import CocoaLumberjack
import OperationKit

public enum DownloadFileOperationError: ErrorType {
    case InvalidHTTPResponse(URL: NSURL, code: Int, message: String)
}

public class DownloadFileOperation: Operation, NSProgressReporting {
    
    // MARK: - Properties
    
    public let destinationFileURL: NSURL
    public let sourceURL: NSURL
    
    public let progress: NSProgress = {
        let p = NSProgress(totalUnitCount: -1)
        p.kind = NSProgressKindFile
        p.setUserInfoObject(NSProgressFileOperationKindDownloading, forKey: NSProgressFileOperationKindKey)
        return p
        }()
    
    private var request: Request?
    
    // MARK: - Initialization
    
    public init(sourceURL: NSURL, destinationFileURL: NSURL, networkObserver: OperationObserver? = nil) {
        assert(destinationFileURL.fileURL, "Destination URL must be a file path")
        
        self.destinationFileURL = destinationFileURL
        self.sourceURL = sourceURL
        
        super.init()
        
        let reachabilityCondition = ReachabilityCondition(URL: sourceURL)
        addCondition(reachabilityCondition)
        
        if let networkObserver = networkObserver {
            addObserver(networkObserver)
        }
        
        progress.cancellationHandler = { self.cancel() }
        
        name = "Download Resource"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        assert(request == nil, "Operation executed twice?")
        DDLogDebug("Starting download of \(self.sourceURL)")
        
        request = Alamofire.download(.GET, self.sourceURL) { _, _ in
            // Ensure the parent directory exists
            let parentDirectory = self.destinationFileURL.URLByDeletingLastPathComponent!
            try! NSFileManager.defaultManager().createDirectoryAtURL(parentDirectory, withIntermediateDirectories: true, attributes: nil)
            return self.destinationFileURL
            }
            .progress { [progress] bytesRead, totalBytesRead, totalBytesExpectedToRead in
                if totalBytesExpectedToRead != NSURLSessionTransferSizeUnknown {
                    progress.localizedAdditionalDescription = nil
                    progress.totalUnitCount = totalBytesExpectedToRead
                    progress.completedUnitCount = totalBytesRead
                } else {
                    progress.localizedAdditionalDescription = "Downloading..."
                }
            }
            .response { _, response, _, error in
                if let response = response {
                    let statusCode = response.statusCode
                    DDLogDebug("Got HTTP status code \(statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))")
                    guard statusCode / 100 == 2 else {
                        let httpError = DownloadFileOperationError.InvalidHTTPResponse(URL: response.URL!, code: statusCode, message: NSHTTPURLResponse.localizedStringForStatusCode(statusCode))
                        self.finishWithError(httpError)
                        return
                    }
                }
                self.finishWithError(error)
        }
    }
}
