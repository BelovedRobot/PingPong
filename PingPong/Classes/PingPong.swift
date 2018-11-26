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
    
    // POST JSON Document
    public func saveDocumentToCloud(jsonString : String, success : (() -> ())? ) {
        // Guard against missing id
        guard let id = JSON.init(parseJSON: jsonString)["id"].string else {
            return
        }
        
        let url = "\(PingPong.shared.documentEndpoint)/document"
        
        guard let nsUrl = NSURL(string: url) else {
            success?()
            return
        }
        
        // Build the request
        let request = NSMutableURLRequest(url: nsUrl as URL)
        request.httpMethod = "PUT"
        request.httpBody = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true)
        let authValue = "Token token=\(PingPong.shared.authorizationToken)"
        request.addValue(authValue, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Build the task
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
            // Check if response is valid
            if let httpResponse = response as? HTTPURLResponse {
                // Check the status code
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    // Parse the data
                    if let realData = data, let value = String(data: realData, encoding: String.Encoding.utf8) {
                        let json = JSON.init(parseJSON: value)
                        if let documentJson = json["data"].rawString() {
                            // Update stash
                            DataStore.sharedDataStore.stashDocument(documentJson: documentJson)
                            
                            // Send notification of update
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncObject.getUpdatedNotification(id: id)), object: nil)
                            
                            if let docType = json["data"]["docType"].string {
                                print("Document \(docType) synced!")
                            } else {
                                print("Document synced down but JSON could not be parsed")
                            }
                            
                            success?()
                        }
                    }
                } else {
                    // The request went bad, do some thing about it
                    print("There was a problem syncing the document")
                    print("Response code is \(httpResponse.statusCode)")
                }
            } else {
                // The response is nil
                print("There was a problem syncing the document, did not recieve a response from the endpoint")
            }
        })
        
        task.resume()
    }
}
