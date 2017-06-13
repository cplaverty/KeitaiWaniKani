//
//  ParseListItemOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import CocoaLumberjack
import FMDB
import SwiftyJSON
import OperationKit

public final class ParseListItemOperation<Coder: JSONDecoder & ListItemDatabaseCoder>: OperationKit.Operation, WaniKaniAPIResourceParser, ProgressReporting {
    
    // MARK: - Properties
    
    public let inputDirectory: URL
    public let databaseQueue: FMDatabaseQueue
    public let coder: Coder
    public let progress: Progress = Progress(totalUnitCount: -1)
    public private(set) var parsed: [Coder.ModelObject]?
    
    // MARK: - Initialization
    
    init(coder: Coder, inputDirectory: URL, databaseQueue: FMDatabaseQueue) {
        self.coder = coder
        self.inputDirectory = inputDirectory
        self.databaseQueue = databaseQueue
        
        super.init()
        progress.cancellationHandler = { self.cancel() }
        
        name = "Parse Resource \(Coder.ModelObject.self)"
    }
    
    // MARK: - Operation
    
    public override func execute() {
        progress.localizedAdditionalDescription = "Parsing..."
        
        do {
            let jsonDocuments = try parseJSONInDirectory(url: inputDirectory)
            
            if !jsonDocuments.isEmpty {
                try parse(jsonDocuments)
            }
            
            finish()
        } catch {
            DDLogError("Error occurred in \(type(of: self)): \(error)")
            finish(withError: error)
        }
    }
    
    public override func finished(_ errors: [Error]) {
        super.finished(errors)
        
        // Ensure progress is 100%
        progress.completedUnitCount = progress.totalUnitCount
    }
    
    // MARK: - Parse
    
    private func parse(_ jsonDocuments: [JSON]) throws {
        // The total unit count represents parsing and saving the user info, plus the "requested information" payload
        progress.completedUnitCount = 0
        progress.totalUnitCount = Int64(jsonDocuments.count) * 2 + 2
        
        // Ensure progress is 100%
        defer { progress.completedUnitCount = progress.totalUnitCount }
        
        var maybeError: Error? = nil
        var userInformation: UserInformation? = nil
        var parsed: [Coder.ModelObject]
        parsed = []
        for json in jsonDocuments {
            // WORKAROUND: Vocabulary puts the array under "general" for some reason
            let jsonArray: [JSON]
            if let general = json[WaniKaniAPIResourceKeys.requestedInformation]["general"].array {
                jsonArray = general
            } else {
                jsonArray = json[WaniKaniAPIResourceKeys.requestedInformation].arrayValue
            }
            
            if userInformation == nil {
                userInformation = UserInformation.coder.load(from: json[WaniKaniAPIResourceKeys.userInformation])
            }
            progress.completedUnitCount += 1
            
            parsed += jsonArray.flatMap { return coder.load(from: $0) }
            progress.completedUnitCount += 1
        }
        
        DDLogInfo("Parsed \(parsed.count) \(Coder.ModelObject.self) item(s).  Adding to database...")
        progress.localizedAdditionalDescription = "Saving..."
        
        databaseQueue.inTransaction { (db, rollback) in
            do {
                if let item = userInformation {
                    DDLogDebug("Saving user information")
                    try UserInformation.coder.save(item, to: db)
                }
                self.progress.completedUnitCount += 1
                
                DDLogDebug("Saving data")
                try self.coder.save(parsed, to: db)
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
        DDLogInfo("\(Coder.ModelObject.self) database insert complete")
    }
}
