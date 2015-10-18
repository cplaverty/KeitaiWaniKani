//
//  GetSingleItemResourceOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import Alamofire
import CocoaLumberjack
import FMDB
import SwiftyJSON
import OperationKit

/// A composite `Operation` to both download and parse resource data.
public class GetSingleItemResourceOperation<Coder: protocol<ResourceHandler, JSONDecoder, SingleItemDatabaseCoder>>: Operation, WaniKaniAPIResourceParser, NSProgressReporting {
    
    // MARK: - Properties
    
    public let progress: NSProgress
    
    public private(set) var parsed: Coder.ModelObject?
    
    public var fetchRequired: Bool {
        return !cancelled
    }
    
    private let coder: Coder
    private let databaseQueue: FMDatabaseQueue
    private let sourceURL: NSURL
    private var request: Request?
    
    // MARK: - Initialisers
    
    public init(coder: Coder, resolver: ResourceResolver, databaseQueue: FMDatabaseQueue, networkObserver: OperationObserver?) {
        self.coder = coder
        self.databaseQueue = databaseQueue
        
        let resource = coder.resource
        self.sourceURL = resolver.URLForResource(resource, withArgument: nil)
        
        progress = NSProgress(totalUnitCount: 3)
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
        DDLogInfo("Starting download of \(self.sourceURL)")
        request = Alamofire.request(.GET, self.sourceURL)
            .validate()
            .responseJSON { [progress] response in
                progress.completedUnitCount = 1
                defer { progress.completedUnitCount = progress.totalUnitCount }
                DDLogInfo("Download of \(self.sourceURL) complete")
                switch response.result {
                case .Success(let value):
                    do {
                        let json = JSON(value)
                        try self.throwForError(json)
                        try self.parse(json)
                        self.finish()
                    } catch {
                        self.finishWithError(error)
                    }
                case .Failure(let error):
                    self.finishWithError(error)
                }
        }
    }
    
    public override func cancel() {
        DDLogInfo("Cancelling download of \(self.sourceURL)")
        super.cancel()
        request?.cancel()
    }
    
    // MARK: - Parse
    
    private func parse(json: JSON) throws {
        var maybeError: ErrorType? = nil
        var userInformation: UserInformation? = nil
        var parsed: Coder.ModelObject?
        
        userInformation = UserInformation.coder.loadFromJSON(json[WaniKaniAPIResourceKeys.userInformation])
        
        parsed = coder.loadFromJSON(json[WaniKaniAPIResourceKeys.requestedInformation])
        
        ++progress.completedUnitCount
        
        DDLogInfo("Parsed \(Coder.ModelObject.self).  Adding to database...")
        progress.localizedAdditionalDescription = "Saving..."
        
        databaseQueue.inTransaction { (db, rollback) -> Void in
            do {
                if let item = userInformation {
                    DDLogDebug("Saving user information")
                    try UserInformation.coder.save(item, toDatabase: db)
                }
                
                if let parsed = parsed {
                    DDLogDebug("Saving \(Coder.ModelObject.self) data")
                    try self.coder.save(parsed, toDatabase: db)
                } else {
                    DDLogWarn("Not saving \(Coder.ModelObject.self) as no valid items were parsed")
                }
                
                ++self.progress.completedUnitCount
            } catch {
                DDLogWarn("Rolling back due to database error: \(error)")
                rollback.memory = true
                maybeError = error
            }
        }
        progress.localizedAdditionalDescription = "Done!"
        
        if let error = maybeError {
            throw error
        }
        
        self.parsed = parsed
        DDLogInfo("\(Coder.ModelObject.self) database insert complete")
    }
    
}
