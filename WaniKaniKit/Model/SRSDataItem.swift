//
//  SRSDataItem.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public protocol SRSDataItem {
    var level: Int { get }
    var userSpecificSRSData: UserSpecificSRSData? { get }
}
