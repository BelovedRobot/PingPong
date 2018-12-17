//
//  TestObject.swift
//  PingPong_Example
//
//  Created by Zane Kellogg on 12/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import PingPong

class TestObject : Syncable {
    var docType: String
    var id: String = ""
    var synced: Bool = false
    var deleted: Bool = false
    var aString: String = ""
    var aDateString: String = ""
    var aInt : Int?
    var aBool : Bool?
    
    required init(docType: String) {
        self.docType = docType
    }
    
//    func toJSON() -> String? {
//        do {
//            let encoder = JSONEncoder()
//            let encodedData = try encoder.encode(self)
//
//            guard let jsonString = String(data: encodedData, encoding: .utf8) else {
//                print("Encoding object type \(type(of: self)) failed")
//                return nil
//            }
//
//            return jsonString
//        } catch {
//            print("Encoding object type \(type(of: self)) failed")
//            return nil
//        }
//    }

//    func fromJSON(json: String) -> Syncable? {
//        guard let jsonData = json.data(using: .utf8) else {
//            print("Failed to decode from json")
//            return nil
//        }
//
//        do {
//            let decoder = JSONDecoder()
//            let instance = try decoder.decode(TestObject.self, from: jsonData)
//
//            return instance
//        } catch {
//            print("Failed to decode from json")
//            return nil
//        }
//    }
}
