//
//  GetSingleItemResourceOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON
import OperationKit

/// A composite `Operation` to both download and parse resource data.
public class GetSingleItemResourceOperation<Coder: ResourceHandler & JSONDecoder & SingleItemDatabaseCoder>: OperationKit.Operation, WaniKaniAPIResourceParser, ProgressReporting {
    
    // MARK: - Properties
    
    public let progress: Progress
    
    public private(set) var parsed: Coder.ModelObject?
    
    public var fetchRequired: Bool {
        return !isCancelled
    }
    
    private let coder: Coder
    private let databaseQueue: FMDatabaseQueue
    private let sourceURL: URL
    private var task: URLSessionTask?
    private let parseOnly: Bool
    
    // MARK: - Initialisers
    
    public init(coder: Coder, resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver?, parseOnly: Bool = false) {
        self.coder = coder
        self.databaseQueue = databaseQueue
        self.parseOnly = parseOnly
        
        let resource = coder.resource
        self.sourceURL = resolver.resolveURL(resource: resource, withArgument: nil)
        
        progress = Progress(totalUnitCount: 3)
        progress.localizedDescription = "Fetching \(resource)"
        progress.localizedAdditionalDescription = "Waiting..."
        
        super.init()
        progress.cancellationHandler = { self.cancel() }
        
        if let networkObserver = networkObserver {
            addObserver(networkObserver)
        }
        
        name = "Get \(resource)"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        assert(task == nil, "Operation executed twice?")
        
        DDLogInfo("Starting download of \(self.sourceURL)")
        progress.localizedAdditionalDescription = "Connecting..."
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = TimeInterval(10 * 60) // Max resource timeout of 10 minutes
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        
        task = session.dataTask(with: sourceURL) { (data, response, error) in
            self.progress.completedUnitCount = 1
            defer { self.progress.completedUnitCount = self.progress.totalUnitCount }
            DDLogDebug("Download of \(self.sourceURL) complete")
            if let error = error {
                self.finish(withError: error)
                return
            }
            
            do {
                let json = JSON(data: data!)
                try self.throwForError(json)
                try self.parse(json)
                self.finish()
            } catch {
                self.finish(withError: error)
            }
        }
        task!.resume()
    }
    
    public override func cancel() {
        DDLogDebug("Cancelling download of \(self.sourceURL)")
        super.cancel()
        task?.cancel()
    }
    
    public override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        DDLogVerbose("Data operation for \(self.sourceURL) finished")
        
        // Ensure progress is 100%
        if progress.totalUnitCount < 0 {
            progress.completedUnitCount = 1
            progress.totalUnitCount = 1
        } else {
            progress.completedUnitCount = progress.totalUnitCount
        }
    }
    
    // MARK: - Parse
    
    private func parse(_ json: JSON) throws {
        var maybeError: Error? = nil
        var userInformation: UserInformation? = nil
        var parsed: Coder.ModelObject?
        
        userInformation = UserInformation.coder.load(from: json[WaniKaniAPIResourceKeys.userInformation])
        
        parsed = coder.load(from: json[WaniKaniAPIResourceKeys.requestedInformation])
        
        progress.completedUnitCount += 1
        
        if parseOnly {
            DDLogInfo("Parsed \(Coder.ModelObject.self).  Skipping save to database because parseOnly = true.")
            self.progress.completedUnitCount += 1
            return
        }
        
        DDLogInfo("Parsed \(Coder.ModelObject.self).  Adding to database...")
        progress.localizedAdditionalDescription = "Saving..."
        
        databaseQueue.inTransaction { (db, rollback) in
            do {
                if let item = userInformation {
                    DDLogDebug("Saving user information")
                    try UserInformation.coder.save(item, to: db)
                }
                
                if let parsed = parsed {
                    DDLogDebug("Saving \(Coder.ModelObject.self) data")
                    try self.coder.save(parsed, to: db)
                } else {
                    DDLogWarn("Not saving \(Coder.ModelObject.self) as no valid items were parsed")
                }
                
                self.progress.completedUnitCount += 1
                
                WaniKaniDarwinNotificationCenter.postModelUpdateMessage("\(Coder.ModelObject.self)")
            } catch {
                DDLogWarn("Rolling back due to database error: \(error)")
                rollback.pointee = true
                maybeError = error
            }
        }
        progress.localizedAdditionalDescription = "Done!"
        
        if let error = maybeError {
            throw error
        }
        
        self.parsed = parsed
        DDLogDebug("\(Coder.ModelObject.self) database insert complete")
    }
    
}
