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
    public var date: NSDate? {
        get {
            if let timeInterval = self.double where timeInterval > 0 {
                return NSDate(timeIntervalSince1970: timeInterval)
            }
            return nil
        }
        set {
            self.double = newValue?.timeIntervalSince1970
        }
    }
    
    //Non-optional date
    public var dateValue: NSDate {
        get {
            return NSDate(timeIntervalSince1970: self.doubleValue)
        }
        set {
            self.doubleValue = newValue.timeIntervalSince1970
        }
    }
    
}
