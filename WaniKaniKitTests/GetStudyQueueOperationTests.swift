//
//  GetStudyQueueOperationTests.swift
//  WaniKaniKit
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import XCTest
import OHHTTPStubs
import OperationKit
@testable import WaniKaniKit

class GetStudyQueueOperationTests: DatabaseTestCase, ResourceHTTPStubs {
    
    func testBadAPIKey() {
        stubRequest(for: .studyQueue, file: "Bad API Key")
        defer { OHHTTPStubs.removeAllStubs() }
        
        let expect = expectation(description: "studyQueue")
        let operationQueue = OperationKit.OperationQueue()
        let operation = GetStudyQueueOperation(resolver: resourceResolver, databaseQueue: databaseQueue)
        
        let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
            defer { expect.fulfill() }
            XCTAssertEqual(errors.count, 1, "Expected exactly one error, but received: \(errors)")
            if let error = errors.first {
                switch error {
                case WaniKaniAPIError.userNotFound: break
                default:
                    XCTFail("Expected single WaniKaniAPIError.UserNotFound error, but got \(error)")
                }
            }
        })
        operation.addObserver(completionObserver)
        operationQueue.addOperation(operation)
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
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
                                                      creationDate: Date(timeIntervalSince1970: TimeInterval(1402558829)))
        
        let expectedStudyQueue = StudyQueue(lessonsAvailable: 29,
                                            reviewsAvailable: 8,
                                            nextReviewDate: Date(timeIntervalSince1970: TimeInterval(1438180831)),
                                            reviewsAvailableNextHour: 0,
                                            reviewsAvailableNextDay: 19)
        
        let operationQueue = OperationKit.OperationQueue()
        
        stubRequest(for: .studyQueue, file: "Study Queue Success")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measure() {
            let expect = self.expectation(description: "studyQueue")
            let operation = GetStudyQueueOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
        let userInformation = try! databaseQueue.withDatabase { try UserInformation.coder.load(from: $0) }
        XCTAssertEqual(userInformation, expectedUserInformation, "UserInformation mismatch from database")
        
        let studyQueue = try! databaseQueue.withDatabase { try StudyQueue.coder.load(from: $0) }
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
                                                      creationDate: Date(timeIntervalSince1970: TimeInterval(1435328490)))
        
        let expectedStudyQueue = StudyQueue(lessonsAvailable: 26,
                                            reviewsAvailable: 0,
                                            reviewsAvailableNextHour: 0,
                                            reviewsAvailableNextDay: 0)
        
        let operationQueue = OperationKit.OperationQueue()
        
        stubRequest(for: .studyQueue, file: "Study Queue New User")
        defer { OHHTTPStubs.removeAllStubs() }
        
        self.measure() {
            let expect = self.expectation(description: "studyQueue")
            let operation = GetStudyQueueOperation(resolver: self.resourceResolver, databaseQueue: self.databaseQueue)
            
            let completionObserver = BlockObserver(finishHandler: { (operation, errors) -> Void in
                defer { expect.fulfill() }
                XCTAssertEqual(errors.count, 0, "Expected no errors, but received: \(errors)")
            })
            operation.addObserver(completionObserver)
            operationQueue.addOperation(operation)
            
            self.waitForExpectations(timeout: 5.0, handler: nil)
        }
        
        let userInformation = try! databaseQueue.withDatabase { try UserInformation.coder.load(from: $0) }
        XCTAssertEqual(userInformation, expectedUserInformation, "UserInformation mismatch from database")
        
        let studyQueue = try! databaseQueue.withDatabase { try StudyQueue.coder.load(from: $0) }
        XCTAssertEqual(studyQueue, expectedStudyQueue, "StudyQueue mismatch from database")
    }
    
}
