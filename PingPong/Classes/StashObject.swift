//
//  StashObject.swift
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

extension Syncable {
    public func stash() {
        guard let jsonString = self.toJSON() else {
            return
        }
        DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't overwrite local queued changes
    public func safeStash() {
        if !self.hasPendingSync() {
            guard let jsonString = self.toJSON() else {
                return
            }
            DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
        }
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't delete local queued changes, oftentimes when we fetch a large set of data we will delete existing data to ensure that objects deleted elsewhere are reflected. This is a safe way to do it.
    public func safeDelete() {
        if !self.hasPendingSync() {
            DataStore.sharedDataStore.deleteDocument(id: self.id)
        }
    }
    
    // This is essentially an override for stash where only a single instance of this document type should exist in the DB at a time
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
    
    public func hasPendingSync() -> Bool {
        return DataStore.sharedDataStore.hasPendingSync(documentId: self.id);
    }
}
