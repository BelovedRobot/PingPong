import XCTest
import PingPong

class SyncObjectTests: XCTestCase {

    private let documentEndpoint = "http://localhost:8282/api"

    override func setUp() {
        super.setUp()

        print("Warning: These tests depend on a local instance of the PingPongEndpoint running on port 8282")
        print("For more info, see: https://github.com/BelovedRobot/PingPongEndpoint")

        // Set the document endpoint on PingPong
        PingPong.shared.documentEndpoint = documentEndpoint
        PingPong.shared.authorizationToken = "someTokenValue"

        // Init the data store
        let _ = DataStore.sharedDataStore
    }

    override func tearDown() {
        super.tearDown()

        // Reset the database
        DataStore.sharedDataStore.resetDatabase()
    }

    func testPostAndDelete() {
        // Create expectation to post object
        let expectation = XCTestExpectation(description: "Post Object")

        // Post the object by manually running sync logic
        let syncObj = TestObject(docType: "testObject")
        syncObj.aString = "Hello world"
        syncObj.aInt = 100
        syncObj.aDateString = "2008-09-15T15:53:00"
        syncObj.id = "anIdentifier"
        
        syncObj.backgroundSync { success in
            XCTAssert(success, "The sync was not a success")
            XCTAssert(syncObj.synced, "The object is not synced")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Now delete the object
        syncObj.deleted = true
        
        let expectation2 = XCTestExpectation(description: "Delete Object")
        syncObj.backgroundSync { success in
            XCTAssert(success, "The delete was not a success")
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 10.0)
        
        
    }
    
    func testPostFailure() {
        // Create expectation to post object
        let expectation = XCTestExpectation(description: "Post Object")
        
        // Post the object by manually running sync logic
        let syncObj = TestObject(docType: "testObject")
        syncObj.aString = "Hello world"
        syncObj.aInt = 100
        syncObj.aDateString = "2008-09-15T15:53:00"
        
        // Remove the doc type forcing a failure
        syncObj.docType = ""
        
        syncObj.backgroundSync { success in
            XCTAssert(success == false, "The sync was supposed to fail")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

}
