//
//  ResourceResolver.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation

public protocol ResourceResolver {
    var apiKey: String { get }
    /// Given a resource and argument, find the URL to load it.
    func resolveURL(resource: Resource, withArgument argument: String?) -> URL
}
