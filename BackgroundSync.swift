//
//  BackgroundSync.swift
//  Deshazo
//
//  Created by Zane Kellogg on 7/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class BackgroundSync {
    
    static let shared : BackgroundSync = BackgroundSync()
    private var queue : OperationQueue;
    private var secondsInterval : Int = 0
    private var timer : Timer?
    
    init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1 // Serial Queue
    }
    
    func start(secondsInterval : Int) {
        self.secondsInterval = secondsInterval
        self.scheduleTimer(seconds: 5) // First pass refreshes after 5 seconds
    }
    
    func stop() {
        if let validTimer = self.timer {
            validTimer.invalidate()
        }
    }
    
    private func scheduleTimer(seconds : Int) {
        let secondsDouble = Double(seconds)
        let selector = #selector(self.timerFired(timer:))
        timer = Timer.scheduledTimer(timeInterval: secondsDouble, target: self, selector: selector, userInfo: nil, repeats: false)
    }
    
    @objc private func timerFired(timer : Timer) {
        let someWork : ()->() = {
            print("Background Sync Fired -> \(Date().toISOString())")
            self.sync()
        }
        queue.addOperation(someWork);
        
        // Schedule more work
        self.scheduleTimer(seconds: self.secondsInterval)
    }
    
    func sync() {
        // Is there a network connection
        guard PingPong.shared.isEndpointReachable else {
            return
        }
        
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        // Get all Document Ids to Sync
        var results : [String]?
        DataStore.sharedDataStore.retrieveQueuedDocuments { (dataResults) in
            results = dataResults
            sema.signal()
        }
        
        sema.wait()
        
        // Get list of document sync tasks
        let syncTaskDictionary = self.getDocumentSyncTasksDictionary()
        
        if let jsonDocuments = results {
            // For each document
            for json in jsonDocuments {
                let type = JSON.parse(json)["docType"].stringValue
                let id = JSON.parse(json)["id"].stringValue
                
                // The success for each type of document is to remove itself from the sync queue
                let success = {
                    DataStore.sharedDataStore.removeDocumentFromSyncQueue(documentId: id)
                }
                
                // Based on type, de-serialize from JSON in order to save
                switch(type) {
                case "fileUpload":
                    let fileUpload = FileUpload()
                    fileUpload.fromJSON(json: json)
                    PingPong.shared.uploadFile(fileUpload: fileUpload, callback: success)
                case "fileDelete":
                    let fileDelete = FileDelete()
                    fileDelete.fromJSON(json: json)
                    PingPong.shared.deleteFile(fileDelete: fileDelete, callback: success)
                default:
                    // Does the docType has a custom sync task
                    if let syncTask = syncTaskDictionary[type] {
                        // Execute the custom sync operation and pass the success callback
                        syncTask.sync(jsonString: json, success: success)
                    } else {
                        // By Default sync the document
                        PingPong.shared.saveDocumentToCloud(jsonString: json, success: success)
                    }
                }
            }
        }
        
        // Get list of automatic sync tasks and execute
        let autoSyncTasks = PingPong.shared.syncTasks.filter({ $0.automaticTask })
        for task in autoSyncTasks {
            task.sync(jsonString: nil, success: nil)
        }
        
        // Delete any orphanced records in the sync queue, there is a byproduct of the sync options in which they clean up their own records but 
        // the sync queue record may remain
        DataStore.sharedDataStore.removeOrphanedSyncQueueEntries()
    }
    
    // Helpers
    private func getDocumentSyncTasksDictionary() -> [String : SyncTask] {
        // This dictionary represents syncTasks indexed by their document type
        var syncTasksDictionary : [String : SyncTask] = [String : SyncTask]()
        
        for task in PingPong.shared.syncTasks.filter({ $0.docType != nil && $0.docType != "" }) {
            syncTasksDictionary[task.docType!] = task
        }
        
        return syncTasksDictionary
    }
}
