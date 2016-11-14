//
//  StashObject.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class StashObject : JsonObject {
    
    required override init() {
        super.init()
    }
    
    var id : String = "" // Every sync object is required to have an id
    
    func stash() {
        let jsonString = self.toJSON()
        DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
    }
    
    // This is essentially an override for stash where only a single instance of this document should exist in the DB at a time
    func stashSingle(docType : String) -> Bool {
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
    
    func refresh() {
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        DataStore.sharedDataStore.retrieveDocumentJSON(id: self.id) { (result : String?) in
            if let json = result {
                self.fromJSON(json: json)
                sema.signal()
            }
        }
        
        sema.wait()
    }
    
    func hasChangedFromStash() -> Bool {
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
