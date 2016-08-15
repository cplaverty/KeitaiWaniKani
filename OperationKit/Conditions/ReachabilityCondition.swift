/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation
import SystemConfiguration
import CocoaLumberjack

public enum ReachabilityConditionError: Error {
    case failedToReachHost(host: String)
}

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
public struct ReachabilityCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    public static var isEnabled = true
    
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func dependency(for operation: Operation) -> Foundation.Operation? {
        return nil
    }
    
    public func evaluate(for operation: Operation, completion: (OperationConditionResult) -> Void) {
        guard self.dynamicType.isEnabled else {
            DDLogVerbose("Reachability check disabled - faking satisfied check")
            completion(.satisfied)
            return
        }
        
        ReachabilityController.requestReachability(for: url) { reachable in
            if reachable {
                DDLogVerbose("Reachability check satisfied")
                completion(.satisfied)
            }
            else {
                DDLogVerbose("Reachability check failed!")
                let error = ReachabilityConditionError.failedToReachHost(host: self.url.host ?? "<unknown host>")
                
                completion(.failed(error))
            }
        }
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()

    static let reachabilityQueue = DispatchQueue(label: "Operations.Reachability")
    
    static func requestReachability(for url: URL, completionHandler: (Bool) -> Void) {
        if url.isFileURL {
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            completionHandler(fileExists)
        } else if let host = url.host {
            reachabilityQueue.async {
                var ref = self.reachabilityRefs[host]

                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.utf8String!)
                }
                
                if let ref = ref {
                    self.reachabilityRefs[host] = ref
                    
                    var reachable = false
                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) {
                        /*
                            Note that this is a very basic "is reachable" check. 
                            Your app may choose to allow for other considerations,
                            such as whether or not the connection would require 
                            VPN, a cellular connection, etc.
                        */
                        reachable = flags.contains(.reachable)
                    }
                    completionHandler(reachable)
                }
                else {
                    completionHandler(false)
                }
            }
        }
        else {
            completionHandler(false)
        }
    }
}
