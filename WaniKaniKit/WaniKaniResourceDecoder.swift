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
        if #available(iOS 10.0, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            decoder.dateDecodingStrategy = .custom(decodeISO8601Date)
        }
        return decoder
    }
    
    private func decodeISO8601Date(decoder: Decoder) throws -> Date {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        
        let parseISODate: (String) -> (UnsafePointer<CChar>) -> Date? = { fmt in { p in
            var tmc: tm = tm(tm_sec: 0, tm_min: 0, tm_hour: 0, tm_mday: 0, tm_mon: 0, tm_year: 0, tm_wday: 0, tm_yday: 0, tm_isdst: 0, tm_gmtoff: 0, tm_zone: nil)
            guard strptime(p, fmt, &tmc) != nil else {
                return nil
            }
            
            return Date(timeIntervalSince1970: TimeInterval(mktime(&tmc)))
            }}
        
        let parsed = stringValue.hasSuffix("Z")
            ? stringValue.dropLast(1).withCString(parseISODate("%FT%T"))
            : stringValue.withCString(parseISODate("%FT%T%z"))
        
        guard let date = parsed else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to parse date \(stringValue)"))
        }
        
        return date
    }
}
