//
//  WaniKaniAPIError.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum WaniKaniAPIError: Error {
    case noContent
    case invalidAPIKey
    case unknownError(httpStatusCode: Int, message: String)
    case unhandledStatusCode(httpStatusCode: Int, data: Data?)
}
