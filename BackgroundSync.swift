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
    private var queue : NSOperationQueue;
    private var secondsInterval : Int = 0
    private var timer : NSTimer?
    
    init() {
        queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1 // Serial Queue
    }
    
    func start(secondsInterval : Int) {
        self.secondsInterval = secondsInterval
        self.scheduleTimer()
    }
    
    func stop() {
        if let validTimer = self.timer {
            validTimer.invalidate()
        }
    }
    
    private func scheduleTimer() {
        let seconds = Double(self.secondsInterval)
        timer = NSTimer.scheduledTimerWithTimeInterval(seconds, target: self, selector: #selector(self.timerFired(_:)), userInfo: nil, repeats: false)
    }
    
    @objc private func timerFired(timer : NSTimer) {
        let someWork : ()->() = {
            NSDate().toISOString()
            
            print("Background Sync Fired -> \(NSDate().toISOString())")
            
            self.sync()
        }
        queue.addOperationWithBlock(someWork);
        
        // Schedule more work
        self.scheduleTimer()
    }
    
    func sync() {
        // Is there a network connection
        guard PingPong.shared.isEndpointReachable else {
            return
        }
        
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        // Get all Document Ids to Sync
        var results : [String]?
        DataStore.sharedDataStore.retrieveQueuedDocuments { (dataResults) in
            results = dataResults
            dispatch_semaphore_signal(sema)
        }
        
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(20 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
        
        if let jsonDocuments = results {
            // For each document
            for json in jsonDocuments {
                let type = JSON.parse(json)["docType"].stringValue
                let id = JSON.parse(json)["id"].stringValue
                
                // The success for each type of document is to remove itself from the sync queue
                let success = {
                    DataStore.sharedDataStore.removeDocumentFromSyncQueue(id)
                }
                
                // Based on type, de-serialize from JSON in order to save
                switch(type) {
                case "fileUpload":
                    let fileUpload = FileUpload()
                    fileUpload.fromJSON(json)
                    PingPong.shared.uploadFile(fileUpload, callback: success)
                case "fileDelete":
                    let fileDelete = FileDelete()
                    fileDelete.fromJSON(json)
                    PingPong.shared.deleteFile(fileDelete, callback: success)
                default:
                    // Does the docType has a custom sync option
                    if let syncOption = PingPong.shared.syncOptions[type] {
                        syncOption(jsonData: json, success: success)
                    } else {
                        // By Default sync the document
                        PingPong.shared.saveDocumentToCloud(json, success: success)
                    }
                }
            }
        }
    }
}