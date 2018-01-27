//
//  ResourceRepositoryTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import XCTest
@testable import WaniKaniKit

class ResourceRepositoryTests: XCTestCase {
    
    private var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        let factory = EphemeralDatabaseConnectionFactory()
        databaseManager = DatabaseManager(factory: factory)
        
        if !databaseManager.open() {
            self.continueAfterFailure = false
            XCTFail("Failed to open database queue")
        }
    }
    
    override func tearDown() {
        databaseManager.close()
        databaseManager = nil
        
        super.tearDown()
    }
    
    func testUpdateAssignments() {
        let dataUpdatedAt = makeUTCDate(year: 2017, month: 8, day: 1, hour: 3, minute: 12, second: 39)
        let baseDate = makeUTCDate(year: 2017, month: 2, day: 4, hour: 8, minute: 26, second: 31)
        let expected1 = ResourceCollectionItem(id: 1,
                                               type: .assignment,
                                               url: URL(string: "https://www.wanikani.com/api/v2/assignments/1")!,
                                               dataUpdatedAt: dataUpdatedAt,
                                               data: Assignment(subjectID: 1,
                                                                subjectType: .radical,
                                                                level: 1,
                                                                srsStage: 9,
                                                                srsStageName: "Burned",
                                                                unlockedAt: baseDate,
                                                                startedAt: baseDate.addingTimeInterval(.oneDay),
                                                                passedAt: baseDate.addingTimeInterval(4 * .oneDay),
                                                                burnedAt: baseDate.addingTimeInterval(160 * .oneDay),
                                                                availableAt: baseDate,
                                                                isPassed: true,
                                                                isResurrected: false))
        let expected2 = ResourceCollectionItem(id: 2,
                                               type: .assignment,
                                               url: URL(string: "https://www.wanikani.com/api/v2/assignments/2")!,
                                               dataUpdatedAt: dataUpdatedAt,
                                               data: Assignment(subjectID: 10,
                                                                subjectType: .radical,
                                                                level: 10,
                                                                srsStage: 2,
                                                                srsStageName: "Apprentice II",
                                                                unlockedAt: baseDate,
                                                                startedAt: baseDate.addingTimeInterval(.oneDay),
                                                                passedAt: nil,
                                                                burnedAt: nil,
                                                                availableAt: baseDate,
                                                                isPassed: false,
                                                                isResurrected: false))
        
        let collection = ResourceCollection(object: "collection",
                                            url: URL(string: "https://www.wanikani.com/api/v2/assignments")!,
                                            pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                            totalCount: 2,
                                            dataUpdatedAt: dataUpdatedAt,
                                            data: [expected1, expected2])
        let emptyCollection = ResourceCollection(object: "collection",
                                                 url: URL(string: "https://www.wanikani.com/api/v2/assignments")!,
                                                 pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                                 totalCount: 0,
                                                 dataUpdatedAt: nil,
                                                 data: [])
        
        var apiCallNumber = 0
        let api = MockWaniKaniAPI(resourceCollectionLocator: { resourceCollectionRequestType in
            apiCallNumber += 1
            if case .assignments(filter: let filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return (collection, nil)
                case 2:
                    XCTAssertNotNil(filter)
                    return (emptyCollection, nil)
                default:
                    XCTFail("Only expected 2 requests")
                    fatalError()
                }
            } else {
                XCTFail("Expected load request")
                fatalError()
            }
        })
        
        let resourceRepository = ResourceRepository(databaseManager: databaseManager, api: api)
        
        let callbackExpectation = self.expectation(description: "First callback")
        let notificationExpectation = self.expectation(forNotification: .waniKaniAssignmentsDidChange, object: nil, handler: nil)
        var callbackCount = 0
        resourceRepository.updateAssignments(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .success = result {
                callbackExpectation.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation, notificationExpectation], timeout: 10)
        
        XCTAssertEqual(callbackCount, 1)
        
        var updateTime: Date?
        do {
            updateTime = try resourceRepository.getLastUpdateDate(for: .assignments)
            XCTAssertNotNil(updateTime)
            
            let load1 = try resourceRepository.loadResource(id: 1)
            let load2 = try resourceRepository.loadResource(id: 2)
            XCTAssertEqual(load1, expected1)
            XCTAssertEqual(load2, expected2)
            
            let load = try resourceRepository.loadResources(ids: [1, 2])
            XCTAssertEqual(load, [expected1, expected2])
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let callbackExpectation2 = expectation(description: "Second callback")
        callbackCount = 0
        resourceRepository.updateAssignments(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .noData = result {
                callbackExpectation2.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation2], timeout: 10)
        XCTAssertEqual(callbackCount, 1)
        
        do {
            let updateTime2 = try resourceRepository.getLastUpdateDate(for: .assignments)
            XCTAssertNotEqual(updateTime2, updateTime)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateStudyMaterials() {
        let dataUpdatedAt = makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 51)
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
        
        let collection = ResourceCollection(object: "collection",
                                            url: URL(string: "https://www.wanikani.com/api/v2/study_materials")!,
                                            pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                            totalCount: 1,
                                            dataUpdatedAt: dataUpdatedAt,
                                            data: [expected])
        let emptyCollection = ResourceCollection(object: "collection",
                                                 url: URL(string: "https://www.wanikani.com/api/v2/study_materials")!,
                                                 pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                                 totalCount: 0,
                                                 dataUpdatedAt: nil,
                                                 data: [])
        
        var apiCallNumber = 0
        let api = MockWaniKaniAPI(resourceCollectionLocator: { resourceCollectionRequestType in
            apiCallNumber += 1
            if case .studyMaterials(filter: let filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return (collection, nil)
                case 2:
                    XCTAssertNotNil(filter)
                    return (emptyCollection, nil)
                default:
                    XCTFail("Only expected 2 requests")
                    fatalError()
                }
            } else {
                XCTFail("Expected load request")
                fatalError()
            }
        })
        
        let resourceRepository = ResourceRepository(databaseManager: databaseManager, api: api)
        
        let callbackExpectation = expectation(description: "First callback")
        let notificationExpectation = self.expectation(forNotification: .waniKaniStudyMaterialsDidChange, object: nil, handler: nil)
        var callbackCount = 0
        resourceRepository.updateStudyMaterials(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .success = result {
                callbackExpectation.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation, notificationExpectation], timeout: 10)
        
        XCTAssertEqual(callbackCount, 1)
        
        var updateTime: Date?
        do {
            updateTime = try resourceRepository.getLastUpdateDate(for: .studyMaterials)
            XCTAssertNotNil(updateTime)
            
            let load = try resourceRepository.loadResource(id: 204431)
            XCTAssertEqual(load, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let callbackExpectation2 = expectation(description: "Second callback")
        callbackCount = 0
        resourceRepository.updateStudyMaterials(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .noData = result {
                callbackExpectation2.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation2], timeout: 10)
        XCTAssertEqual(callbackCount, 1)
        
        do {
            let updateTime2 = try resourceRepository.getLastUpdateDate(for: .studyMaterials)
            XCTAssertNotEqual(updateTime2, updateTime)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateSubjects() {
        let dataUpdatedAt = makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 51)
        let expected1 = ResourceCollectionItem(id: 1,
                                               type: .radical,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/1")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 6, day: 12, hour: 23, minute: 21, second: 17),
                                               data: Radical(level: 1,
                                                             createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 18, minute: 8, second: 16),
                                                             slug: "ground",
                                                             characters: "一",
                                                             characterImages: [],
                                                             meanings: [Meaning(meaning: "Ground", isPrimary: true)],
                                                             documentURL: URL(string: "https://www.wanikani.com/radicals/ground")!))
        let expected2 = ResourceCollectionItem(id: 440,
                                               type: .kanji,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/440")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 47),
                                               data: Kanji(level: 1,
                                                           createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 19, minute: 55, second: 19),
                                                           slug: "一",
                                                           characters: "一",
                                                           meanings: [Meaning(meaning: "One", isPrimary: true)],
                                                           readings: [Reading(type: "Onyomi", reading: "いち", isPrimary: true),
                                                                      Reading(type: "Kunyomi", reading: "ひと", isPrimary: false),
                                                                      Reading(type: "Nanori", reading: "かず", isPrimary: false)],
                                                           componentSubjectIDs: [1],
                                                           documentURL: URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!))
        let expected3 = ResourceCollectionItem(id: 2467,
                                               type: .vocabulary,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/2467")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 11, second: 3),
                                               data: Vocabulary(level: 1,
                                                                createdAt: makeUTCDate(year: 2012, month: 2, day: 28, hour: 8, minute: 4, second: 47),
                                                                slug: "一",
                                                                characters: "一",
                                                                meanings: [Meaning(meaning: "One", isPrimary: true)],
                                                                readings: [Reading(reading: "いち", isPrimary: true)],
                                                                partsOfSpeech: ["numeral"],
                                                                componentSubjectIDs: [440],
                                                                documentURL: URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80")!))
        
        let collection = ResourceCollection(object: "collection",
                                            url: URL(string: "https://www.wanikani.com/api/v2/subjects")!,
                                            pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                            totalCount: 3,
                                            dataUpdatedAt: dataUpdatedAt,
                                            data: [expected1, expected2, expected3])
        let emptyCollection = ResourceCollection(object: "collection",
                                                 url: URL(string: "https://www.wanikani.com/api/v2/subjects")!,
                                                 pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                                 totalCount: 0,
                                                 dataUpdatedAt: nil,
                                                 data: [])
        
        var apiCallNumber = 0
        let api = MockWaniKaniAPI(resourceCollectionLocator: { resourceCollectionRequestType in
            apiCallNumber += 1
            if case .subjects(filter: let filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return (collection, nil)
                case 2:
                    XCTAssertNotNil(filter)
                    return (emptyCollection, nil)
                default:
                    XCTFail("Only expected 2 requests")
                    fatalError()
                }
            } else {
                XCTFail("Expected load request")
                fatalError()
            }
        })
        
        let resourceRepository = ResourceRepository(databaseManager: databaseManager, api: api)
        
        let callbackExpectation = expectation(description: "First callback")
        let notificationExpectation = self.expectation(forNotification: .waniKaniSubjectsDidChange, object: nil, handler: nil)
        var callbackCount = 0
        resourceRepository.updateSubjects(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .success = result {
                callbackExpectation.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation, notificationExpectation], timeout: 10)
        
        XCTAssertEqual(callbackCount, 1)
        
        var updateTime: Date?
        do {
            updateTime = try resourceRepository.getLastUpdateDate(for: .subjects)
            XCTAssertNotNil(updateTime)
            
            let load1 = try resourceRepository.loadResource(id: 1)
            let load2 = try resourceRepository.loadResource(id: 440)
            let load3 = try resourceRepository.loadResource(id: 2467)
            XCTAssertEqual(load1, expected1)
            XCTAssertEqual(load2, expected2)
            XCTAssertEqual(load3, expected3)
            
            let load = try resourceRepository.loadResources(ids: [1, 440, 2467])
            XCTAssertEqual(load, [expected1, expected2, expected3])
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let callbackExpectation2 = expectation(description: "Second callback")
        callbackCount = 0
        resourceRepository.updateSubjects(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .noData = result {
                callbackExpectation2.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation2], timeout: 10)
        XCTAssertEqual(callbackCount, 1)
        
        do {
            let updateTime2 = try resourceRepository.getLastUpdateDate(for: .subjects)
            XCTAssertNotEqual(updateTime2, updateTime)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateReviewStatistics() {
        let dataUpdatedAt = makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 51)
        let expected = ResourceCollectionItem(id: 2364240,
                                              type: .reviewStatistic,
                                              url: URL(string: "https://www.wanikani.com/api/v2/review_statistics/2364240")!,
                                              dataUpdatedAt: makeUTCDate(year: 2017, month: 6, day: 26, hour: 22, minute: 19, second: 23),
                                              data: ReviewStatistics(createdAt: makeUTCDate(year: 2016, month: 9, day: 23, hour: 8, minute: 13, second: 49),
                                                                     subjectID: 889,
                                                                     subjectType: .kanji,
                                                                     meaningCorrect: 8,
                                                                     meaningIncorrect: 1,
                                                                     meaningMaxStreak: 5,
                                                                     meaningCurrentStreak: 3,
                                                                     readingCorrect: 8,
                                                                     readingIncorrect: 3,
                                                                     readingMaxStreak: 5,
                                                                     readingCurrentStreak: 2,
                                                                     percentageCorrect: 80))
        
        let collection = ResourceCollection(object: "collection",
                                            url: URL(string: "https://www.wanikani.com/api/v2/review_statistics")!,
                                            pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                            totalCount: 1,
                                            dataUpdatedAt: dataUpdatedAt,
                                            data: [expected])
        let emptyCollection = ResourceCollection(object: "collection",
                                                 url: URL(string: "https://www.wanikani.com/api/v2/review_statistics")!,
                                                 pages: ResourceCollection.Pages(itemsPerPage: 250, previousURL: nil, nextURL: nil),
                                                 totalCount: 0,
                                                 dataUpdatedAt: nil,
                                                 data: [])
        
        var apiCallNumber = 0
        let api = MockWaniKaniAPI(resourceCollectionLocator: { resourceCollectionRequestType in
            apiCallNumber += 1
            if case .reviewStatistics(filter: let filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return (collection, nil)
                case 2:
                    XCTAssertNotNil(filter)
                    return (emptyCollection, nil)
                default:
                    XCTFail("Only expected 2 requests")
                    fatalError()
                }
            } else {
                XCTFail("Expected load request")
                fatalError()
            }
        })
        
        let resourceRepository = ResourceRepository(databaseManager: databaseManager, api: api)
        
        let callbackExpectation = expectation(description: "First callback")
        let notificationExpectation = self.expectation(forNotification: .waniKaniReviewStatisticsDidChange, object: nil, handler: nil)
        var callbackCount = 0
        resourceRepository.updateReviewStatistics(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .success = result {
                callbackExpectation.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation, notificationExpectation], timeout: 10)
        
        XCTAssertEqual(callbackCount, 1)
        
        var updateTime: Date?
        do {
            updateTime = try resourceRepository.getLastUpdateDate(for: .reviewStatistics)
            XCTAssertNotNil(updateTime)
            
            let load = try resourceRepository.loadResource(id: 2364240)
            XCTAssertEqual(load, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let callbackExpectation2 = expectation(description: "Second callback")
        callbackCount = 0
        resourceRepository.updateReviewStatistics(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .noData = result {
                callbackExpectation2.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation2], timeout: 10)
        XCTAssertEqual(callbackCount, 1)
        
        do {
            let updateTime2 = try resourceRepository.getLastUpdateDate(for: .reviewStatistics)
            XCTAssertNotEqual(updateTime2, updateTime)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testUpdateUser() {
        let expected = StandaloneResource(type: .user,
                                          url: URL(string: "https://www.wanikani.com/api/v2/user")!,
                                          dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 25, hour: 8, minute: 8, second: 6),
                                          data: UserInformation(username: "cplaverty",
                                                                level: 13,
                                                                maxLevelGrantedBySubscription: 60,
                                                                startedAt: makeUTCDate(year: 2014, month: 6, day: 12, hour: 7, minute: 40, second: 29),
                                                                isSubscribed: true,
                                                                profileURL: URL(string: "https://www.wanikani.com/users/cplaverty")!,
                                                                currentVacationStartedAt: nil))
        
        let api = MockWaniKaniAPI(standaloneResourceLocator: { resourceRequestType in
            if case .user = resourceRequestType {
                return (expected, nil)
            } else {
                XCTFail("Expected load request")
                fatalError()
            }
        })
        
        let resourceRepository = ResourceRepository(databaseManager: databaseManager, api: api)
        
        let callbackExpectation = expectation(description: "First callback")
        let notificationExpectation = self.expectation(forNotification: .waniKaniUserInformationDidChange, object: nil, handler: nil)
        var callbackCount = 0
        resourceRepository.updateUser(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .success = result {
                callbackExpectation.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation, notificationExpectation], timeout: 10)
        
        XCTAssertEqual(callbackCount, 1)
        
        var updateTime: Date?
        do {
            updateTime = try resourceRepository.getLastUpdateDate(for: .user)
            XCTAssertNotNil(updateTime)
            
            let load = try resourceRepository.userInformation()
            XCTAssertNotNil(load)
            if let load = load {
                XCTAssertEqual(load, expected.data as! UserInformation)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        let callbackExpectation2 = expectation(description: "Second callback")
        callbackCount = 0
        resourceRepository.updateUser(minimumFetchInterval: 0) { result in
            callbackCount += 1
            if case .noData = result {
                callbackExpectation2.fulfill()
            } else {
                XCTFail("\(result)")
            }
        }
        
        wait(for: [callbackExpectation2], timeout: 10)
        XCTAssertEqual(callbackCount, 1)
        
        do {
            let updateTime2 = try resourceRepository.getLastUpdateDate(for: .user)
            XCTAssertNotEqual(updateTime2, updateTime)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
}
