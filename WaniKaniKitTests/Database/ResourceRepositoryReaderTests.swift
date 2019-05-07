//
//  ResourceRepositoryReaderTests.swift
//  WaniKaniKitTests
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import FMDB
import XCTest
@testable import WaniKaniKit

class ResourceRepositoryReaderTests: XCTestCase {
    
    private var databaseManager: DatabaseManager!
    private var resourceRepository: ResourceRepositoryReader!
    
    private var nextAssignmentID = 100000
    private var nextSubjectID = 1
    private let testUserLevel = 10
    
    private var nextHourReviewTime: Date!
    private var nextDayReviewTime: Date!
    
    override func setUp() {
        super.setUp()
        
        let factory = EphemeralDatabaseConnectionFactory(databaseStorageType: .file)
        databaseManager = DatabaseManager(factory: factory)
        resourceRepository = ResourceRepositoryReader(databaseManager: databaseManager)
        
        nextAssignmentID = 100000
        
        if !databaseManager.open() {
            self.continueAfterFailure = false
            XCTFail("Failed to open database queue")
        }
        
        createTestUser()
        
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: utcTimeZone, from: calendar.date(byAdding: .minute, value: 30, to: Date())!)
        components.second = 0
        components.nanosecond = 0
        
        nextHourReviewTime = components.date!
        
        components = calendar.dateComponents(in: utcTimeZone, from: calendar.date(byAdding: .hour, value: 12, to: calendar.startOfHour(for: Date()))!)
        
        nextDayReviewTime = components.date!
    }
    
    override func tearDown() {
        databaseManager.close()
        databaseManager = nil
        
        super.tearDown()
    }
    
    func testHasStudyQueue() {
        XCTAssertFalse(try resourceRepository.hasStudyQueue())
        
        populateDatabaseForStudyQueue(lessonCount: 10, pendingReviewCount: 23)
        
        XCTAssertTrue(try resourceRepository.hasStudyQueue())
    }
    
    func testStudyQueue_Empty() {
        let expected = StudyQueue(lessonsAvailable: 0, reviewsAvailable: 0, nextReviewDate: nil, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expected)
    }
    
    func testStudyQueue_PendingLessonsReviews_NoFutureReviews() {
        populateDatabaseForStudyQueue(lessonCount: 10, pendingReviewCount: 23)
        
        let expected = StudyQueue(lessonsAvailable: 10, reviewsAvailable: 23, nextReviewDate: nil, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expected)
    }
    
    func testStudyQueue_FutureReviewsOnly() {
        populateDatabaseForStudyQueue(futureReviewCount: 6, futureReviewTime: nextHourReviewTime)
        populateDatabaseForStudyQueue(futureReviewCount: 4, futureReviewTime: nextDayReviewTime)
        
        let expected = StudyQueue(lessonsAvailable: 0, reviewsAvailable: 0, nextReviewDate: nextHourReviewTime, reviewsAvailableNextHour: 6, reviewsAvailableNextDay: 10)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expected)
    }
    
    func testStudyQueue_ResurrectedItems() {
        populateDatabaseForStudyQueue(lessonCount: 10, pendingReviewCount: 18, resurrectedReviewCount: 5)
        
        let expected = StudyQueue(lessonsAvailable: 10, reviewsAvailable: 23, nextReviewDate: nil, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expected)
    }

    func testStudyQueue_VacationMode() {
        populateDatabaseForStudyQueue(lessonCount: 10, pendingReviewCount: 23, futureReviewCount: 6, futureReviewTime: nextHourReviewTime)
        populateDatabaseForStudyQueue(lessonCount: 0, pendingReviewCount: 0, futureReviewCount: 4, futureReviewTime: nextDayReviewTime)
        
        let expectedPreVacation = StudyQueue(lessonsAvailable: 10, reviewsAvailable: 23, nextReviewDate: nextHourReviewTime, reviewsAvailableNextHour: 6, reviewsAvailableNextDay: 10)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expectedPreVacation)
        
        createTestUser(currentVacationStartedAt: Date())
        
        let expectedPostVacation = StudyQueue(lessonsAvailable: 0, reviewsAvailable: 0, nextReviewDate: nil, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        
        XCTAssertEqual(try resourceRepository.studyQueue(), expectedPostVacation)
    }
    
    func testStudyQueue_Load() {
        populateDatabaseForStudyQueue(lessonCount: 327, pendingReviewCount: 1352, futureReviewCount: 50, futureReviewTime: nextHourReviewTime)
        populateDatabaseForStudyQueue(lessonCount: 0, pendingReviewCount: 0, futureReviewCount: 2342, futureReviewTime: nextDayReviewTime)
        
        let expected = StudyQueue(lessonsAvailable: 327, reviewsAvailable: 1352, nextReviewDate: nextHourReviewTime, reviewsAvailableNextHour: 50, reviewsAvailableNextDay: 2392)
        
        self.measure {
            do {
                let studyQueue = try resourceRepository.studyQueue()
                XCTAssertEqual(studyQueue, expected)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testHasLevelProgression() {
        XCTAssertFalse(try resourceRepository.hasLevelProgression())
        
        populateDatabaseForLevelProgression(radicalsNotPassed: 10, radicalsPassed: 0, kanjiNotPassed: 15, kanjiPassed: 0)
        
        XCTAssertTrue(try resourceRepository.hasLevelProgression())
    }
    
    func testLevelProgression_Empty() {
        let expected = CurrentLevelProgression(radicalsProgress: 0, radicalsTotal: 0, radicalSubjectIDs: [], kanjiProgress: 0, kanjiTotal: 0, kanjiSubjectIDs: [])
        
        XCTAssertEqual(try resourceRepository.levelProgression(), expected)
    }
    
    func testLevelProgression_NoProgress() {
        let radicalSubjectIDs = (nextSubjectID..<(nextSubjectID + 10)).map { $0 }
        let kanjiSubjectIDs = ((nextSubjectID + 10)..<(nextSubjectID + 10 + 15)).map { $0 }
        
        populateDatabaseForLevelProgression(radicalsNotPassed: 10, radicalsPassed: 0, kanjiNotPassed: 15, kanjiPassed: 0)
        
        let expected = CurrentLevelProgression(radicalsProgress: 0, radicalsTotal: 10, radicalSubjectIDs: radicalSubjectIDs, kanjiProgress: 0, kanjiTotal: 15, kanjiSubjectIDs: kanjiSubjectIDs)
        
        XCTAssertEqual(try resourceRepository.levelProgression(), expected)
    }
    
    func testLevelProgression_PartialProgress() {
        let radicalSubjectIDs = (nextSubjectID..<(nextSubjectID + 10)).map { $0 }
        let kanjiSubjectIDs = ((nextSubjectID + 10)..<(nextSubjectID + 10 + 15)).map { $0 }
        
        populateDatabaseForLevelProgression(radicalsNotPassed: 4, radicalsPassed: 6, kanjiNotPassed: 12, kanjiPassed: 3)
        
        let expected = CurrentLevelProgression(radicalsProgress: 6, radicalsTotal: 10, radicalSubjectIDs: radicalSubjectIDs, kanjiProgress: 3, kanjiTotal: 15, kanjiSubjectIDs: kanjiSubjectIDs)
        
        XCTAssertEqual(try resourceRepository.levelProgression(), expected)
    }
    
    func testLevelProgression_FullProgress() {
        let radicalSubjectIDs = (nextSubjectID..<(nextSubjectID + 10)).map { $0 }
        let kanjiSubjectIDs = ((nextSubjectID + 10)..<(nextSubjectID + 10 + 15)).map { $0 }
        
        populateDatabaseForLevelProgression(radicalsNotPassed: 0, radicalsPassed: 10, kanjiNotPassed: 0, kanjiPassed: 15)
        
        let expected = CurrentLevelProgression(radicalsProgress: 10, radicalsTotal: 10, radicalSubjectIDs: radicalSubjectIDs, kanjiProgress: 15, kanjiTotal: 15, kanjiSubjectIDs: kanjiSubjectIDs)
        
        XCTAssertEqual(try resourceRepository.levelProgression(), expected)
    }
    
    func testHasSRSDistribution() {
        XCTAssertFalse(try resourceRepository.hasSRSDistribution())
        
        populateDatabaseForSRSDistribution(srsStage: 0, radicals: 30, kanji: 23, vocabulary: 42)
        
        XCTAssertTrue(try resourceRepository.hasSRSDistribution())
    }
    
    func testSRSDistribution_Empty() {
        let expected = SRSDistribution(countsBySRSStage: [SRSStage: SRSItemCounts]())
        
        XCTAssertEqual(try resourceRepository.srsDistribution(), expected)
    }
    
    func testSRSDistribution_Load() {
        populateDatabaseForSRSDistribution(srsStage: 0, radicals: 30, kanji: 23, vocabulary: 42)
        for srsStage in 1...4 {
            populateDatabaseForSRSDistribution(srsStage: srsStage, radicals: 9, kanji: 12, vocabulary: 20)
        }
        for srsStage in 5...6 {
            populateDatabaseForSRSDistribution(srsStage: srsStage, radicals: 45, kanji: 40, vocabulary: 100)
        }
        populateDatabaseForSRSDistribution(srsStage: 7, radicals: 212, kanji: 340, vocabulary: 301)
        populateDatabaseForSRSDistribution(srsStage: 8, radicals: 324, kanji: 753, vocabulary: 1704)
        populateDatabaseForSRSDistribution(srsStage: 9, radicals: 502, kanji: 1452, vocabulary: 3856)
        
        let expected = SRSDistribution(countsBySRSStage: [
            .apprentice: SRSItemCounts(radicals: 36, kanji: 48, vocabulary: 80),
            .guru: SRSItemCounts(radicals: 90, kanji: 80, vocabulary: 200),
            .master: SRSItemCounts(radicals: 212, kanji: 340, vocabulary: 301),
            .enlightened: SRSItemCounts(radicals: 324, kanji: 753, vocabulary: 1704),
            .burned: SRSItemCounts(radicals: 502, kanji: 1452, vocabulary: 3856)
            ])
        
        self.measure {
            do {
                let srsDistribution = try resourceRepository.srsDistribution()
                XCTAssertEqual(srsDistribution, expected)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testReviewTimeline_Empty() {
        let expected = [SRSReviewCounts]()
        
        XCTAssertEqual(try resourceRepository.reviewTimeline(), expected)
    }
    
    func testReviewTimeline_ByLevel() {
        var expectedLvl1 = [SRSReviewCounts]()
        var expectedLvl2 = [SRSReviewCounts]()
        let expectedLvl3 = [SRSReviewCounts]()
        
        var resourceItems = [ResourceCollectionItem]()
        
        let calendar = Calendar.current
        var reviewTime = calendar.startOfHour(for: Date()).addingTimeInterval(.oneDay)
        
        repeat {
            let radicalCount = Int.random(in: 0...30)
            let kanjiCount = Int.random(in: 0...30)
            let vocabularyCount = Int.random(in: 0...30)
            for _ in 0..<radicalCount {
                resourceItems += createTestRadicalWithAssignment(level: 1, srsStage: 1, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestRadicalWithAssignment(level: 2, srsStage: 2, availableAt: reviewTime)
                }
            }
            for _ in 0..<kanjiCount {
                resourceItems += createTestKanjiWithAssignment(level: 1, srsStage: 2, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestKanjiWithAssignment(level: 2, srsStage: 3, availableAt: reviewTime)
                }
            }
            for _ in 0..<vocabularyCount {
                resourceItems += createTestVocabularyWithAssignment(level: 1, srsStage: 1, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestVocabularyWithAssignment(level: 2, srsStage: 5, availableAt: reviewTime)
                }
            }
            expectedLvl1.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: radicalCount, kanji: kanjiCount, vocabulary: vocabularyCount)))
            expectedLvl2.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: radicalCount * 2, kanji: kanjiCount * 2, vocabulary: vocabularyCount * 2)))
            reviewTime += .oneHour
        } while expectedLvl1.count < 100
        
        expectedLvl1 = expectedLvl1.filter { c in c.itemCounts.total > 0 }
        expectedLvl2 = expectedLvl2.filter { c in c.itemCounts.total > 0 }
        
        NSLog("Writing \(resourceItems.count) assignments")
        writeToDatabase(resourceItems)
        
        XCTAssertEqual(try resourceRepository.reviewTimeline(forLevel: 1), expectedLvl1)
        XCTAssertEqual(try resourceRepository.reviewTimeline(forLevel: 2), expectedLvl2)
        XCTAssertEqual(try resourceRepository.reviewTimeline(forLevel: 3), expectedLvl3)
    }
    
    func testReviewTimeline_BySRSStage() {
        var expectedApprentice = [SRSReviewCounts]()
        var expectedGuru = [SRSReviewCounts]()
        var expectedMaster = [SRSReviewCounts]()
        let expectedEnlightened = [SRSReviewCounts]()
        
        var resourceItems = [ResourceCollectionItem]()
        
        let calendar = Calendar.current
        var reviewTime = calendar.startOfHour(for: Date()).addingTimeInterval(.oneDay)
        
        repeat {
            let radicalCount = Int.random(in: 0...30)
            let kanjiCount = Int.random(in: 0...30)
            let vocabularyCount = Int.random(in: 0...30)
            for _ in 0..<radicalCount {
                resourceItems += createTestRadicalWithAssignment(level: 1, srsStage: 1, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestRadicalWithAssignment(level: 2, srsStage: 2, availableAt: reviewTime)
                }
            }
            for _ in 0..<kanjiCount {
                resourceItems += createTestKanjiWithAssignment(level: 1, srsStage: 6, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestKanjiWithAssignment(level: 2, srsStage: 7, availableAt: reviewTime)
                }
            }
            for _ in 0..<vocabularyCount {
                resourceItems += createTestVocabularyWithAssignment(level: 1, srsStage: 1, availableAt: reviewTime)
                for _ in 0..<2 {
                    resourceItems += createTestVocabularyWithAssignment(level: 2, srsStage: 5, availableAt: reviewTime)
                }
            }
            expectedApprentice.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: radicalCount * 3, kanji: 0, vocabulary: vocabularyCount)))
            expectedGuru.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: 0, kanji: kanjiCount, vocabulary: vocabularyCount * 2)))
            expectedMaster.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: 0, kanji: kanjiCount * 2, vocabulary: 0)))
            reviewTime += .oneHour
        } while expectedApprentice.count < 100
        
        expectedApprentice = expectedApprentice.filter { c in c.itemCounts.total > 0 }
        expectedGuru = expectedGuru.filter { c in c.itemCounts.total > 0 }
        expectedMaster = expectedMaster.filter { c in c.itemCounts.total > 0 }
        
        NSLog("Writing \(resourceItems.count) assignments")
        writeToDatabase(resourceItems)
        
        XCTAssertEqual(try resourceRepository.reviewTimeline(forSRSStage: .apprentice), expectedApprentice)
        XCTAssertEqual(try resourceRepository.reviewTimeline(forSRSStage: .guru), expectedGuru)
        XCTAssertEqual(try resourceRepository.reviewTimeline(forSRSStage: .master), expectedMaster)
        XCTAssertEqual(try resourceRepository.reviewTimeline(forSRSStage: .enlightened), expectedEnlightened)
    }
    
    func testReviewTimeline_Load() {
        var expected = [SRSReviewCounts]()
        
        var resourceItems = [ResourceCollectionItem]()
        
        let calendar = Calendar.current
        var reviewTime = calendar.startOfHour(for: Date()).addingTimeInterval(.oneDay)
        
        repeat {
            let radicalCount = Int.random(in: 0...30)
            let kanjiCount = Int.random(in: 0...30)
            let vocabularyCount = Int.random(in: 0...30)
            for _ in 0..<radicalCount {
                resourceItems += createTestRadicalWithAssignment(level: 1, srsStage: 3, availableAt: reviewTime)
            }
            for _ in 0..<kanjiCount {
                resourceItems += createTestKanjiWithAssignment(level: 1, srsStage: 3, availableAt: reviewTime)
            }
            for _ in 0..<vocabularyCount {
                resourceItems += createTestVocabularyWithAssignment(level: 1, srsStage: 3, availableAt: reviewTime)
            }
            expected.append(SRSReviewCounts(dateAvailable: reviewTime, itemCounts: SRSItemCounts(radicals: radicalCount, kanji: kanjiCount, vocabulary: vocabularyCount)))
            reviewTime += .oneHour
        } while expected.count < 100
        
        NSLog("Writing \(resourceItems.count) assignments")
        writeToDatabase(resourceItems)
        
        self.measure {
            do {
                let reviewTimeline = try resourceRepository.reviewTimeline()
                XCTAssertEqual(reviewTimeline, expected)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testHasLevelTimeline() {
        XCTAssertFalse(try resourceRepository.hasLevelTimeline())
        
        populateDatabaseForLevelProgression(radicalsNotPassed: 10, radicalsPassed: 0, kanjiNotPassed: 15, kanjiPassed: 0)
        
        XCTAssertTrue(try resourceRepository.hasLevelTimeline())
    }
    
    func testLevelTimeline_Empty() {
        let expected = LevelData(detail: [], projectedCurrentLevel: nil)
        
        XCTAssertEqual(try resourceRepository.levelTimeline(), expected)
    }
    
    func testLevelTimeline_Load() {
        var levelProgressions = [LevelProgression]()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: utcTimeZone,
                                                 from: calendar.date(byAdding: .weekOfYear, value: -testUserLevel * 2 + 1,
                                                                     to: calendar.startOfDay(for: Date()).addingTimeInterval(.oneDay))!)
        
        var resourceItems = [ResourceCollectionItem]()
        
        var startDate = components.date!
        
        for level in 1..<testUserLevel {
            let radicalCount = Int.random(in: 1...30)
            let kanjiCount = Int.random(in: 1...30)
            let kanjiStart = startDate + .oneDay * 7
            
            for _ in 0..<radicalCount {
                resourceItems += createTestRadicalWithAssignment(level: level, srsStage: 5, unlockedAt: startDate, availableAt: startDate, isPassed: true)
            }
            for _ in 0..<kanjiCount {
                resourceItems += createTestKanjiWithAssignment(level: level, srsStage: 5, unlockedAt: kanjiStart, availableAt: kanjiStart, isPassed: true)
            }
            
            let endDate = startDate + .oneDay * 14
            levelProgressions.append(LevelProgression(level: level, createdAt: startDate, unlockedAt: startDate, startedAt: startDate, passedAt: endDate, completedAt: nil, abandonedAt: nil))
            startDate = endDate
        }
        
        let radicalCount = Int.random(in: 1...30)
        let kanjiCount = Int.random(in: 1...30)
        let kanjiStart = startDate + .oneDay * 7
        
        XCTAssertGreaterThan(kanjiStart, Date())
        
        let firstRadicalAssignmentId = nextAssignmentID
        for _ in 0..<radicalCount {
            resourceItems += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 5, unlockedAt: startDate, availableAt: startDate, isPassed: true)
        }
        let firstKanjiAssignmentId = nextAssignmentID
        for _ in 0..<kanjiCount {
            resourceItems += createTestKanjiWithAssignment(level: testUserLevel, srsStage: 0, unlockedAt: kanjiStart, availableAt: kanjiStart, isPassed: false)
        }
        let lastKanjiAssignmentId = nextAssignmentID
        
        levelProgressions.append(LevelProgression(level: testUserLevel, createdAt: startDate, unlockedAt: startDate, startedAt: startDate, passedAt: nil, completedAt: nil, abandonedAt: nil))
        
        NSLog("Writing \(resourceItems.count) resources")
        writeToDatabase(resourceItems)
        
        let minimumGuruTime = 4 * .oneHour + 8 * .oneHour + .oneDay - .oneHour + 2 * .oneDay - .oneHour
        let projectedLevelInfo = ProjectedLevelInfo(level: testUserLevel, startDate: startDate, endDate: kanjiStart + minimumGuruTime, endDateMethodology: .calculated(usingLockedItem: false))
        
        let expected = LevelData(detail: levelProgressions, projectedCurrentLevel: projectedLevelInfo)
        
        do {
            let levelTimeline = try resourceRepository.levelTimeline()
            XCTAssertEqual(levelTimeline, expected)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        databaseManager.databaseQueue!.inExclusiveTransaction { (database, rollback) in
            for assignmentId in firstKanjiAssignmentId..<lastKanjiAssignmentId {
                do {
                    let dependencies = firstKanjiAssignmentId - firstRadicalAssignmentId > 1 ? [firstRadicalAssignmentId, firstRadicalAssignmentId + 1] : [firstRadicalAssignmentId]
                    try SubjectRelation.write(items: dependencies, to: database, type: .component, id: assignmentId)
                } catch {
                    rollback.pointee = true
                    XCTFail("Failed to create test items: \(error)")
                }
            }
        }
        
        self.measure {
            do {
                let levelTimeline = try resourceRepository.levelTimeline()
                XCTAssertEqual(levelTimeline, expected)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testSubjectSearch() {
        let leafRadical = createTestRadical(level: 1, characters: nil, meanings: [Meaning(meaning: "leaf", isPrimary: true, isAcceptedAnswer: true)])
        let finsRadical = createTestRadical(level: 1, characters: "ハ", meanings: [Meaning(meaning: "fins", isPrimary: true, isAcceptedAnswer: true)])
        let mountainKanji = createTestKanji(level: 1, characters: "山",
                                            meanings: [Meaning(meaning: "Mountain", isPrimary: true, isAcceptedAnswer: true)],
                                            readings: [Reading(type: .onyomi, reading: "さん", isPrimary: true, isAcceptedAnswer: true), Reading(type: .kunyomi, reading: "やま", isPrimary: false, isAcceptedAnswer: false)])
        let mouthKanji = createTestKanji(level: 1, characters: "口",
                                         meanings: [Meaning(meaning: "Mouth", isPrimary: true, isAcceptedAnswer: true)],
                                         readings: [Reading(type: .onyomi, reading: "こう", isPrimary: true, isAcceptedAnswer: true), Reading(type: .onyomi, reading: "く", isPrimary: true, isAcceptedAnswer: true), Reading(type: .kunyomi, reading: "くち", isPrimary: false, isAcceptedAnswer: false)])
        let industryKanji = createTestKanji(level: 1, characters: "工",
                                            meanings: [Meaning(meaning: "Construction", isPrimary: true, isAcceptedAnswer: true), Meaning(meaning: "Industry", isPrimary: false, isAcceptedAnswer: true)],
                                            readings: [Reading(type: .onyomi, reading: "こう", isPrimary: true, isAcceptedAnswer: true), Reading(type: .onyomi, reading: "く", isPrimary: true, isAcceptedAnswer: true)])
        let mountainVocab = createTestVocabulary(level: 1, characters: "山",
                                                 meanings: [Meaning(meaning: "Mountain", isPrimary: true, isAcceptedAnswer: true)],
                                                 readings: [Reading(type: nil, reading: "やま", isPrimary: true, isAcceptedAnswer: true)])
        let mouthVocab = createTestVocabulary(level: 1, characters: "口",
                                              meanings: [Meaning(meaning: "Mouth", isPrimary: true, isAcceptedAnswer: true)],
                                              readings: [Reading(type: nil, reading: "くち", isPrimary: true, isAcceptedAnswer: true)])
        let mountFujiVocab = createTestVocabulary(level: 1, characters: "ふじ山",
                                                  meanings: [Meaning(meaning: "Mt Fuji", isPrimary: true, isAcceptedAnswer: true), Meaning(meaning: "Mount Fuji", isPrimary: false, isAcceptedAnswer: true), Meaning(meaning: "Mt. Fuji", isPrimary: false, isAcceptedAnswer: true)],
                                                  readings: [Reading(type: nil, reading: "ふじさん", isPrimary: true, isAcceptedAnswer: true)])
        
        writeToDatabase([leafRadical, finsRadical, mountainKanji, mouthKanji, industryKanji, mountainVocab, mouthVocab, mountFujiVocab])
        
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "leaf"), [leafRadical.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "fins"), [finsRadical.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "やま"), [mountainVocab.id, mountainKanji.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "く"), [mouthVocab.id, mouthKanji.id, industryKanji.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "mouth"), [mouthVocab.id, mouthKanji.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "口"), [mouthVocab.id, mouthKanji.id])
        XCTAssertEqual(try resourceRepository.findSubjects(matching: "mount"), [mountainVocab.id, mountainKanji.id, mountFujiVocab.id])
    }
    
    private func createTestUser(currentVacationStartedAt: Date? = nil) {
        let user = UserInformation(id: "00000000-0000-0000-0000-000000000000",
                                   username: "Test",
                                   level: testUserLevel,
                                   profileURL: URL(string: "https://localhost/Test")!,
                                   startedAt: Date(),
                                   subscription: UserInformation.Subscription(isActive: true,
                                                                              type: "lifetime",
                                                                              maxLevelGranted: 60,
                                                                              periodEndsAt: nil),
                                   currentVacationStartedAt: currentVacationStartedAt)
        
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
    
    private func createTestAssignment(subjectType: SubjectType, srsStage: Int, unlockedAt: Date? = nil, availableAt: Date? = nil, resurrectedAt: Date? = nil, isPassed: Bool? = nil, subjectID: Int? = nil) -> ResourceCollectionItem {
        let item = ResourceCollectionItem(id: nextAssignmentID,
                                          type: .assignment,
                                          url: URL(string: "https://www.wanikani.com/api/v2/assignments/\(nextAssignmentID)")!,
                                          dataUpdatedAt: Date(),
                                          data: Assignment(createdAt: Date(),
                                                           subjectID: subjectID ?? nextSubjectID,
                                                           subjectType: subjectType,
                                                           srsStage: srsStage,
                                                           srsStageName: "",
                                                           unlockedAt: unlockedAt,
                                                           startedAt: nil,
                                                           passedAt: nil,
                                                           burnedAt: nil,
                                                           availableAt: availableAt,
                                                           resurrectedAt: resurrectedAt,
                                                           isPassed: isPassed ?? (srsStage >= SRSStage.guru.numericLevelRange.lowerBound),
                                                           isResurrected: resurrectedAt != nil,
                                                           isHidden: false))
        nextAssignmentID += 1
        if subjectID == nil { nextSubjectID += 1 }
        return item
    }
    
    private func createTestRadical(level: Int, characters: String? = nil, meanings: [Meaning] = []) -> ResourceCollectionItem {
        let item = ResourceCollectionItem(id: nextSubjectID,
                                          type: .radical,
                                          url: URL(string: "https://www.wanikani.com/api/v2/subjects/\(nextSubjectID)")!,
                                          dataUpdatedAt: Date(timeIntervalSinceReferenceDate: 0),
                                          data: Radical(createdAt: Date(timeIntervalSinceReferenceDate: 0),
                                                        level: level,
                                                        slug: "slug",
                                                        hiddenAt: nil,
                                                        documentURL: URL(string: "https://www.wanikani.com/radicals/slug")!,
                                                        characters: characters,
                                                        characterImages: [],
                                                        meanings: meanings,
                                                        auxiliaryMeanings: [],
                                                        amalgamationSubjectIDs: [],
                                                        meaningMnemonic: "",
                                                        lessonPosition: 0))
        nextSubjectID += 1
        return item
    }
    
    private func createTestRadicalWithAssignment(level: Int, characters: String? = nil, meanings: [Meaning] = [],
                                                 srsStage: Int, unlockedAt: Date? = nil, availableAt: Date? = nil, resurrectedAt: Date? = nil, isPassed: Bool? = nil) -> [ResourceCollectionItem] {
        let subject = createTestRadical(level: level, characters: characters, meanings: meanings)
        let assignment = createTestAssignment(subjectType: .radical, srsStage: srsStage, unlockedAt: unlockedAt, availableAt: availableAt, resurrectedAt: resurrectedAt, isPassed: isPassed, subjectID: subject.id)
        
        return [subject, assignment]
    }
    
    private func createTestKanji(level: Int, characters: String = "", meanings: [Meaning] = [], readings: [Reading] = []) -> ResourceCollectionItem {
        let item = ResourceCollectionItem(id: nextSubjectID,
                                          type: .kanji,
                                          url: URL(string: "https://www.wanikani.com/api/v2/subjects/\(nextSubjectID)")!,
                                          dataUpdatedAt: Date(timeIntervalSinceReferenceDate: 0),
                                          data: Kanji(createdAt: Date(timeIntervalSinceReferenceDate: 0),
                                                      level: level,
                                                      slug: "slug",
                                                      hiddenAt: nil,
                                                      documentURL: URL(string: "https://www.wanikani.com/kanji/\(characters.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)")!,
                                                      characters: characters,
                                                      meanings: meanings,
                                                      auxiliaryMeanings: [],
                                                      readings: readings,
                                                      componentSubjectIDs: [],
                                                      amalgamationSubjectIDs: [],
                                                      visuallySimilarSubjectIDs: [],
                                                      meaningMnemonic: "",
                                                      meaningHint: "",
                                                      readingMnemonic: "",
                                                      readingHint: "",
                                                      lessonPosition: 0))
        nextSubjectID += 1
        return item
    }
    
    private func createTestKanjiWithAssignment(level: Int, characters: String = "", meanings: [Meaning] = [], readings: [Reading] = [],
                                               srsStage: Int, unlockedAt: Date? = nil, availableAt: Date? = nil, resurrectedAt: Date? = nil, isPassed: Bool? = nil) -> [ResourceCollectionItem] {
        let subject = createTestKanji(level: level, characters: characters, meanings: meanings, readings: readings)
        let assignment = createTestAssignment(subjectType: .kanji, srsStage: srsStage, unlockedAt: unlockedAt, availableAt: availableAt, resurrectedAt: resurrectedAt, isPassed: isPassed, subjectID: subject.id)
        
        return [subject, assignment]
    }
    
    private func createTestVocabulary(level: Int, characters: String = "", meanings: [Meaning] = [], readings: [Reading] = []) -> ResourceCollectionItem {
        let item = ResourceCollectionItem(id: nextSubjectID,
                                          type: .vocabulary,
                                          url: URL(string: "https://www.wanikani.com/api/v2/subjects/\(nextSubjectID)")!,
                                          dataUpdatedAt: Date(timeIntervalSinceReferenceDate: 0),
                                          data: Vocabulary(createdAt: Date(timeIntervalSinceReferenceDate: 0),
                                                           level: level,
                                                           slug: "slug",
                                                           hiddenAt: nil,
                                                           documentURL: URL(string: "https://www.wanikani.com/vocabulary/\(characters.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)")!,
                                                           characters: characters,
                                                           meanings: meanings,
                                                           auxiliaryMeanings: [],
                                                           readings: readings,
                                                           partsOfSpeech: [],
                                                           componentSubjectIDs: [],
                                                           meaningMnemonic: "",
                                                           readingMnemonic: "",
                                                           contextSentences: [],
                                                           pronunciationAudios: [],
                                                           lessonPosition: 0))
        nextSubjectID += 1
        return item
    }
    
    private func createTestVocabularyWithAssignment(level: Int, characters: String = "", meanings: [Meaning] = [], readings: [Reading] = [],
                                                    srsStage: Int, unlockedAt: Date? = nil, availableAt: Date? = nil, resurrectedAt: Date? = nil, isPassed: Bool? = nil) -> [ResourceCollectionItem] {
        let subject = createTestVocabulary(level: level, characters: characters, meanings: meanings, readings: readings)
        let assignment = createTestAssignment(subjectType: .vocabulary, srsStage: srsStage, unlockedAt: unlockedAt, availableAt: availableAt, resurrectedAt: resurrectedAt, isPassed: isPassed, subjectID: subject.id)
        
        return [subject, assignment]
    }
    
    private func populateDatabaseForStudyQueue(lessonCount: Int = 0, pendingReviewCount: Int = 0, resurrectedReviewCount: Int = 0, futureReviewCount: Int = 0, futureReviewTime: Date? = nil) {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity((lessonCount + pendingReviewCount + futureReviewCount) * 2)
        
        let dateInPast = makeUTCDate(year: 2012, month: 2, day: 24, hour: 19, minute: 9, second: 18)
        
        for _ in 0..<lessonCount {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 0, unlockedAt: dateInPast)
        }
        
        for _ in 0..<pendingReviewCount {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 3, availableAt: dateInPast)
        }
        
        for _ in 0..<resurrectedReviewCount {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 3, availableAt: dateInPast, resurrectedAt: dateInPast)
        }

        for _ in 0..<futureReviewCount {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 3, availableAt: futureReviewTime!)
        }
        
        writeToDatabase(items)
    }
    
    private func populateDatabaseForLevelProgression(radicalsNotPassed: Int, radicalsPassed: Int, kanjiNotPassed: Int, kanjiPassed: Int) {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity((radicalsNotPassed + radicalsPassed + kanjiNotPassed + kanjiPassed) * 2)
        
        let now = Date()
        
        for _ in 0..<radicalsNotPassed {
            let radical = createTestRadical(level: testUserLevel)
            items.append(radical)
            if Bool.random() {
                items.append(createTestAssignment(subjectType: .radical, srsStage: 0, availableAt: now, isPassed: false, subjectID: radical.id))
            }
        }
        
        for _ in 0..<radicalsPassed {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: 4, availableAt: now, isPassed: true)
        }
        
        for _ in 0..<kanjiNotPassed {
            let kanji = createTestKanji(level: testUserLevel)
            items.append(kanji)
            if Bool.random() {
                items.append(createTestAssignment(subjectType: .kanji, srsStage: 0, availableAt: now, isPassed: false, subjectID: kanji.id))
            }
        }
        
        for _ in 0..<kanjiPassed {
            items += createTestKanjiWithAssignment(level: testUserLevel, srsStage: 4, availableAt: now, isPassed: true)
        }
        
        for _ in 0..<Int.random(in: 50...150) {
            items += createTestVocabularyWithAssignment(level: testUserLevel, srsStage: 1, availableAt: now, isPassed: false)
        }
        
        writeToDatabase(items)
    }
    
    private func populateDatabaseForSRSDistribution(srsStage: Int, radicals: Int, kanji: Int, vocabulary: Int) {
        var items = [ResourceCollectionItem]()
        items.reserveCapacity((radicals + kanji + vocabulary) * 2)
        
        let now = Date()
        
        for _ in 0..<radicals {
            items += createTestRadicalWithAssignment(level: testUserLevel, srsStage: srsStage, availableAt: now)
        }
        for _ in 0..<kanji {
            items += createTestKanjiWithAssignment(level: testUserLevel, srsStage: srsStage, availableAt: now)
        }
        for _ in 0..<vocabulary {
            items += createTestVocabularyWithAssignment(level: testUserLevel, srsStage: srsStage, availableAt: now)
        }
        
        writeToDatabase(items)
    }
    
    private func writeToDatabase(_ items: [ResourceCollectionItem]) {
        databaseManager.databaseQueue!.inExclusiveTransaction { (database, rollback) in
            do {
                for item in items {
                    try item.write(to: database)
                }
                try Set(items.map { $0.type }).forEach { type in
                    switch type {
                    case .radical, .kanji, .vocabulary:
                        try ResourceType.subjects.setLastUpdateDate(Date(), in: database)
                    case .assignment:
                        try ResourceType.assignments.setLastUpdateDate(Date(), in: database)
                    case .levelProgression:
                        try ResourceType.levelProgression.setLastUpdateDate(Date(), in: database)
                    case .reviewStatistic:
                        try ResourceType.reviewStatistics.setLastUpdateDate(Date(), in: database)
                    case .studyMaterial:
                        try ResourceType.studyMaterials.setLastUpdateDate(Date(), in: database)
                    }
                }
            } catch {
                rollback.pointee = true
                XCTFail("Failed to create test items: \(error)")
            }
        }
    }
    
}
