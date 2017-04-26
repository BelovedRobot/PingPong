//
//  SyncObject.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class SyncObject : StashObject {
    
    // Id didSet override, updateNotificationName, and onCloudUpdate are all built to ensure that any 
    // variables of this object in memeory will update automatically if a cloud update is issued.
    override var id: String {
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
    
    @objc private func onCloudUpdate() {
        self.refresh()
    }

    static func getUpdatedNotification(id : String) -> String {
        return "\(id)_updated"
    }
    
    func saveEventually() {
        // Update the local stash
        self.stash()
        
        // Stash DocId in Database and let it go
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: self.id)
    }
    
    func backgroundSync(callback : (() -> ())? ) {
        let isPost = (self.id == "")
        
        // Convert the closure to the type expected by post/put
        let convertedCallback : (String?)->() = { _ in
            callback?()
        }
        
        // If it is a post
        if isPost {
            self.post(success: convertedCallback)
        } else {
            self.put(success: convertedCallback)
        }
    }
    
    func fromCloud(success : (()->())?) {
        self.get{ jsonString in
            
            // If json was returned
            if let json = jsonString {
                
                // Populate self
                self.fromJSON(json: json)
                
                // Call success
                if let callableSuccess = success {
                    callableSuccess()
                }
            }
        }
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't overwrite local queued changes
    func safeStashFromCloud() {
        if !self.hasPendingSync() {
            let jsonString = self.toJSON()
            DataStore.sharedDataStore.stashDocument(documentJson: jsonString)
        }
    }
    
    // This func is meant for data coming from the cloud to ensure that it doesn't delete local queued changes, oftentimes when we fetch a large set of data we will delete existing data to ensure that objects deleted elsewhere are reflected. This is a safe way to do it.
    func safeDelete() {
        if !self.hasPendingSync() {
            DataStore.sharedDataStore.deleteDocument(id: self.id)
        }
    }
    
    func hasPendingSync() -> Bool {
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
    
    // POST Document
    private func post(success : ((_ jsonString : String?) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        let url = "\(PingPong.shared.documentEndpoint)/document"
        
        // Send the request
        request(url, method: .post, parameters: self.toDictionary(), encoding: JSONEncoding.default, headers: headerDict)
            .responseJSON { response in
                if response.response?.statusCode == 200 {
                    print("Document \(self.value(forKey: "docType")!) synced!")
                    
                    if let value = response.result.value {
                        let json = JSON(value);
                        let documentJson = json["data"].rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions(rawValue: 0))!
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson: documentJson)
                        
                        // Send notification of update
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncObject.getUpdatedNotification(id: self.id)), object: nil)
                        
                        success?(documentJson)
                    } else {
                        success?(nil)
                    }
                } else {
                    print("There was a problem syncing the document")
                    print("Response code is \(response.response?.statusCode)")
                }
        }
    }
    
    // PUT Document
    private func put(success : ((_ jsonString : String?) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        let url = "\(PingPong.shared.documentEndpoint)/document"
        
        // Send the request
        request(url, method: .put, parameters: self.toDictionary(), encoding: JSONEncoding.default, headers: headerDict)
            .responseJSON { response in
                if response.response?.statusCode == 200 {
                    print("Document \(self.value(forKey: "docType")!) synced!")
                    
                    if let value = response.result.value {
                        let json = JSON(value);
                        let documentJson = json["data"].rawString(String.Encoding.utf8, options: JSONSerialization.WritingOptions(rawValue: 0))!
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson: documentJson)
                        
                        // Send notification of update
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SyncObject.getUpdatedNotification(id: self.id)), object: nil)
                        
                        success?(documentJson)
                    } else {
                        success?(nil);
                    }
                } else {
                    print("There was a problem syncing the document")
                    print("Response code is \(response.response?.statusCode)")
                }
        }
    }
}

enum SyncObjectError: Error {
    case SerializationErrorUnsupportedType
    case SerializationErrorUnsupportedSubType
}
