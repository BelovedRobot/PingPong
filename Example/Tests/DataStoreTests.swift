//
//  DataStoreTests.swift
//  PingPong_Example
//
//  Created by Zane Kellogg on 11/24/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import PingPong

class DataStoreTests : XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Init the data store
        let _ = DataStore.sharedDataStore
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
        // Reset the database
        DataStore.sharedDataStore.resetDatabase()
    }
    
    func testDatabaseCreated() {
        let appDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = "\(appDir)/\(DataStore.databaseName)"
        
        XCTAssert(FileManager.default.fileExists(atPath: dbPath))
    }
    
    func testStash() {
        let stashObject = TestObject(docType: "testObject")
        stashObject.aString = "Hello world"
        stashObject.aDateString = "2008-09-15T15:53:00"
        stashObject.aInt = 100
        
        stashObject.stash()
        
        let result = DataStore.sharedDataStore.retrieveDocumentJSONSynchronous(id: stashObject.id)
        
        XCTAssertNotNil(result)
    }
    
    func testReset() {
        let stashObject = TestObject(docType: "testObject")
        stashObject.id = "stashObject"
        stashObject.aString = "Hello world"
        stashObject.aDateString = "2008-09-15T15:53:00"
        stashObject.aInt = 100

        stashObject.stash()
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: stashObject.id)

        let stashObject2 = TestObject(docType: "testObject")
        stashObject2.id = "stashObject2"
        stashObject2.aString = "Hello world"
        stashObject2.aDateString = "2008-09-15T15:53:00"
        stashObject2.aInt = 100

        stashObject2.stash()
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: stashObject2.id)

        // Create expectation to retrieve documents
        let expectation = XCTestExpectation(description: "Get queued objects")

        DataStore.sharedDataStore.retrieveQueuedDocuments { queuedDocuments in
            XCTAssert(queuedDocuments.count == 2, "Documents Not queued")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)

        // Reset the database
        DataStore.sharedDataStore.resetDatabase()

        let expectation2 = XCTestExpectation(description: "Get documents after reset")
        DataStore.sharedDataStore.queryDocumentStore(query: "SELECT * FROM documents;") { results in
            XCTAssert(results.count == 0, "Documents Not Deleted")
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 10.0)

        let expectation3 = XCTestExpectation(description: "Get queued objects after reset")
        DataStore.sharedDataStore.retrieveQueuedDocuments { queuedDocs in
            XCTAssert(queuedDocs.count == 0, "Documents Not Deleted")
            expectation3.fulfill()
        }

        wait(for: [expectation3], timeout: 10.0)
    }
}
