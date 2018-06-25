//
//  BackgroundSync.swift
//
//  Created by Zane Kellogg on 7/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

public class BackgroundSync {
    
    static let shared : BackgroundSync = BackgroundSync()
    private var queue : OperationQueue
    private var secondsInterval : Int = 0
    private var timer : Timer?
    private var isSyncing : Bool = false
    
    private init() {
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1 // Serial Queue
    }
    
    public func start(secondsInterval : Int) {
        self.secondsInterval = secondsInterval
        self.scheduleTimer(seconds: secondsInterval) // First pass refreshes after 5 seconds
    }
    
    public func stop() {
        if let validTimer = self.timer {
            validTimer.invalidate()
        }
    }
    
    private func scheduleTimer(seconds : Int) {
        let secondsDouble = Double(seconds)
        let selector = #selector(self.timerFired(timer:))
        timer = Timer.scheduledTimer(timeInterval: secondsDouble, target: self, selector: selector, userInfo: nil, repeats: true)
        
        // Go ahead and fire the first time
        timer?.fire()
    }
    
    @objc private func timerFired(timer : Timer) {
        // Only fire the sync if the background sync is not running
        if self.isSyncing {
//            print("Automatic sync avoided, already running in background")
//            return
            print("Syncing already running: Starting Anyway")
        }
        // Update the syncing status
        self.isSyncing = true
        let someWork : ()->() = {
            print("Background Sync Fired -> \(Date().toISOString())")
                            DispatchQueue.backgroundQueue.async {
            self.sync()
        }
                        }
        self.queue.addOperation(someWork);
        
        // Schedule more work
        // self.scheduleTimer(seconds: self.secondsInterval)
    }
    
    public func manualSync() {
        // Only fire the manual sync if the background sync is not running
        if self.isSyncing {
//            print("Manual sync avoided, already running in background")
//            return
            print("Syncing already running: Starting Anyway")
        }
		// Update the syncing status
		self.isSyncing = true
        
        // Create some work for queue
        let someWork : ()->() = {
            print("Manual Sync Fired -> \(Date().toISOString())")
            DispatchQueue.backgroundQueue.async {
                self.sync()
            }
        }
        self.queue.addOperation(someWork);
    }
    
    public func sync() {
        // Is there a network connection
        guard PingPong.shared.isEndpointReachable else {
            print("Sync aborting: Endpoint is not reachable")
            self.isSyncing = false
            return
        }
        
        // First thing, run the before automatic sync tasks
        let beforeTasks = PingPong.shared.autoTasks.filter({ $0.order == AutomaticSyncOrder.beforeDocumentSync })
        beforeTasks.forEach { task in
            task.sync(success: nil)
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
        
        // For tracking the end of syncing we will create an array of ints, and as they complete they will
        // pop an int off of the stack. This is a generic counting mechanism.
        var autoSyncTasksCounter : [Int] = [Int]()
        
        // For the success of the auto complete tasks we need to check the counter, and if it's empty then we know we're done
        let autoQueue = DispatchQueue(label: "autoTaskSuccessQueue") // Create a queue to process all success messages
        let autoSuccess = {
            autoQueue.sync {
            // Somehow this was fired when there was no objects left, so wrapping for safety
            if autoSyncTasksCounter.count > 0 {
                autoSyncTasksCounter.removeLast()
            }
            
            if (autoSyncTasksCounter.count == 0) {
                // Send complete notification
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("PingPong.BackgroundSync.Complete"), object: nil)
                    self.isSyncing = false
                }
            }
        }
        }
        
        // Get list of automatic sync tasks and execute
        let autoSyncTasks = PingPong.shared.autoTasks.filter({ $0.order == AutomaticSyncOrder.afterDocumentsSync })
        
        // Add a counter for each task
        autoSyncTasksCounter += 1...autoSyncTasks.count
        
        for task in autoSyncTasks {
            // Perform Sync
            // print("Starting task name \(String(describing: type(of: task)))")
            task.sync(success: autoSuccess)
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
