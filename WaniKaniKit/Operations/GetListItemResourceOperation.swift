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
public class GetListItemResourceOperation<Coder: ResourceHandler & JSONDecoder & ListItemDatabaseCoder>: GroupOperation, ProgressReporting {
    
    // MARK: - Properties
    
    public let progress = Progress(totalUnitCount: 2)
    
    public private(set) var downloadOperations: [DownloadFileOperation]?
    public private(set) var parseOperation: ParseListItemOperation<Coder>?
    public var fetchRequired: Bool {
        guard let downloadOperations = downloadOperations else { return false }
        return downloadOperations.reduce(false) { $0 || !$1.isCancelled }
    }
    
    private let coder: Coder
    private let batchesForCoder: (Coder) -> [DownloadBatches]
    private let resolver: ResourceResolver
    private let databaseQueue: FMDatabaseQueue
    private let networkObserver: OperationObserver?
    private lazy var rootCacheDirectory: URL = {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempDirectory.appendingPathComponent("\(self.resource)/\(UUID().uuidString)/")
    }()
    
    private let resource: Resource
    
    // MARK: - Initialisers
    
    public init(coder: Coder, resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver?, batchesForCoder: @escaping (Coder) -> [DownloadBatches]) {
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
                for cacheFile in try FileManager.default.contentsOfDirectory(at: self.rootCacheDirectory, includingPropertiesForKeys: nil, options: []) {
                    DDLogDebug("Cleaning up cache file \(cacheFile)")
                    try FileManager.default.removeItem(at: cacheFile)
                }
                DDLogDebug("Removing cache directory \(self.rootCacheDirectory)")
                try FileManager.default.removeItem(at: self.rootCacheDirectory)
            } catch CocoaError.fileNoSuchFile {
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
        
        progress.becomeCurrent(withPendingUnitCount: 1)
        let parseOperation = ParseListItemOperation(coder: coder, inputDirectory: rootCacheDirectory, databaseQueue: databaseQueue)
        parseOperation.addCondition(NoCancelledDependencies())
        progress.resignCurrent()
        
        self.parseOperation = parseOperation
        
        var downloadOperations = [DownloadFileOperation]()
        for batch in downloadBatches {
            let cacheFile = rootCacheDirectory.appendingPathComponent(batch.description == nil ? "download.json" : "\(batch.description).json")
            progress.becomeCurrent(withPendingUnitCount: 1)
            let downloadOperation = DownloadFileOperation(resolver: resolver, resource: resource, argument: batch.argument, destinationFileURL: cacheFile, networkObserver: networkObserver)
            var progressDescription = "Downloading \(resource)"
            if let batchDescription = batch.description {
                progressDescription += " \(batchDescription)"
            }
            progress.resignCurrent()
            
            // These operations must be executed in order
            parseOperation.addDependency(downloadOperation)
            if let lastDownloadOperation = downloadOperations.last {
                downloadOperation.addDependency(lastDownloadOperation)
                downloadOperation.addCondition(NoCancelledDependencies())
            }
            
            add(downloadOperation)
            downloadOperations.append(downloadOperation)
        }
        
        if !downloadOperations.isEmpty {
            self.downloadOperations = downloadOperations
        }
        
        add(parseOperation)
        
        // This must be done last as it starts the internal queue
        super.execute()
    }
    
    public override func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [Error]) {
        if errors.isEmpty {
            DDLogDebug("\(type(of: operation.self)) finished with no errors")
        } else {
            DDLogWarn("\(type(of: operation.self)) finished with \(errors.count) error(s): \(errors)")
        }
    }
    
    public override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
}
