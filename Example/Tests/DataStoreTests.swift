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
        let stashObject = TestStashObject()
        stashObject.aString = "Hello world"
        stashObject.aDateString = "2008-09-15T15:53:00"
        stashObject.aNumber = 100
        
        stashObject.stash()
        
        let result = DataStore.sharedDataStore.retrieveDocumentJSONSynchronous(id: stashObject.id)
        
        XCTAssertNotNil(result)
    }
}
