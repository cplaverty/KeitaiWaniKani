//
//  GetListItemResourceOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import OperationKit

/// A composite `Operation` to both download and parse resource data.
public class GetListItemResourceOperation<Coder: protocol<ResourceHandler, JSONDecoder, ListItemDatabaseCoder>>: GroupOperation, NSProgressReporting {
    
    // MARK: - Properties
    
    public let progress: NSProgress = {
        let progress = NSProgress(totalUnitCount: -1)
        return progress
    }()
    
    public private(set) var downloadOperations: [DownloadResourceOperation]?
    public private(set) var parseOperation: ParseListItemOperation<Coder>?
    public var fetchRequired: Bool {
        guard let downloadOperations = downloadOperations else { return false }
        return downloadOperations.reduce(false) { $0 || !$1.cancelled }
    }
    
    private let coder: Coder
    private let batchesForCoder: Coder -> [DownloadBatches]
    private let resolver: ResourceResolver
    private let databaseQueue: FMDatabaseQueue
    private let networkObserver: OperationObserver?
    private lazy var rootCacheDirectory: NSURL = {
        let tempDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempDirectory.URLByAppendingPathComponent("\(self.resource)/\(NSUUID().UUIDString)/")
        }()
    
    private let resource: Resource
    
    // MARK: - Initialisers
    
    public init(coder: Coder, resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver?, batchesForCoder: Coder -> [DownloadBatches]) {
        self.resource = coder.resource
        self.batchesForCoder = batchesForCoder
        self.coder = coder
        self.resolver = resolver
        self.databaseQueue = databaseQueue
        self.networkObserver = networkObserver
        
        super.init(operations: [])
        progress.localizedDescription = "Fetching \(resource)"
        progress.localizedAdditionalDescription = "Waiting..."
        progress.cancellationHandler = { self.cancel() }
        addObserver(BlockObserver { _ in
            guard self.downloadOperations != nil else { return }
            self.progress.localizedAdditionalDescription = "Finishing..."
            
            do {
                for cacheFile in try NSFileManager.defaultManager().contentsOfDirectoryAtURL(self.rootCacheDirectory, includingPropertiesForKeys: nil, options: []) {
                    DDLogDebug("Cleaning up cache file \(cacheFile)")
                    try NSFileManager.defaultManager().removeItemAtURL(cacheFile)
                }
                DDLogDebug("Removing cache directory \(self.rootCacheDirectory)")
                try NSFileManager.defaultManager().removeItemAtURL(self.rootCacheDirectory)
            } catch NSCocoaError.FileNoSuchFileError {
                DDLogDebug("Ignoring failure to delete cache file in directory which didn't exist: \(self.rootCacheDirectory)")
            } catch {
                DDLogWarn("Failed to clean up temporary file in \(self.rootCacheDirectory): \(error)")
            }
            })
        
        name = "Get \(resource)"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        let downloadBatches = batchesForCoder(coder)
        guard downloadBatches.count > 0 else {
            super.execute()
            return
        }
        
        progress.totalUnitCount = downloadBatches.count + 1
        
        progress.becomeCurrentWithPendingUnitCount(1)
        let parseOperation = ParseListItemOperation(coder: coder, inputDirectory: rootCacheDirectory, databaseQueue: databaseQueue)
        parseOperation.addProgressListenerForDestinationProgress(progress, localizedDescription: "Parsing \(resource)")
        parseOperation.addCondition(NoCancelledDependencies())
        progress.resignCurrent()
        
        self.parseOperation = parseOperation

        var downloadOperations = [DownloadResourceOperation]()
        for batch in downloadBatches {
            let cacheFile = rootCacheDirectory.URLByAppendingPathComponent(batch.description == nil ? "download.json" : "\(batch.description).json")
            progress.becomeCurrentWithPendingUnitCount(1)
            let downloadOperation = DownloadResourceOperation(resolver: resolver, resource: resource, argument: batch.argument, destinationFileURL: cacheFile, networkObserver: networkObserver)
            var progressDescription = "Downloading \(resource)"
            if let batchDescription = batch.description {
                progressDescription += " \(batchDescription)"
            }
            downloadOperation.addProgressListenerForDestinationProgress(progress, localizedDescription: progressDescription)
            progress.resignCurrent()
            
            // These operations must be executed in order
            parseOperation.addDependency(downloadOperation)
            if let lastDownloadOperation = downloadOperations.last {
                downloadOperation.addDependency(lastDownloadOperation)
                downloadOperation.addCondition(NoCancelledDependencies())
            }
            
            addOperation(downloadOperation)
            downloadOperations.append(downloadOperation)
        }
        
        if !downloadOperations.isEmpty {
            self.downloadOperations = downloadOperations
        }

        addOperation(parseOperation)
        
        // This must be done last as it starts the internal queue
        super.execute()
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty {
            DDLogDebug("\(operation.self.dynamicType) finished with no errors")
        } else {
            DDLogWarn("\(operation.self.dynamicType) finished with \(errors.count) error(s): \(errors)")
        }
    }
    
    public override func finished(errors: [ErrorType]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
}
