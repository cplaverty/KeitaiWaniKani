//
//  DownloadFileOperation+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import OperationKit

extension DownloadFileOperation {
    
    convenience init(resolver: ResourceResolver, resource: Resource, argument: String? = nil, destinationFileURL: URL, networkObserver: OperationObserver? = nil) {
        let sourceURL = resolver.resolveURL(resource: resource, withArgument: argument)
        
        self.init(sourceURL: sourceURL, destinationFileURL: destinationFileURL, networkObserver: networkObserver)
        
        name = "Download \(resource)"
    }
    
}
