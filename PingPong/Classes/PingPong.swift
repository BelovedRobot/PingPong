//
//  SyncFramework.swift
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public class PingPong {
    
    public static let shared : PingPong = PingPong()

    public var documentEndpoint : String = ""
    public var authorizationToken : String = ""
    public var backgroundSync : BackgroundSync
    public var reachabilityManager : NetworkReachabilityManager?
    public var isEndpointReachable : Bool = false
    public var avoidSyncIfUnreachable : Bool = true // Setting this to false will enable the sync to run regardless of reachability status
    
    var syncTasks = [SyncTask]() // This array of sync tasks is configured with PingPong and enables overriding the default document syncing behavior
    var autoTasks = [AutomaticSyncTask]() // This array of sync tasks is configured with PingPong and enables task to be executed for each sync
    
    private init() {
        // Init the data store
        let _ = DataStore.sharedDataStore
        
        // Init the background sync
        self.backgroundSync = BackgroundSync.shared
        
        // Init Reachability Manger with no host
        self.reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    }
    
    public func start(documentEndpoint : String, authorizationToken : String, backGroundSyncInterval : Int, syncTasks : [SyncTask]?, automaticSyncTasks : [AutomaticSyncTask]?) {
        self.documentEndpoint = documentEndpoint
        self.authorizationToken = authorizationToken
        
        if let tasks = syncTasks {
            self.syncTasks = tasks
        }
        
        if let autoTasks = automaticSyncTasks {
            self.autoTasks = autoTasks
        }
        
        // Ensure the setting is enabled before starting reachablity
        if self.avoidSyncIfUnreachable {
            // Start listening
            self.reachabilityManager?.listener = { status in
                print("Network Status Changed: \(status)")
                switch (status) {
                case .reachable(.ethernetOrWiFi):
                    self.isEndpointReachable = true
                case .reachable(.wwan):
                    self.isEndpointReachable = true
                default:
                    self.isEndpointReachable = false
                }
            }
            self.reachabilityManager?.startListening()
        } else {
            // The feature is disabled so force isReachable to always be true
            self.isEndpointReachable = true
        }
        
        let wait = DispatchTime.now() + 1 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: wait) {
            self.backgroundSync.start(secondsInterval: backGroundSyncInterval)
        }
    }
    
    public func startBackgroundSync(documentEndpoint : String, authorizationToken : String, syncTasks : [SyncTask]?, automaticSyncTasks: [AutomaticSyncTask]?) {
        self.documentEndpoint = documentEndpoint
        self.authorizationToken = authorizationToken
        
        if let tasks = syncTasks {
            self.syncTasks = tasks
        }
        
        if let autoTasks = automaticSyncTasks {
            self.autoTasks = autoTasks
        }
        
        // Start listening
        self.reachabilityManager?.listener = { status in
            print("Network Status Changed: \(status)")
            switch (status) {
            case .reachable(.ethernetOrWiFi):
                self.isEndpointReachable = true
            case .reachable(.wwan):
                self.isEndpointReachable = true
            default:
                self.isEndpointReachable = false
            }
        }
        self.reachabilityManager?.startListening()
        
        // Call the background sync
        self.backgroundSync.sync()
    }
    
    public func stop() {
        self.backgroundSync.stop()
    }
}
