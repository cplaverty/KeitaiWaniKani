//
//  DownloadResourceOperation+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OperationKit

extension DownloadResourceOperation {
    
    convenience init(resolver: ResourceResolver, resource: Resource, argument: String? = nil, destinationFileURL: NSURL, networkObserver: OperationObserver? = nil) {
        let sourceURL = resolver.URLForResource(resource, withArgument: argument)
        
        self.init(sourceURL: sourceURL, destinationFileURL: destinationFileURL, networkObserver: networkObserver)
        
        name = "Download \(resource)"
    }

}