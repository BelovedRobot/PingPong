//
//  StashObject.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class StashObject : JsonObject {
    
    override init() {
        self.id = ""
        super.init()
    }
    
    var id : String; // Every sync object is required to have an id
    
    func stash() {
        let jsonString = self.toJSON()
        DataStore.sharedDataStore.stashDocument(jsonString)
    }
    
    func refresh() {
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        DataStore.sharedDataStore.retrieveDocumentJSON(self.id) { (result : String?) in
            if let json = result {
                self.fromJSON(json)
                dispatch_semaphore_signal(sema)
            }
        }
        
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
    }
    
    func hasChangedFromStash() -> Bool {
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        // "Assume" the model has changed, it's better to sync too often than not often enough
        var hasChanged : Bool = true
        
        DataStore.sharedDataStore.retrieveDocumentJSON(self.id) { (result : String?) in
            if let stashJson = result {
                
                let currentJson = self.toJSON()
                hasChanged = (currentJson != stashJson)
                
                dispatch_semaphore_signal(sema)
            }
        }
        
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
        
        return hasChanged
    }
    
    private func retrieve(id : String, callback : (() -> ())?) {
        DataStore.sharedDataStore.retrieveDocumentJSON(id) { (result : String?) in
            if let json = result {
                self.fromJSON(json)
                if let callableCallback = callback {
                    callableCallback()
                }
            }
        }
    }
}