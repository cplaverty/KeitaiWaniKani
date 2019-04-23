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
                                               data: Assignment(createdAt: baseDate.addingTimeInterval(-.oneDay),
                                                                subjectID: 1,
                                                                subjectType: .radical,
                                                                srsStage: 9,
                                                                srsStageName: "Burned",
                                                                unlockedAt: baseDate,
                                                                startedAt: baseDate.addingTimeInterval(.oneDay),
                                                                passedAt: baseDate.addingTimeInterval(4 * .oneDay),
                                                                burnedAt: baseDate.addingTimeInterval(160 * .oneDay),
                                                                availableAt: baseDate,
                                                                resurrectedAt: nil,
                                                                isPassed: true,
                                                                isResurrected: false,
                                                                isHidden: false))
        let expected2 = ResourceCollectionItem(id: 2,
                                               type: .assignment,
                                               url: URL(string: "https://www.wanikani.com/api/v2/assignments/2")!,
                                               dataUpdatedAt: dataUpdatedAt,
                                               data: Assignment(createdAt: baseDate.addingTimeInterval(-.oneDay),
                                                                subjectID: 10,
                                                                subjectType: .radical,
                                                                srsStage: 2,
                                                                srsStageName: "Apprentice II",
                                                                unlockedAt: baseDate,
                                                                startedAt: baseDate.addingTimeInterval(.oneDay),
                                                                passedAt: nil,
                                                                burnedAt: nil,
                                                                availableAt: baseDate,
                                                                resurrectedAt: nil,
                                                                isPassed: false,
                                                                isResurrected: false,
                                                                isHidden: false))
        
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
            if case let .assignments(filter: filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return .success(collection)
                case 2:
                    XCTAssertNotNil(filter)
                    return .success(emptyCollection)
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
            
            let load1 = try resourceRepository.loadResource(id: 1, type: .assignment)
            let load2 = try resourceRepository.loadResource(id: 2, type: .assignment)
            XCTAssertEqual(load1, expected1)
            XCTAssertEqual(load2, expected2)
            
            let load = try resourceRepository.loadResources(ids: [1, 2], type: .assignment)
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
                                                                   meaningSynonyms: ["industry"],
                                                                   isHidden: false))
        
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
            if case let .studyMaterials(filter: filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return .success(collection)
                case 2:
                    XCTAssertNotNil(filter)
                    return .success(emptyCollection)
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
            
            let load = try resourceRepository.loadResource(id: 204431, type: .studyMaterial)
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
        createTestUser()
        
        let dataUpdatedAt = makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 51)
        let expected1 = ResourceCollectionItem(id: 1,
                                               type: .radical,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/1")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 6, day: 12, hour: 23, minute: 21, second: 17),
                                               data: Radical(createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 18, minute: 8, second: 16),
                                                             level: 1,
                                                             slug: "ground",
                                                             hiddenAt: nil,
                                                             documentURL: URL(string: "https://www.wanikani.com/radicals/ground")!,
                                                             characters: "一",
                                                             characterImages: [
                                                                Radical.CharacterImage(url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-original.png?1520987606")!,
                                                                                       metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "1024x1024", styleName: "original", inlineStyles: nil),
                                                                                       contentType: "image/png"),
                                                                Radical.CharacterImage(url: URL(string: "https://cdn.wanikani.com/images/legacy/1054-subject-1-normal-weight-black-1024px.png?1520987606")!,
                                                                                       metadata: Radical.CharacterImage.Metadata(color: "#000000", dimensions: "1024x1024", styleName: "1024px", inlineStyles: nil),
                                                                                       contentType: "image/png"),
                                                                ],
                                                             meanings: [Meaning(meaning: "Ground", isPrimary: true, isAcceptedAnswer: true)],
                                                             auxiliaryMeanings: [],
                                                             amalgamationSubjectIDs: [440],
                                                             meaningMnemonic: "ground",
                                                             lessonPosition: 0))
        let expected2 = ResourceCollectionItem(id: 440,
                                               type: .kanji,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/440")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 6, second: 47),
                                               data: Kanji(createdAt: makeUTCDate(year: 2012, month: 2, day: 27, hour: 19, minute: 55, second: 19),
                                                           level: 1,
                                                           slug: "一",
                                                           hiddenAt: nil,
                                                           documentURL: URL(string: "https://www.wanikani.com/kanji/%E4%B8%80")!,
                                                           characters: "一",
                                                           meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                           auxiliaryMeanings: [AuxiliaryMeaning(type: "whitelist", meaning: "1")],
                                                           readings: [
                                                            Reading(type: .onyomi, reading: "いち", isPrimary: true, isAcceptedAnswer: true),
                                                            Reading(type: .kunyomi, reading: "ひと", isPrimary: false, isAcceptedAnswer: false),
                                                            Reading(type: .nanori, reading: "かず", isPrimary: false, isAcceptedAnswer: false),
                                                            ],
                                                           componentSubjectIDs: [1],
                                                           amalgamationSubjectIDs: [2467],
                                                           visuallySimilarSubjectIDs: [],
                                                           meaningMnemonic: "ground",
                                                           meaningHint: "one",
                                                           readingMnemonic: "itchy",
                                                           readingHint: "sensation",
                                                           lessonPosition: 26))
        let expected3 = ResourceCollectionItem(id: 2467,
                                               type: .vocabulary,
                                               url: URL(string: "https://www.wanikani.com/api/v2/subjects/2467")!,
                                               dataUpdatedAt: makeUTCDate(year: 2017, month: 7, day: 14, hour: 1, minute: 11, second: 3),
                                               data: Vocabulary(createdAt: makeUTCDate(year: 2012, month: 2, day: 28, hour: 8, minute: 4, second: 47),
                                                                level: 1,
                                                                slug: "一",
                                                                hiddenAt: nil,
                                                                documentURL: URL(string: "https://www.wanikani.com/vocabulary/%E4%B8%80")!,
                                                                characters: "一",
                                                                meanings: [Meaning(meaning: "One", isPrimary: true, isAcceptedAnswer: true)],
                                                                auxiliaryMeanings: [AuxiliaryMeaning(type: "whitelist", meaning: "1")],
                                                                readings: [Reading(reading: "いち", isPrimary: true, isAcceptedAnswer: true)],
                                                                partsOfSpeech: ["numeral"],
                                                                componentSubjectIDs: [440],
                                                                meaningMnemonic: "one",
                                                                readingMnemonic: "kunyomi",
                                                                contextSentences: [
                                                                    Vocabulary.ContextSentence(english: "Let’s meet up once.", japanese: "一ど、あいましょう。"),
                                                                    Vocabulary.ContextSentence(english: "First place was an American.", japanese: "一いはアメリカ人でした。"),
                                                                    Vocabulary.ContextSentence(english: "I’m the weakest man in the world.", japanese: "ぼくはせかいで一ばんよわい。"),
                                                                    ],
                                                                pronunciationAudios: [
                                                                    Vocabulary.PronunciationAudio(url: URL(string: "https://cdn.wanikani.com/audios/3020-subject-2467.mp3?1547862356")!,
                                                                                                  metadata: Vocabulary.PronunciationAudio.Metadata(gender: "male", sourceID: 2711, pronunciation: "いち", voiceActorID: 2, voiceActorName: "Kenichi", voiceDescription: "Tokyo accent"),
                                                                                                  contentType: "audio/mpeg"),
                                                                    Vocabulary.PronunciationAudio(url: URL(string: "https://cdn.wanikani.com/audios/3018-subject-2467.ogg?1547862356")!,
                                                                                                  metadata: Vocabulary.PronunciationAudio.Metadata(gender: "male", sourceID: 2711, pronunciation: "いち", voiceActorID: 2, voiceActorName: "Kenichi", voiceDescription: "Tokyo accent"),
                                                                                                  contentType: "audio/ogg"),
                                                                    ],
                                                                lessonPosition: 44))
        
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
            if case let .subjects(filter: filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return .success(collection)
                case 2:
                    XCTAssertNotNil(filter)
                    return .success(emptyCollection)
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
            
            let load1 = try resourceRepository.loadResource(id: 1, type: .radical)
            let load2 = try resourceRepository.loadResource(id: 440, type: .kanji)
            let load3 = try resourceRepository.loadResource(id: 2467, type: .vocabulary)
            XCTAssertEqual(load1, expected1)
            XCTAssertEqual(load2, expected2)
            XCTAssertEqual(load3, expected3)
            
            let load = try resourceRepository.loadSubjects(ids: [1, 440, 2467])
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
                                                                     percentageCorrect: 80,
                                                                     isHidden: false))
        
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
            if case let .reviewStatistics(filter: filter) = resourceCollectionRequestType {
                switch apiCallNumber {
                case 1:
                    XCTAssertNil(filter)
                    return .success(collection)
                case 2:
                    XCTAssertNotNil(filter)
                    return .success(emptyCollection)
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
            
            let load = try resourceRepository.loadResource(id: 2364240, type: .reviewStatistic)
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
                                          dataUpdatedAt: makeUTCDate(year: 2019, month: 2, day: 9, hour: 18, minute: 21, second: 51),
                                          data: UserInformation(id: "7d1742c5-c493-444b-97ae-c495bec9d850",
                                                                username: "cplaverty",
                                                                level: 14,
                                                                profileURL: URL(string: "https://www.wanikani.com/users/cplaverty")!,
                                                                startedAt: makeUTCDate(year: 2014, month: 6, day: 12, hour: 7, minute: 40, second: 29),
                                                                subscription: UserInformation.Subscription(isActive: true,
                                                                                                           type: "lifetime",
                                                                                                           maxLevelGranted: 60,
                                                                                                           periodEndsAt: nil),
                                                                currentVacationStartedAt: nil))
        
        let api = MockWaniKaniAPI(standaloneResourceLocator: { resourceRequestType in
            if case .user = resourceRequestType {
                return .success(expected)
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
    
    private func createTestUser() {
        let user = UserInformation(id: "00000000-0000-0000-0000-000000000000",
                                   username: "Test",
                                   level: 1,
                                   profileURL: URL(string: "https://localhost/Test")!,
                                   startedAt: Date(),
                                   subscription: UserInformation.Subscription(isActive: true,
                                                                              type: "lifetime",
                                                                              maxLevelGranted: 60,
                                                                              periodEndsAt: nil),
                                   currentVacationStartedAt: nil)
        
        databaseManager.databaseQueue!.inExclusiveTransaction { (database, rollback) in
            do {
                try user.write(to: database)
                try ResourceType.user.setLastUpdateDate(Date(), in: database)
            } catch {
                rollback.pointee = true
                XCTFail("Failed to create test user: \(error)")
            }
        }
    }
    
}
