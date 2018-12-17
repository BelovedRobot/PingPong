//
//  TestJsonSerialization.swift
//  PingPong_Example
//
//  Created by Zane Kellogg on 12/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

class JsonSerializationTests : XCTestCase {
    
    func testToJson() {
        // Create the obj
        let obj = TestObject(docType: "testObject")
        obj.aString = "Hello World"
        obj.aInt = 100
        obj.aBool = false
        obj.id = "anIdentifier"
        obj.synced = true
        obj.aDateString = ""
        
        // Serialize it into JSON
        let json = obj.toJSON()
        
        XCTAssert(json != nil)
        XCTAssert(json! == "{\"synced\":true,\"aInt\":100,\"deleted\":false,\"id\":\"anIdentifier\",\"aBool\":false,\"aString\":\"Hello World\",\"docType\":\"testObject\",\"aDateString\":\"\"}")
    }
    
    func testFromJson() {
        // Set the json
        let json =
        """
        {
            "docType" : "testObject",
            "id" : "anotherIdentifier",
            "aBool" : true,
            "synced" : true,
            "aString" : "Hello World",
            "aInt" : 1000,
            "aDateString" : "",
            "deleted" : false
        }
        """

        let obj = TestObject.fromJSON(target: TestObject.self, json: json)
        
        XCTAssert(obj != nil)
        XCTAssert(obj?.docType == "testObject")
        XCTAssert(obj?.id == "anotherIdentifier")
        XCTAssert(obj?.aBool == true)
        XCTAssert(obj?.synced == true)
        XCTAssert(obj?.aString == "Hello World")
        XCTAssert(obj?.aInt == 1000)
    }
}
