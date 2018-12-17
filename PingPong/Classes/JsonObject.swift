//
//  JsonObject.swift
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

extension Syncable {
    public func toJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(self)
            
            guard let jsonString = String(data: encodedData, encoding: .utf8) else {
                print("Encoding object type \(type(of: self)) failed")
                return nil
            }
            
            return jsonString
        } catch {
            print("Encoding object type \(type(of: self)) failed")
            return nil
        }
    }
    
    public static func fromJSON<T: Codable>(target : T.Type, json: String) -> T? {
        guard let jsonData = json.data(using: .utf8) else {
            print("Failed to decode from json")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let instance = try decoder.decode(target, from: jsonData)
            
            return instance
        } catch {
            print("Failed to decode from json")
            return nil
        }
    }
}
