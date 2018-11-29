//
//  SyncObject.swift
//
//  Created by Zane Kellogg on 6/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

open class SyncObject : StashObject {
    
    // Id didSet override, updateNotificationName, and onCloudUpdate are all built to ensure that any 
    // variables of this object in memeory will update automatically if a cloud update is issued.
    override open var id: String {
        didSet {
            // Only add the observer is id is not ""
            if (id != "") {
                // Add observer for cloud changes
                let notificationName = Notification.Name(SyncObject.getUpdatedNotification(id: self.id))
                NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.onCloudUpdate), name: notificationName, object: nil)
            }
        }
    }
    
    @objc public var synced : Bool = false // Every sync object is required to have a flag that tells PingPong if it has been synced. This will tell the API to issue a post or a put.
    
    @objc private func onCloudUpdate() {
        self.refresh()
    }

    public static func getUpdatedNotification(id : String) -> String {
        return "\(id)_updated"
    }
    
    public func saveEventually() {
        // Update the local stash
        self.stash()
        
        // Stash DocId in Database and let it go
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: self.id)
    }
    
    public func backgroundSync(completion : @escaping (_ success : Bool) -> ()) {
        // Determine Post/Put
        var method = HTTPMethod.post
        if (self.synced) {
            method = HTTPMethod.put
        }
        
        self.postPut(method: method, completion: completion)
    }
    
    public func fromCloud(success : (()->())?) {
        self.get{ jsonString in
            
            // If json was returned
            if let json = jsonString {
                
                // Populate self
                self.fromJSON(json: json)
                
                // Call success
                success?()
            }
        }
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't overwrite local queued changes
    public func safeStashFromCloud() {
        if !self.hasPendingSync() {
            let jsonString = self.toJSON()
            DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
        }
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't delete local queued changes, oftentimes when we fetch a large set of data we will delete existing data to ensure that objects deleted elsewhere are reflected. This is a safe way to do it.
    public func safeDelete() {
        if !self.hasPendingSync() {
            DataStore.sharedDataStore.deleteDocument(id: self.id)
        }
    }
    
    public func hasPendingSync() -> Bool {
        return DataStore.sharedDataStore.hasPendingSync(documentId: self.id);
    }
    
    // Get Document
    private func get(success : ((String?) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        let url = "\(PingPong.shared.documentEndpoint)/document/\(self.id)"
        
        // Send the request
        request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headerDict)
            .validate()
            .responseJSON { response in
                print("Document \(self.value(forKey: "docType")!) retrieved!")
                
                if let value = response.result.value {
                    let json = JSON(value);
                    if let documentJson = json.rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson: documentJson)
                        
                        // Send notification of update
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncObject.getUpdatedNotification(id: self.id)), object: nil)
                        
                        success?(documentJson)
                    } else {
                        print("There was a problem retrieving the document")
                    }
                } else {
                    success?(nil)
                }
        }
    }
    
    // POST/PUT Document
    private func postPut(method : HTTPMethod, completion : @escaping (_ success : Bool) -> () ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        var url = "\(PingPong.shared.documentEndpoint)/document"
        if (method == .put) {
            url = "url/\(self.id)"
        }
        
        // Send the request
        request(url, method: method, parameters: self.toDictionary(), encoding: JSONEncoding.default, headers: headerDict)
            .validate()
            .response(
                queue: DispatchQueue.backgroundQueue,
                responseSerializer: DataRequest.jsonResponseSerializer(),
                completionHandler: { response in
                    switch response.result {
                    case .success(let value):
                        print("Document \(self.docType):\(self.id) synced!")
                        
                        var json = JSON(value)
                        
                        // Set field synced = true
                        json["synced"] = true
                        
                        // Update stash
                        if let documentJson = json["data"].rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions(rawValue: 0)) {
                            DataStore.sharedDataStore.stashDocument(documentJson: documentJson)
                        } else {
                            // If the endpoint doesn't return anything but is still successful then we simply mark self as synced and stash
                            self.synced = true
                            self.stash()
                        }
                    
                        // Send notification of update
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncObject.getUpdatedNotification(id: self.id)), object: nil)
                        
                        completion(true)
                    case .failure(let error):
                        print("There was a problem syncing the document: \(error.localizedDescription)")
                        print("Response code is \(String(describing: response.response?.statusCode))")
                        completion(false)
                    }
        })
    }
}

enum SyncObjectError: Error {
    case SerializationErrorUnsupportedType
    case SerializationErrorUnsupportedSubType
}
