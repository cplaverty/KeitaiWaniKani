//
//  WaniKaniAPIError.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public enum WaniKaniAPIError: Error, LocalizedError {
    case noContent
    case invalidAPIKey
    case tooManyRequests
    case unknownError(httpStatusCode: Int, message: String)
    case unhandledStatusCode(httpStatusCode: Int, data: Data?)
    
    public var errorDescription: String? {
        switch self {
        case .noContent:
            return "The response from the WaniKani API was empty"
        case .invalidAPIKey:
            return "The API key is invalid"
        case .tooManyRequests:
            return "Too many requests have been made for this account to the WaniKani API.  Please try your request again later."
        case let .unknownError(httpStatusCode: httpStatusCode, message: message):
            return "Received an unexpected response code \(httpStatusCode) from the API.  Message: \(message)"
        case let .unhandledStatusCode(httpStatusCode: httpStatusCode, data: _):
            return "An unknown error has occurred communicating with the WaniKani API (response code \(httpStatusCode) received)"
        }
    }
}
