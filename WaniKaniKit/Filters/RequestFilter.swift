//
//  RequestFilter.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

protocol RequestFilter {
    func asQueryItems() -> [URLQueryItem]?
}
