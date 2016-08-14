//
//  DownloadFileOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import OperationKit

public enum DownloadFileOperationError: Error {
    case invalidHTTPResponse(url: URL, code: Int, message: String)
}

public class DownloadFileOperation: OperationKit.Operation, URLSessionDownloadDelegate, ProgressReporting {
    
    // MARK: - Properties
    
    public let destinationFileURL: URL
    public let sourceURL: URL
    
    public let progress: Progress = {
        let p = Progress(totalUnitCount: -1)
        p.kind = ProgressKind.file
        p.setUserInfoObject(Progress.FileOperationKind.downloading, forKey: .fileOperationKindKey)
        return p
    }()
    
    private var task: URLSessionTask?
    
    // MARK: - Initialization
    
    public init(sourceURL: URL, destinationFileURL: URL, networkObserver: OperationObserver? = nil) {
        assert(destinationFileURL.isFileURL, "Destination URL must be a file path")
        
        self.destinationFileURL = destinationFileURL
        self.sourceURL = sourceURL
        
        super.init()
        
        let reachabilityCondition = ReachabilityCondition(url: sourceURL)
        addCondition(reachabilityCondition)
        
        if let networkObserver = networkObserver {
            addObserver(networkObserver)
        }
        
        progress.cancellationHandler = { self.cancel() }
        
        name = "Download Resource"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        assert(task == nil, "Operation executed twice?")
        
        DDLogInfo("Starting download of \(self.sourceURL)")
        progress.localizedAdditionalDescription = "Connecting..."
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = TimeInterval(60 * 60) // Max resource timeout of an hour
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: self.sourceURL)
        task!.resume()
    }
    
    public override func cancel() {
        DDLogInfo("Cancelling download of \(self.sourceURL)")
        super.cancel()
        task?.cancel()
    }
    
    public override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        DDLogVerbose("Download operation for \(self.sourceURL) finished: \(self.destinationFileURL)")
        
        // Ensure progress is 100%
        if progress.totalUnitCount < 0 {
            progress.completedUnitCount = 1
            progress.totalUnitCount = 1
        } else {
            progress.completedUnitCount = progress.totalUnitCount
        }
    }
    
    // MARK: URLSessionDownloadDelegate
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DDLogInfo("Download of \(self.sourceURL) (\(self.formattedFileSize(of: location)) to \(location) complete")
        
        if let downloadError = downloadTask.error {
            DDLogDebug("Download task has error: \(downloadError)")
            finishWithError(downloadError)
            return
        }
        
        if let response = downloadTask.response as? HTTPURLResponse {
            let statusCode = response.statusCode
            DDLogDebug("Got HTTP status code \(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))")
            guard statusCode / 100 == 2 else {
                let httpError = DownloadFileOperationError.invalidHTTPResponse(url: response.url!, code: statusCode, message: HTTPURLResponse.localizedString(forStatusCode: statusCode))
                finishWithError(httpError)
                return
            }
        }
        
        let fm = FileManager.default
        do {
            // If we already have a file at this location, just delete it.
            try fm.removeItem(at: destinationFileURL)
        } catch CocoaError.fileNoSuchFileError {
            // Ignore errors if the file didn't exist
        } catch {
            DDLogWarn("Failed to remove destination file \(self.destinationFileURL): \(error)")
        }
        
        do {
            // Ensure the parent directory exists
            let parentDirectory = destinationFileURL.deletingLastPathComponent()
            try fm.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
            
            DDLogVerbose("Moving temp file \(location) to \(self.destinationFileURL)")
            try fm.moveItem(at: location, to: destinationFileURL)
            finish()
        } catch let error {
            finishWithError(error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DDLogWarn("Download of \(self.sourceURL) failed: \(error)")
        finishWithError(error)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        DDLogVerbose("Task resuming (\(fileOffset)/\(expectedTotalBytes))")
        if expectedTotalBytes != NSURLSessionTransferSizeUnknown {
            progress.localizedAdditionalDescription = nil
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset
        } else {
            progress.localizedAdditionalDescription = "Downloading..."
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DDLogVerbose("Download progress (\(totalBytesWritten)/\(totalBytesExpectedToWrite))")
        if totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown {
            progress.localizedAdditionalDescription = nil
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
        } else {
            progress.localizedAdditionalDescription = "Downloading..."
        }
    }
    
    private func formattedFileSize(of location: URL) -> String {
        do {
            let resourceValues = try location.resourceValues(forKeys: [.fileSizeKey])
            if let fileSizeBytes = resourceValues.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSizeBytes), countStyle: .file)
            }
        } catch {
            DDLogDebug("Failed to get file size due to error: \(error)")
        }
        
        return "unknown size"
    }
    
}
