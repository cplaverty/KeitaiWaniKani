//
//  ParseSingleItemOperation.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON
import OperationKit

public final class ParseSingleItemOperation<Coder: protocol<JSONDecoder, SingleItemDatabaseCoder>>: Operation, WaniKaniAPIResourceParser, NSProgressReporting {
    
    // MARK: - Properties
    
    public let cacheFile: NSURL
    public let databaseQueue: FMDatabaseQueue
    public let coder: Coder
    public let progress: NSProgress = NSProgress(totalUnitCount: -1)
    public private(set) var parsed: Coder.ModelObject?
    
    // MARK: - Initialization
    
    init(coder: Coder, cacheFile: NSURL, databaseQueue: FMDatabaseQueue) {
        self.coder = coder
        self.cacheFile = cacheFile
        self.databaseQueue = databaseQueue
        
        super.init()
        progress.cancellationHandler = { self.cancel() }
        
        name = "Parse Resource \(Coder.ModelObject.self)"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        progress.localizedAdditionalDescription = "Parsing..."
        
        do {
            let jsonDocument = try parseJSONAtURL(cacheFile)
            try parse(jsonDocument)
            
            finish()
        } catch {
            DDLogError("Error occurred in \(self.dynamicType): \(error)")
            finishWithError(error)
        }
    }
    
    public override func finished(errors: [ErrorType]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
    // MARK: - Parse
    
    private func parse(json: JSON) throws {
        // The total unit count represents parsing and saving the user info, plus the "requested information" payload
        progress.completedUnitCount = 0
        progress.totalUnitCount = 4
        
        // Ensure progress is 100%
        defer { progress.completedUnitCount = progress.totalUnitCount }
        
        var maybeError: ErrorType? = nil
        var userInformation: UserInformation? = nil
        var parsed: Coder.ModelObject?
        
        userInformation = UserInformation.coder.loadFromJSON(json[WaniKaniAPIResourceKeys.userInformation])
        ++progress.completedUnitCount
        
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
                ++self.progress.completedUnitCount
                
                if let parsed = parsed {
                    DDLogDebug("Saving data")
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
