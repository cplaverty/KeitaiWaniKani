/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows an example of implementing the OperationCondition protocol.
*/

import Foundation
import SystemConfiguration
import CocoaLumberjack

public enum ReachabilityConditionError: ErrorType {
    case FailedToReachHost(host: String)
}

/**
    This is a condition that performs a very high-level reachability check.
    It does *not* perform a long-running reachability check, nor does it respond to changes in reachability.
    Reachability is evaluated once when the operation to which this is attached is asked about its readiness.
*/
public struct ReachabilityCondition: OperationCondition {
    public static let isMutuallyExclusive = false
    
    public let URL: NSURL
    
    
    public init(URL: NSURL) {
        self.URL = URL
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        ReachabilityController.requestReachability(URL) { reachable in
            if reachable {
                DDLogVerbose("Reachability check satisfied")
                completion(.Satisfied)
            }
            else {
                DDLogVerbose("Reachability check failed!")
                let error = ReachabilityConditionError.FailedToReachHost(host: self.URL.host ?? "<unknown host>")
                
                completion(.Failed(error))
            }
        }
    }
    
}

/// A private singleton that maintains a basic cache of `SCNetworkReachability` objects.
private class ReachabilityController {
    static var reachabilityRefs = [String: SCNetworkReachability]()

    static let reachabilityQueue = dispatch_queue_create("Operations.Reachability", DISPATCH_QUEUE_SERIAL)
    
    static func requestReachability(url: NSURL, completionHandler: (Bool) -> Void) {
        if url.fileURL {
            let fileExists = NSFileManager.defaultManager().fileExistsAtPath(url.path!)
            completionHandler(fileExists)
        } else if let host = url.host {
            dispatch_async(reachabilityQueue) {
                var ref = self.reachabilityRefs[host]

                if ref == nil {
                    let hostString = host as NSString
                    ref = SCNetworkReachabilityCreateWithName(nil, hostString.UTF8String)
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
                        reachable = flags.contains(.Reachable)
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
