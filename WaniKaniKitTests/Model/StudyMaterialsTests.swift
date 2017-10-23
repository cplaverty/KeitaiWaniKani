//
//  StudyMaterialsTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class StudyMaterialsTests: XCTestCase {
    
    func testDecode() {
        let data = """
            {"id":204431,"object":"study_material","url":"https://www.wanikani.com/api/v2/study_materials/204431","data_updated_at":"2017-05-13T14:36:04.000000Z","data":{"created_at":"2015-07-07T16:41:02.000000Z","subject_id":25,"subject_type":"radical","meaning_note":"meaning note","reading_note":"reading note","meaning_synonyms":["industry"]}}
            """.data(using: .utf8)!
        
        let decoder = WaniKaniResourceDecoder()
        
        do {
            let resource = try decoder.decode(ResourceCollectionItem.self, from: data)
            
            let expected = ResourceCollectionItem(id: 204431,
                                                  type: .studyMaterial,
                                                  url: URL(string: "https://www.wanikani.com/api/v2/study_materials/204431")!,
                                                  dataUpdatedAt: makeUTCDate(year: 2017, month: 5, day: 13, hour: 14, minute: 36, second: 4),
                                                  data: StudyMaterials(createdAt: makeUTCDate(year: 2015, month: 7, day: 7, hour: 16, minute: 41, second: 2),
                                                                       subjectID: 25,
                                                                       subjectType: .radical,
                                                                       meaningNote: "meaning note",
                                                                       readingNote: "reading note",
                                                                       meaningSynonyms: ["industry"]))
            
            XCTAssertEqual(resource, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
