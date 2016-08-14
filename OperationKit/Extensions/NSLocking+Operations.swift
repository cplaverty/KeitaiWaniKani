/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension to NSLocking to simplify executing critical code.
*/

import Foundation

extension NSLocking {
    func withCriticalScope<T>(_ block: @noescape (Void) -> T) -> T {
        lock()
        defer { unlock() }
        
        return block()
    }
}
