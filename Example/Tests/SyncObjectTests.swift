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
    
    func testPostObject() {
        // Create expectation to post object
        let expectation = XCTestExpectation(description: "Post Object")
        
        // Post the object by manually running sync logic
        let syncObj = TestSyncObject()
        syncObj.aString = "Hello world"
        syncObj.aNumber = 100
        syncObj.aDateString = "2008-09-15T15:53:00"

        syncObj.backgroundSync { success in
            XCTAssert(syncObj.synced, "The object is not synced")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
}
