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
    
    public let sourceURL: URL
    public let destinationFileURL: URL
    public let downloadOperation: DownloadFileOperation
    
    public static var parentDirectory: URL = {
        let fm = FileManager.default
        let cachesDir = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let parentDirectory = cachesDir.appendingPathComponent("RadicalImages", isDirectory: true)
        if !fm.fileExists(atPath: parentDirectory.path) {
            _ = try? fm.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return parentDirectory
    }()
    
    // MARK: - Initialisers
    
    public init(sourceURL: URL, networkObserver: OperationObserver? = nil) {
        self.sourceURL = sourceURL
        self.destinationFileURL = type(of: self).parentDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        
        downloadOperation = DownloadFileOperation(sourceURL: sourceURL, destinationFileURL: destinationFileURL, networkObserver: networkObserver)
        downloadOperation.addCondition(FileMissingCondition(url: destinationFileURL))
        
        super.init(operations: [downloadOperation])
        addObserver(TimeoutObserver(timeout: type(of: self).runTimeoutInSeconds))
        
        name = "Get Radical Image"
    }
}
