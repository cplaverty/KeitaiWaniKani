//
//  GetRadicalImageOperation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OperationKit

public class GetRadicalImageOperation: GroupOperation {
    private static let runTimeoutInSeconds = 20.0
    
    // MARK: - Properties
    
    public let sourceURL: NSURL
    public let destinationFileURL: NSURL
    public let downloadOperation: DownloadResourceOperation
    
    public static var parentDirectory: NSURL = {
        let fm = NSFileManager.defaultManager()
        let cachesDir = try! fm.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let parentDirectory = cachesDir.URLByAppendingPathComponent("RadicalImages", isDirectory: true)
        if !fm.fileExistsAtPath(parentDirectory.path!) {
            _ = try? fm.createDirectoryAtURL(parentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return parentDirectory
        }()
    
    // MARK: - Initialisers
    
    public init(sourceURL: NSURL, networkObserver: OperationObserver? = nil) {
        self.sourceURL = sourceURL
        self.destinationFileURL = self.dynamicType.parentDirectory.URLByAppendingPathComponent(sourceURL.lastPathComponent!)
        
        downloadOperation = DownloadResourceOperation(sourceURL: sourceURL, destinationFileURL: destinationFileURL, networkObserver: networkObserver)
        downloadOperation.addCondition(FileMissingCondition(fileURL: destinationFileURL))
        
        super.init(operations: [downloadOperation])
        addObserver(TimeoutObserver(timeout: self.dynamicType.runTimeoutInSeconds))
        
        name = "Get Radical Image"
    }
}
