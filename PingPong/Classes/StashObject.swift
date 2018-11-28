//
//  StashObject.swift
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

open class StashObject : JsonObject {
    
    public init(docType : String = "") {
        // If docType is empty string then log
        if (docType == "") {
            print("PingPong: docType must be provided on type \(type(of: self))")
        }
        
        self.docType = docType
    }
    
    @objc public var id : String = "" // Every stash object is required to have an id
    @objc public let docType : String // Every stash object must have a docType
    
    open func stash() {
        let jsonString = self.toJSON()
        DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
    }
    
    public class func stashAll(objects: [StashObject]) -> Bool{
        return DataStore.sharedDataStore.stashObjects(objects:objects)
    }
    
    // This is essentially an override for stash where only a single instance of this document should exist in the DB at a time
    public func stashSingle(docType : String) -> Bool {
        var shouldStash = false
        
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        // Query the datastore for existing receipt validation tasks
        DataStore.sharedDataStore.queryDocumentStore(parameters: ("docType", docType)) { results in
            // If none are found then stash current
            if (results.count == 0) {
                shouldStash = true
            }
            sema.signal()
        }
        
        sema.wait()
        
        if (shouldStash) {
            stash()
        }
        
        return shouldStash
    }
    
    public func refresh() {
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        DataStore.sharedDataStore.retrieveDocumentJSON(id: self.id) { (result : String?) in
            if let json = result {
                self.fromJSON(json: json)
            }
            sema.signal()
        }
        
        sema.wait()
    }
    
    public func hasChangedFromStash() -> Bool {
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        // "Assume" the model has changed, it's better to sync too often than not often enough
        var hasChanged : Bool = true
        
        DataStore.sharedDataStore.retrieveDocumentJSON(id: self.id) { (result : String?) in
            if let stashJson = result {
                
                let currentJson = self.toJSON()
                hasChanged = (currentJson != stashJson)
                
                sema.signal()
            }
        }
        
        sema.wait()
        
        return hasChanged
    }
}
