//
//  RadicalTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class RadicalTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":1,"object":"radical","url":"https://api.wanikani.com/v2/subjects/1","data_updated_at":"2018-05-21T21:51:35.000000Z","data":{"created_at":"2012-02-27T18:08:16.000000Z","level":1,"slug":"ground","hidden_at":null,"document_url":"https://www.wanikani.com/radicals/ground","characters":"一","character_images":[{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-original.png?1520987606","metadata":{"color":"#000000","dimensions":"1024x1024","style_name":"original"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-1024px.png?1520987606","metadata":{"color":"#000000","dimensions":"1024x1024","style_name":"1024px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-512px.png?1520987606","metadata":{"color":"#000000","dimensions":"512x512","style_name":"512px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-256px.png?1520987606","metadata":{"color":"#000000","dimensions":"256x256","style_name":"256px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-128px.png?1520987606","metadata":{"color":"#000000","dimensions":"128x128","style_name":"128px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-64px.png?1520987606","metadata":{"color":"#000000","dimensions":"64x64","style_name":"64px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-32px.png?1520987606","metadata":{"color":"#000000","dimensions":"32x32","style_name":"32px"},"content_type":"image/png"},{"url":"https://cdn.wanikani.com/images/legacy/576-subject-1-without-css-original.svg?1520987227","metadata":{"inline_styles":false},"content_type":"image/svg+xml"},{"url":"https://cdn.wanikani.com/images/legacy/98-subject-1-with-css-original.svg?1520987072","metadata":{"inline_styles":true},"content_type":"image/svg+xml"}],"meanings":[{"meaning":"Ground","primary":true,"accepted_answer":true}],"amalgamation_subject_ids":[440,449,450,451,488,531,533,568,590,609,633,635,709,710,724,783,808,913,932,965,971,1000,1020,1085,1113,1126,1137,1178,1198,1240,1241,1249,1340,1367,1372,1376,1379,1428,1431,1463,1491,1506,1521,1547,1559,1591,1655,1674,1706,1769,1851,1852,1855,1868,1869,1888,1970,2091,2104,2128,2138,2148,2171,2182,2263,2277,2334,2375,2419,2437]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 1,
                                                  type: .radical,
                                                  url: URL(string: "https://api.wanikani.com/v2/subjects/1")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2018, month: 5, day: 21, hour: 21, minute: 51, second: 35),
                                                  data: Radical(level: 1,
                                                                createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 18, minute: 8, second: 16),
                                                                slug: "ground",
                                                                characters: "一",
                                                                characterImages: [
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "1024x1024", styleName: "original", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-original.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "1024x1024", styleName: "1024px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-1024px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "512x512", styleName: "512px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-512px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "256x256", styleName: "256px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-256px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "128x128", styleName: "128px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-128px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "64x64", styleName: "64px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-64px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/png",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "32x32", styleName: "32px", inlineStyles: nil),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-32px.png?1520987606")!),
                                                                    Radical.CharacterImage(contentType: "image/svg+xml",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: nil, dimensions: nil, styleName: nil, inlineStyles: false),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/576-subject-1-without-css-original.svg?1520987227")!),
                                                                    Radical.CharacterImage(contentType: "image/svg+xml",
                                                                                           metadata: Radical.CharacterImage.Metadata(color: nil, dimensions: nil, styleName: nil, inlineStyles: true),
                                                                                           url: URL(string: "https://cdn.wanikani.com/images/legacy/98-subject-1-with-css-original.svg?1520987072")!),
                                                                    ],
                                                                meanings: [Meaning(meaning: "Ground", isPrimary: true, isAcceptedAnswer: true)],
                                                                amalgamationSubjectIDs: [440,449,450,451,488,531,533,568,590,609,633,635,709,710,724,783,808,913,932,965,971,1000,1020,1085,1113,1126,1137,1178,1198,1240,1241,1249,1340,1367,1372,1376,1379,1428,1431,1463,1491,1506,1521,1547,1559,1591,1655,1674,1706,1769,1851,1852,1855,1868,1869,1888,1970,2091,2104,2128,2138,2148,2171,2182,2263,2277,2334,2375,2419,2437],
                                                                documentURL: URL(string: "https://www.wanikani.com/radicals/ground")!,
                                                                hiddenAt: nil))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
