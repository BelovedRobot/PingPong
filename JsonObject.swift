//
//  JsonObject.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class JsonObject : NSObject {
    var deserializationExceptions : Dictionary<String, JSON> = Dictionary<String, JSON>() // This is a container used to store properties and values when they can't be de-serialized
    
    // MARK: Serialize to JSON
    
    // Convert object to JSON String
    
    final func toJSON() -> String {
        do {
            let dict = try self.mirrorObjectToDict(self)
//            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)
            let data = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.init(rawValue: 0))
            return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
            
        } catch {
            print("There was an error serializing the object to json. -> \(error)")
            return ""
        }
    }
    
    // Convert object to Dictionary<String, AnyObject> that can be converted to JSON
    final func toDictionary() -> Dictionary<String, AnyObject>? {
        do {
            return try self.mirrorObjectToDict(self)
        } catch {
            print("There was an error serializing the object to json-able dictionary. -> \(error)")
            return nil
        }
    }
    
    private func mirrorObjectToDict(object : Any) throws -> Dictionary<String, AnyObject> {
        // Create mirror of self
        let mirror = Mirror(reflecting: object)
        
        guard (mirror.displayStyle == .Class)
            else { throw SyncObjectError.SerializationErrorUnsupportedType }
        
        var dict = Dictionary<String, AnyObject>();
        
        // Iterate over children and serialize each
        for case let (label?, anyValue) in mirror.children {
            // String
            if let value = anyValue as? NSString {
                dict[label] = value
                // Number
            } else if let value = anyValue as? NSNumber {
                dict[label] = value
                // Null
            } else if let value = anyValue as? NSNull {
                dict[label] = value
                // Array
            } else if let value = anyValue as? NSArray {
                // Loop through elements and reflect on each (only handles array of Strings or Objects
                var children = [AnyObject]()
                for childItem in value {
                    // String
                    if let childValue = childItem as? NSString {
                        children.append(childValue)
                    } else {
                        // Object
                        do {
                            let childDict = try self.mirrorObjectToDict(childItem)
                            children.append(childDict)
                        } catch {
                            // Ignore children error (ie do not throw again)
                            print("Child property '\(label)' can not be serialized...skipping.")
                        }
                    }
                }
                dict[label] = children
                // Class or Struct
            } else if let value = anyValue as? AnyObject {
                // Reflect on child
                do {
                    let childDict = try self.mirrorObjectToDict(value)
                    dict[label] = childDict
                } catch {
                    // Ignore children error (ie do not throw again)
                    print("Child property '\(label)' can not be serialized...skipping.")
                }
            } else if let value = anyValue as? JsonObject {
                // For non-optional types the object will go through dictionary mirror handler, otherwise optionals end-up here
                let childDict = value.toDictionary()
                dict[label] = childDict
            } else {
                print("Child property '\(label)' can not be serialized...skipping.")
            }
        }
        
        // Mirror the superclass to get the id
        for case let (label?, anyValue) in mirror.superclassMirror()!.children {
            if label == "id" {
                if let value = anyValue as? NSString {
                    dict[label] = value
                }
            }
        }
        
        // Mirror the superclass of the superclass to get the id
        if let superSuperClassMirror = mirror.superclassMirror()!.superclassMirror() {
            for case let (label?, anyValue) in superSuperClassMirror.children {
                if label == "id" {
                    if let value = anyValue as? NSString {
                        dict[label] = value
                    }
                }
            }
        }
        
        return dict;
    }
    
    // MARK: De-serialize from JSON
    
    // Init object with json string
    func fromJSON(json : String) {
        self.fromSwiftyJSON(JSON.parse(json))
    }
    
    private func fromSwiftyJSON(json : JSON) {
        for (key, value) in json {
            // If the property exists, then proceed
            if (self.respondsToSelector(NSSelectorFromString(key))) {

                // If it is a string
                if let stringVal = value.string {
                    self.setValue(stringVal, forKey: key)
                // If it is a double
                } else if let intVal = value.double {
                    self.setValue(intVal, forKey: key)
                // If it is an int
                } else if let intVal = value.int {
                    self.setValue(intVal, forKey: key)
                // If it is a bool
                } else if let boolVal = value.bool {
                    self.setValue(boolVal, forKey: key)
                } else {
                    // Add it to the exceptions list
                    self.deserializationExceptions[key] = value
                }
            }
        }
    }

//    Convert a child dictionary is that when you set the key it keeps it as a Dictionary rather than the actual type it should be
//    private func convertSubJsonToDictionary(subJson : [String : JSON]) -> Dictionary<String, AnyObject> {
//        var childDict = [String : AnyObject]()
//
//        for (key, value) in subJson {   
//            // If it is a string
//            if let stringVal = value.string {
//                childDict[key] = stringVal
//                // If it is a double
//            } else if let intVal = value.double {
//                childDict[key] = intVal
//                // If it is an int
//            } else if let intVal = value.int {
//                childDict[key] = intVal
//                // If it is a bool
//            } else if let boolVal = value.bool {
//                childDict[key] = boolVal
//            } else if let childVal = value.dictionary {
//                let subChildDict = self.convertSubJsonToDictionary(childVal)
//                childDict[key] = subChildDict
//            }
//        }
//        return childDict
//    }
    
//    // An alternative to init with json string, the input 'object' is expected to be a NSDictionary
//    func fromDictionary(object : AnyObject) {
//        if let jsonDictionary = object as? NSDictionary {
//            for (key, value) in jsonDictionary {
//                let keyName = key as! String
//                
//                // If the value is of type Dictionary or Array skip and force an override
//                if let valueDict = value as? NSDictionary {
//                    // Store for further serialization
//                    self.deserializationExceptions[keyName] = valueDict
//                } else if let valueArray = value as? NSArray {
//                    // Store for further serialization
//                    self.deserializationExceptions[keyName] = valueArray
//                } else if (self.respondsToSelector(NSSelectorFromString(keyName))) {
//                    // Property exists, test for type
//                    if let stringValue = value as? String {
//                        self.setValue(stringValue, forKey: keyName)
//                    } else if let numberValue = value as? NSNumber {
//                        self.setValue(numberValue, forKey: keyName)
//                    }
//                } else {
//                    // Store for further serialization
//                    self.deserializationExceptions[keyName] = value
//                }
//            }
//        }
//    }
}