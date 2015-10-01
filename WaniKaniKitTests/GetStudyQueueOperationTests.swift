//
//  GetStudyQueueOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OperationKit
@testable import WaniKaniKit

class GetStudyQueueOperationTests: DatabaseTestCase {
    
    func testBadAPIKey() {
        let resourceResolver = TestFileResourceResolver(fileName: "Bad API Key")
        let expect = expectationWithDescription("studyQueue")
        let operationQueue = OperationQueue()
        let operation = GetStudyQueueOperation(resolver: resourceResolver, databaseQueue: databaseQueue)
        
        let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
            defer { expect.fulfill() }
            XCTAssertEqual(errors.count, 1, "Expected exactly one error, but received: \(errors)")
            if let error = errors.first {
                switch error {
                case WaniKaniAPIError.UserNotFound: break
                default:
                    XCTFail("Expected single WaniKaniAPIError.UserNotFound error, but got \(error)")
                }
            }
        })
        operation.addObserver(completionObserver)
        operationQueue.addOperation(operation)
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testStudyQueueSuccess() {
        let expectedUserInformation = UserInformation(username: "cplaverty",
            gravatar: "2dfa6bb295e1b554bf9dc29601a5963b",
            level: 2,
            title: "Turtles",
            about: "",
            twitter: "",
            topicsCount: 0,
            postsCount: 4,
            creationDate: NSDate(timeIntervalSince1970: NSTimeInterval(1402558829)))
        
        let expectedStudyQueue = StudyQueue(lessonsAvailable: 29,
            reviewsAvailable: 8,
            nextReviewDate: NSDate(timeIntervalSince1970: NSTimeInterval(1438180831)),
            reviewsAvailableNextHour: 0,
            reviewsAvailableNextDay: 19)
        
        let resourceResolver = TestFileResourceResolver(fileName: "Study Queue Success")
        let operationQueue = OperationQueue()

        self.measureBlock() {
            let expect = self.expectationWithDescription("studyQueue")
            let operation = GetStudyQueueOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(5.0, handler: nil)
        }
        
        let userInformation = try! databaseQueue.withDatabase { try UserInformation.coder.loadFromDatabase($0) }
        XCTAssertEqual(userInformation, expectedUserInformation, "UserInformation mismatch from database")
        
        let studyQueue = try! databaseQueue.withDatabase { try StudyQueue.coder.loadFromDatabase($0) }
        XCTAssertEqual(studyQueue, expectedStudyQueue, "StudyQueue mismatch from database")
    }
    
    func testStudyQueueNewUser() {
        let expectedUserInformation = UserInformation(username: "Keitai",
            gravatar: "19755999fa6df12050758baecec67db8",
            level: 1,
            title: "Guppies",
            about: "",
            topicsCount: 0,
            postsCount: 0,
            creationDate: NSDate(timeIntervalSince1970: NSTimeInterval(1435328490)))
        
        let expectedStudyQueue = StudyQueue(lessonsAvailable: 26,
            reviewsAvailable: 0,
            reviewsAvailableNextHour: 0,
            reviewsAvailableNextDay: 0)
        
        let resourceResolver = TestFileResourceResolver(fileName: "Study Queue New User")
        let operationQueue = OperationQueue()

        self.measureBlock() {
            let expect = self.expectationWithDescription("studyQueue")
            let operation = GetStudyQueueOperation(resolver: resourceResolver, databaseQueue: self.databaseQueue)

            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectationsWithTimeout(5.0, handler: nil)
        }

        let userInformation = try! databaseQueue.withDatabase { try UserInformation.coder.loadFromDatabase($0) }
        XCTAssertEqual(userInformation, expectedUserInformation, "UserInformation mismatch from database")
        
        let studyQueue = try! databaseQueue.withDatabase { try StudyQueue.coder.loadFromDatabase($0) }
        XCTAssertEqual(studyQueue, expectedStudyQueue, "StudyQueue mismatch from database")
    }

}
