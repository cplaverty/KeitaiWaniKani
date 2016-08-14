//
//  UserInformation.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public struct UserInformation: Equatable {
    public let username: String
    public let gravatar: String
    public let level: Int
    public let title: String
    public let about: String?
    public let website: String?
    public let twitter: String?
    public let topicsCount: Int
    public let postsCount: Int
    public let creationDate: Date
    public let vacationDate: Date?
    public let lastUpdateTimestamp: Date
    
    public init(username: String, gravatar: String, level: Int, title: String, about: String? = nil, website: String? = nil, twitter: String? = nil, topicsCount: Int, postsCount: Int, creationDate: Date, vacationDate: Date? = nil, lastUpdateTimestamp: Date? = nil) {
        self.username = username
        self.gravatar = gravatar
        self.level = level
        self.title = title
        self.about = about
        self.website = website
        self.twitter = twitter
        self.topicsCount = topicsCount
        self.postsCount = postsCount
        self.creationDate = creationDate
        self.vacationDate = vacationDate
        self.lastUpdateTimestamp = lastUpdateTimestamp ?? Date()
    }
}

public func ==(lhs: UserInformation, rhs: UserInformation) -> Bool {
    return lhs.username == rhs.username &&
        lhs.gravatar == rhs.gravatar &&
        lhs.level == rhs.level &&
        lhs.title == rhs.title &&
        lhs.about == rhs.about &&
        lhs.website == rhs.website &&
        lhs.twitter == rhs.twitter &&
        lhs.topicsCount == rhs.topicsCount &&
        lhs.postsCount == rhs.postsCount &&
        lhs.creationDate == rhs.creationDate &&
        lhs.vacationDate == rhs.vacationDate
}
