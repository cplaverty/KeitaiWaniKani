//
//  WaniKaniResourceDecoder.swift
//  WaniKaniKit
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

public protocol ResourceDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

public class WaniKaniResourceDecoder: ResourceDecoder {
    public init() {
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let jsonDecoder = makeJSONDecoder()
        return try jsonDecoder.decode(type, from: data)
    }
    
    private func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(decodeISO8601Date)
        return decoder
    }
    
    private func decodeISO8601Date(decoder: Decoder) throws -> Date {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        
        guard let date = DateFormatter.iso8601.date(from: stringValue) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to parse date \(stringValue)"))
        }
        
        return date
    }
}
