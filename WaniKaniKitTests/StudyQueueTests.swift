//
//  SRSDataItemTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
@testable import WaniKaniKit

class StudyQueueTests: XCTestCase {
    
    func testReviewDateSameDaySameTime() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let nextReviewDate = date(2015, 1, 1, 12, 34, 30)

        let studyQueue = StudyQueue(lessonsAvailable: 1, reviewsAvailable: 0, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        let formattedNextReviewDate = studyQueue.formattedNextReviewDate(referenceDate)
        XCTAssertEqual(formattedNextReviewDate, formatTimeOnly(nextReviewDate))
    }
    
    func testReviewDateSameDayDifferentTime() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let nextReviewDate = date(2015, 1, 1, 18, 15, 0)
        
        let studyQueue = StudyQueue(lessonsAvailable: 1, reviewsAvailable: 0, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        let formattedNextReviewDate = studyQueue.formattedNextReviewDate(referenceDate)
        XCTAssertEqual(formattedNextReviewDate, formatTimeOnly(nextReviewDate))
    }
    
    func testReviewDateNextDayMidnight() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let nextReviewDate = date(2015, 1, 2, 0, 0, 0)
        
        let studyQueue = StudyQueue(lessonsAvailable: 1, reviewsAvailable: 0, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        let formattedNextReviewDate = studyQueue.formattedNextReviewDate(referenceDate)
        XCTAssertEqual(formattedNextReviewDate, formatDateTime(nextReviewDate))
    }
    
    func testReviewDateNextDaySameTime() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let nextReviewDate = date(2015, 1, 2, 12, 34, 30)
        
        let studyQueue = StudyQueue(lessonsAvailable: 1, reviewsAvailable: 0, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        let formattedNextReviewDate = studyQueue.formattedNextReviewDate(referenceDate)
        XCTAssertEqual(formattedNextReviewDate, formatDateTime(nextReviewDate))
    }
    
    func testReviewDateNextDayDifferentTime() {
        let referenceDate = date(2015, 1, 1, 12, 34, 30)
        let nextReviewDate = date(2015, 1, 2, 18, 15, 0)
        
        let studyQueue = StudyQueue(lessonsAvailable: 1, reviewsAvailable: 0, nextReviewDate: nextReviewDate, reviewsAvailableNextHour: 0, reviewsAvailableNextDay: 0)
        let formattedNextReviewDate = studyQueue.formattedNextReviewDate(referenceDate)
        XCTAssertEqual(formattedNextReviewDate, formatDateTime(nextReviewDate))
    }
    
    private func formatDateTime(date: NSDate) -> String {
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
    }
    
    private func formatTimeOnly(date: NSDate) -> String {
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .NoStyle, timeStyle: .ShortStyle)
    }
    
}
