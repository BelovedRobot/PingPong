import XCTest
import PingPong

class SyncObjectTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        print("Warning: These tests depend on a local instance of the PingPongEndpoint running on port 8282")
        print("For more info, see: https://github.com/BelovedRobot/PingPongEndpoint")
        
        // Init the data store
        let _ = DataStore.sharedDataStore
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Reset the database
        DataStore.sharedDataStore.resetDatabase()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
