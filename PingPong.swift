//
//  SyncFramework.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/8/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire

class PingPong {
    
    static let shared : PingPong = PingPong()
    var documentEndpoint : String = ""
    var authorizationToken : String = ""
    private var backgroundSync : BackgroundSync
    private var reachabilityManager : NetworkReachabilityManager?
    var isEndpointReachable : Bool = false
    
    init() {
        // Init the data store
        DataStore.sharedDataStore
        
        // Init the background sync
        self.backgroundSync = BackgroundSync.shared
        
        // Init Reachability Manger with no host
        self.reachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    }
    
    func start(documentEndpoint : String, authorizationToken : String, secondsInterval : Int) {
        self.documentEndpoint = documentEndpoint
        self.authorizationToken = authorizationToken
        self.backgroundSync.start(secondsInterval)
        
        // Start listening
        self.reachabilityManager?.listener = { status in
            print("Network Status Changed: \(status)")
            switch (status) {
            case .Reachable(.EthernetOrWiFi):
                self.isEndpointReachable = true
            case .Reachable(.WWAN):
                self.isEndpointReachable = true
            default:
                self.isEndpointReachable = false
            }
        }
        self.reachabilityManager?.startListening()
    }
    
    func uploadFile(fileUpload : FileUpload, callback: ()->()) {
        guard let fileUrl = NSURL(string: fileUpload.localFileUrl) else {
            return
        }
        
        let json = fileUpload.toJSON()
        guard let jsonData = json.dataUsingEncoding(NSUTF8StringEncoding) else {
            return
        }
        
        let headerDict = [
            "Authorization" : "Token token=\(self.authorizationToken)"
        ];

        let endpoint = "\(PingPong.shared.documentEndpoint)/app/upload"
        
        upload(.POST, endpoint, headers: headerDict,
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(fileURL: fileUrl, name: "file")
                multipartFormData.appendBodyPart(data: jsonData, name: "targetDocument", mimeType: "application/json")
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        switch response.result {
                        case .Success:
                            print("Upload complete!")
                            // Does response have a valid value
                            if let value = response.result.value {
                                let jsonObj = JSON(value)
                                // Cast JSON object
                                if let updatedDocument = jsonObj["data"].rawString(NSUTF8StringEncoding, options: NSJSONWritingOptions(rawValue: 0)) {
                                    
                                    // Update the file locally
                                    DataStore.sharedDataStore.stashDocument(updatedDocument)
                                    
                                    // Send notification of update
                                    if let id = jsonObj["data"]["id"].string {
                                        let notificationName = "\(id)_updated"
                                        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil)
                                    }
                                    
                                    // Delete the old local temp file
                                    do {
                                        try NSFileManager.defaultManager().removeItemAtURL(fileUrl)
                                    } catch { } // I don't really care if this fails so move on
                                    
                                    // Execute callback
                                    callback()
                                }
                            }
                        case .Failure(let error):
                            print(error)
                        }
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
    
    func saveFileEventually(fileData : FileUpload) {
        fileData.stash()
        
        // Ensure the taget object is queued for syncing first, because it will affect matching later
        DataStore.sharedDataStore.addDocumentToSyncQueue(fileData.targetId)
        
        // Now set the file data to sync
        DataStore.sharedDataStore.addDocumentToSyncQueue(fileData.id)
    }
    
    func deleteFile(fileDelete : FileDelete, callback: ()->()) {
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
            
            request(.DELETE, endpoint, parameters: parameters, encoding: .JSON, headers: headerDict)
                .responseJSON{ response in
                    switch response.result {
                    case .Success:
                        print("Delete file success!")
                        callback()
                    case .Failure(let error):
                        print(error)
                    }
            }
        }
    }
    
    func deleteFileEventually(fileDelete : FileDelete) {
        fileDelete.stash()
        DataStore.sharedDataStore.addDocumentToSyncQueue(fileDelete.id)
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
        let request = NSMutableURLRequest(URL: nsUrl)
        request.HTTPMethod = "PUT"
        request.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        request.addValue(PingPong.shared.authorizationToken, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Build the task
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            // Check if response is valid
            if let httpResponse = response as? NSHTTPURLResponse {
                // Check the status code
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    // Parse the data
                    if let realData = data, value = String(data: realData, encoding: NSUTF8StringEncoding) {
                        let json = JSON(value);
                        let documentJson = json["data"].rawString(NSUTF8StringEncoding, options: NSJSONWritingOptions(rawValue: 0))!
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson)
                        
                        // Send notification of update
                        NSNotificationCenter.defaultCenter().postNotificationName(SyncObject.getUpdatedNotification(id), object: nil)
                        
                        success?()
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