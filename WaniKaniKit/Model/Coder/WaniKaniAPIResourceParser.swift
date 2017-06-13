//
//  WaniKaniAPIResourceParser.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import Foundation
import SwiftyJSON
import CocoaLumberjack

public enum WaniKaniAPIError: Error {
    case userNotFound, invalidArguments
    case unknownError(code: String, message: String?)
}

struct WaniKaniAPIResourceKeys {
    static let userInformation = "user_information"
    static let requestedInformation = "requested_information"
    static let error = "error"
}

protocol WaniKaniAPIResourceParser {
    func parseJSON(url: URL) throws -> JSON
    func parseJSONInDirectory(url: URL) throws -> [JSON]
}

extension WaniKaniAPIResourceParser {
    
    func parseJSONInDirectory(url: URL) throws -> [JSON] {
        var jsonDocuments = [JSON]()
        for inputFile in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: []) {
            let json = try parseJSON(url: inputFile)
            jsonDocuments.append(json)
        }
        
        return jsonDocuments
    }
    
    func parseJSON(url: URL) throws -> JSON {
        let stream = InputStream(url: url)!
        stream.open()
        defer { stream.close() }
        
        if let streamError = stream.streamError, stream.streamStatus == .error {
            throw streamError
        }
        
        let json = JSON(try JSONSerialization.jsonObject(with: stream, options: []))
        try throwForError(json)
        return json
    }
    
    func throwForError(_ json: JSON) throws {
        if let code = json[WaniKaniAPIResourceKeys.error]["code"].string {
            let message = json[WaniKaniAPIResourceKeys.error]["message"].string
            DDLogWarn("Received API error \(code): \(message ?? "<no message>")")
            
            switch code {
            case "user_not_found":
                throw WaniKaniAPIError.userNotFound
            case "invalid_arguments":
                throw WaniKaniAPIError.invalidArguments
            default:
                throw WaniKaniAPIError.unknownError(code: code, message: message)
            }
        }
    }
    
}
