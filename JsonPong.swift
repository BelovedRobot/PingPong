////
////  JsonPong.swift
////  PingPong
////
////  Created by Zane Kellogg on 12/3/18.
////
//
//import Foundation
//
//open class JsonPong {
//
//    static public func toJSON(object : Syncable) -> String {
//        do {
//            let encoder = JSONEncoder()
//            let encodedData = try encoder.encode(object)
//
//            guard let jsonString = String(data: encodedData, encoding: .utf8) else {
//                print("Encoding object type \(type(of: self)) failed")
//                return ""
//            }
//
//            return jsonString
//        } catch {
//            print("Encoding object type \(type(of: self)) failed")
//            return ""
//        }
//    }
//
//}
