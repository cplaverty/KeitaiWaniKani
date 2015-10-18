//
//  WaniKaniAPIResourceParser.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import SwiftyJSON
import CocoaLumberjack

public enum WaniKaniAPIError: ErrorType {
    case UserNotFound, InvalidArguments
    case UnknownError(code: String, message: String?)
}

struct WaniKaniAPIResourceKeys {
    static let userInformation = "user_information"
    static let requestedInformation = "requested_information"
    static let error = "error"
}

protocol WaniKaniAPIResourceParser {
    func parseJSONAtURL(URL: NSURL) throws -> JSON
    func parseJSONInDirectoryAtURL(inputDirectory: NSURL) throws -> [JSON]
}

extension WaniKaniAPIResourceParser {
    
    func parseJSONInDirectoryAtURL(inputDirectory: NSURL) throws -> [JSON] {
        var jsonDocuments = [JSON]()
        for inputFile in try NSFileManager.defaultManager().contentsOfDirectoryAtURL(inputDirectory, includingPropertiesForKeys: nil, options: []) {
            let json = try parseJSONAtURL(inputFile)
            jsonDocuments.append(json)
        }
        
        return jsonDocuments
    }
    
    func parseJSONAtURL(URL: NSURL) throws -> JSON {
        let stream = NSInputStream(URL: URL)!
        stream.open()
        defer { stream.close() }
        
        if let streamError = stream.streamError where stream.streamStatus == .Error {
            throw streamError
        }
        
        let json = JSON(try NSJSONSerialization.JSONObjectWithStream(stream, options: []))
        try throwForError(json)
        return json
    }
    
    func throwForError(json: JSON) throws {
        if let code = json[WaniKaniAPIResourceKeys.error]["code"].string {
            let message = json[WaniKaniAPIResourceKeys.error]["message"].string
            DDLogInfo("Received API error \(code): \(message)")
            
            switch code {
            case "user_not_found":
                throw WaniKaniAPIError.UserNotFound
            case "invalid_arguments":
                throw WaniKaniAPIError.InvalidArguments
            default:
                throw WaniKaniAPIError.UnknownError(code: code, message: message)
            }
        }
    }
    
}