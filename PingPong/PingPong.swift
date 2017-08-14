//
//  SyncFramework.swift
//  Deshazo
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
    private var reachabilityManager : NetworkReachabilityManager?
    var isEndpointReachable : Bool = false
    var syncTasks = [SyncTask]() // This array of sync tasks is configured with PingPong and enables overriding the default document syncing behavior
    
    init() {
        // Init the data store
        let _ = DataStore.sharedDataStore
        
        // Init the background sync
        self.backgroundSync = BackgroundSync.shared
        
        // Init Reachability Manger with no host
        self.reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    }
    
    public func start(documentEndpoint : String, authorizationToken : String, backGroundSyncInterval : Int, syncTasks : [SyncTask]?) {
        self.documentEndpoint = documentEndpoint
        self.authorizationToken = authorizationToken
        self.backgroundSync.start(secondsInterval: backGroundSyncInterval)
        if let tasks = syncTasks {
            self.syncTasks = tasks
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
    }
    
    func startBackgroundSync(documentEndpoint : String, authorizationToken : String, syncTasks : [SyncTask]?) {
        self.documentEndpoint = documentEndpoint
        self.authorizationToken = authorizationToken
        if let tasks = syncTasks {
            self.syncTasks = tasks
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
    
    func stop() {
        self.backgroundSync.stop()
    }
    
    func uploadFile(fileUpload : FileUpload, callback: @escaping ()->()) {
        // Expand the path if necessary
        let expandedPath = (fileUpload.localFilePath as NSString).expandingTildeInPath
        
        // Check if the file does not exist
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            // Delete the record and sync record
            DataStore.sharedDataStore.deleteDocument(id: fileUpload.id)
            DataStore.sharedDataStore.removeDocumentFromSyncQueue(documentId: fileUpload.id)
            return
        }
        
        let json = fileUpload.toJSON()
        guard let jsonData = json.data(using: String.Encoding.utf8) else {
            return
        }
        
        let headerDict = [
            "Authorization" : "Token token=\(self.authorizationToken)"
        ]

        let endpoint = "\(PingPong.shared.documentEndpoint)/app/upload"
        let fileUrl = NSURL.fileURL(withPath: expandedPath)

        upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(fileUrl, withName: "file")
                multipartFormData.append(jsonData, withName: "targetDocument", mimeType: "application/json")
            },
            to: endpoint,
            method: .post,
            headers: headerDict,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        switch response.result {
                        case .success:
                            print("Upload complete!")
                            // Does response have a valid value
                            if let value = response.result.value {
                                let jsonObj = JSON(value)
                                // Cast JSON object
                                if let updatedDocument = jsonObj["data"].rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                                    // Update the file locally
                                    DataStore.sharedDataStore.stashDocument(documentJson: updatedDocument)
                        
                                    // Send notification of update
                                    if let id = jsonObj["data"]["id"].string {
                                        let notificationName = "\(id)_updated"
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName), object: nil)
                                    }
                        
                                    // Delete the old local temp file
                                    do {
                                        try FileManager.default.removeItem(at: fileUrl)
                                    } catch { } // I don't really care if this fails so move on
                        
                                    // Execute callback
                                    callback()
                                }
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
    
    func saveFileEventually(fileData : FileUpload) {
        fileData.stash()
        
        // Ensure the taget object is queued for syncing first, because it will affect matching later
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: fileData.targetId)
        
        // Now set the file data to sync
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: fileData.id)
    }
    
    func deleteFile(fileDelete : FileDelete, callback: @escaping ()->()) {
        guard let fileUrl = NSURL(string: fileDelete.fileUrl) else {
            return
        }
        
        if let path = fileUrl.path {
            let pathString = path as NSString
            let fileName = pathString.lastPathComponent
         
            let headerDict = [
                "Authorization" : "Token token=\(self.authorizationToken)"
            ];
            
            let endpoint = "\(PingPong.shared.documentEndpoint)/app/upload"
            
            let parameters = [ "fileName" : fileName]
            
            request(endpoint, method: .delete, parameters: parameters, encoding: JSONEncoding.default, headers: headerDict)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        print("Delete file success!")
                        callback()
                    case .failure(let error):
                        print(error)
                    }
            }
        }
    }
    
    func deleteFileEventually(fileDelete : FileDelete) {
        fileDelete.stash()
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: fileDelete.id)
    }
    
    // POST JSON Document
    func saveDocumentToCloud(jsonString : String, success : (() -> ())? ) {
        // Guard against missing id
        guard let id = JSON.parse(jsonString)["id"].string else {
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
                        let json = JSON.parse(value)
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
