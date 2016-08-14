//
//  JSON+WaniKani.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import SwiftyJSON

extension JSON {
    
    //Optional date
    public var date: Date? {
        get {
            if let timeInterval = self.double, timeInterval > 0 {
                return Date(timeIntervalSince1970: timeInterval)
            }
            return nil
        }
        set {
            self.double = newValue?.timeIntervalSince1970
        }
    }
    
    //Non-optional date
    public var dateValue: Date {
        get {
            return Date(timeIntervalSince1970: self.doubleValue)
        }
        set {
            self.doubleValue = newValue.timeIntervalSince1970
        }
    }
    
}
