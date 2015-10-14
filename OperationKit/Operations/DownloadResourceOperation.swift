//
//  DownloadResourceOperation.swift
//  OperationKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack

public enum DownloadResourceOperationError: ErrorType {
    case InvalidHTTPResponse(URL: NSURL, code: Int, message: String)
}

public final class DownloadResourceOperation: Operation, NSURLSessionDownloadDelegate, NSProgressReporting {
    
    // MARK: Properties
    
    public let destinationFileURL: NSURL
    public let sourceURL: NSURL
    
    public let progress: NSProgress = {
        let p = NSProgress(totalUnitCount: -1)
        p.kind = NSProgressKindFile
        p.setUserInfoObject(NSProgressFileOperationKindDownloading, forKey: NSProgressFileOperationKindKey)
        return p
        }()
    
    private var task: NSURLSessionTask?
    
    // MARK: Initialization
    
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
    
    // MARK: Operation
    
    public override func execute() {
        assert(task == nil, "Operation executed twice?")
        
        DDLogInfo("Starting download of \(self.sourceURL)")
        progress.localizedAdditionalDescription = "Connecting..."
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForResource = NSTimeInterval(60 * 60) // Max resource timeout of an hour
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTaskWithURL(self.sourceURL)
        task!.resume()
    }
    
    public override func cancel() {
        DDLogInfo("Cancelling download of \(self.sourceURL)")
        super.cancel()
        task?.cancel()
    }
    
    public override func finished(errors: [ErrorType]) {
        super.finished(errors)
        
        DDLogVerbose("Download operation for \(self.destinationFileURL) finished")

        // Ensure progress is 100%
        if progress.totalUnitCount < 0 {
            progress.completedUnitCount = 1
            progress.totalUnitCount = 1
        } else {
            progress.completedUnitCount = progress.totalUnitCount
        }
    }
    
    // MARK: NSURLSessionDownloadDelegate
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DDLogVerbose("Downloaded \(totalBytesWritten)/\(totalBytesExpectedToWrite) of \(self.sourceURL)")
        if totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown {
            progress.localizedAdditionalDescription = nil
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
        } else {
            progress.localizedAdditionalDescription = "Downloading..."
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        DDLogInfo("Download of \(self.sourceURL) (\(self.formattedFileSizeOfFileAtURL(location)) to \(location) complete")
        
        if let downloadError = downloadTask.error {
            DDLogDebug("Download task has error: \(downloadError)")
            finishWithError(downloadError)
            return
        }
        
        if let response = downloadTask.response as? NSHTTPURLResponse {
            let statusCode = response.statusCode
            DDLogDebug("Got HTTP status code \(statusCode): \(NSHTTPURLResponse.localizedStringForStatusCode(statusCode))")
            guard statusCode / 100 == 2 else {
                let httpError = DownloadResourceOperationError.InvalidHTTPResponse(URL: response.URL!, code: statusCode, message: NSHTTPURLResponse.localizedStringForStatusCode(statusCode))
                finishWithError(httpError)
                return
            }
        }
        
        let fm = NSFileManager.defaultManager()
        do {
            // If we already have a file at this location, just delete it.
            try fm.removeItemAtURL(destinationFileURL)
        } catch NSCocoaError.FileNoSuchFileError {
            // Ignore errors if the file didn't exist
        } catch {
            DDLogWarn("Failed to remove destination file \(self.destinationFileURL): \(error)")
        }
        
        do {
            // Ensure the parent directory exists
            let parentDirectory = destinationFileURL.URLByDeletingLastPathComponent!
            try fm.createDirectoryAtURL(parentDirectory, withIntermediateDirectories: true, attributes: nil)
            
            DDLogVerbose("Moving temp file \(location) to \(self.destinationFileURL)")
            try fm.moveItemAtURL(location, toURL: destinationFileURL)
            finish()
        } catch let error {
            finishWithError(error)
        }
    }
    
    private func formattedFileSizeOfFileAtURL(location: NSURL) -> String {
        do {
            var fileSizeBytes: AnyObject?
            try location.getResourceValue(&fileSizeBytes, forKey: NSURLFileSizeKey)
            if let fileSizeBytes = fileSizeBytes as? NSNumber {
                return NSByteCountFormatter.stringFromByteCount(fileSizeBytes.longLongValue, countStyle: .File)
            }
        } catch {
            DDLogDebug("Failed to get file size due to error: \(error)")
        }
        
        return "unknown size"
    }
    
}
