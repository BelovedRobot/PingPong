//
//  SyncObject.swift
//  Deshazo
//
//  Created by Zane Kellogg on 6/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire

class SyncObject : StashObject {
    
    // Id didSet override, updateNotificationName, and onCloudUpdate are all built to ensure that any 
    // variables of this object in memeory will update automatically if a cloud update is issued.
    override var id: String {
        didSet {
            // Add observer for cloud changes
            NSNotificationCenter.defaultCenter().removeObserver(self, name: SyncObject.getUpdatedNotification(self.id), object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.onCloudUpdate), name: SyncObject.getUpdatedNotification(self.id), object: nil)
        }
    }
    
    @objc private func onCloudUpdate() {
        self.refresh()
    }

    
//    func save(callback: (() -> ())?) {
//        // Update the local stash
//        self.stash()
//        
//        self.saveDocumentToCloud(self) { jsonString in
//            if let json = jsonString {
//                self.fromJSON(json)
//            }
//            
//            if let callableCallback = callback {
//                callableCallback()
//            }
//        }
//    }
//    func saveAndWait() {
//        // Update the local stash
//        self.stash()
//        
//        // Create semaphore to await results
//        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
//        var jsonResult : String = ""
//        
//        self.saveDocumentToCloud(self) { jsonString in
//            if let json = jsonString {
//                jsonResult = json
//            }
//            dispatch_semaphore_signal(sema)
//        }
//        
//        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(20 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
//        
//        self.fromJSON(jsonResult)
//    }
    
    static func getUpdatedNotification(id : String) -> String {
        return "\(id)_updated"
    }
    
    func saveEventually() {
        // Update the local stash
        self.stash()
        
        // Stash DocId in Database and let it go
        DataStore.sharedDataStore.addDocumentToSyncQueue(self.id)
    }
    
    func backgroundSync(callback : (() -> ())? ) {
        let isPost = (self.id == "")
        
        // Convert the closure to the type expected by post/put
        let convertedCallback : (a : String?)->() = { a in
            callback?()
        }
        
        // If it is a post
        if isPost {
            self.post(convertedCallback)
        } else {
            self.put(convertedCallback)
        }
    }
    
//    // Save Document to Cloud (Network call)
//    private func saveDocumentToCloud(success : ((jsonString : String?) -> ())? ) {
//        let isPost = (self.id == "")
//        
//        // If it is a post
//        if isPost {
//            self.post(success)
//        } else {
//            self.put(success)
//        }
//    }
    
    // POST Document
    private func post(success : ((jsonString : String?) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        let url = "\(PingPong.shared.documentEndpoint)/document"
        
        // Send the request
        request(.POST, url, parameters: self.toDictionary(), headers: headerDict, encoding: .JSON)
            .responseJSON { response in
                if response.response?.statusCode == 200 {
                    print("Document \(self.valueForKey("docType")!) synced!")
                    
                    if let value = response.result.value {
                        let json = JSON(value);
                        let documentJson = json["data"].rawString(NSUTF8StringEncoding, options: NSJSONWritingOptions(rawValue: 0))!
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson)
                        
                        // Send notification of update
                        NSNotificationCenter.defaultCenter().postNotificationName(SyncObject.getUpdatedNotification(self.id), object: nil)
                        
                        success?(jsonString: documentJson)
                    } else {
                        success?(jsonString: nil);
                    }
                } else {
                    print("There was a problem syncing the document")
                    print("Response code is \(response.response?.statusCode)")
                }
        }
    }
    
    // PUT Document
    private func put(success : ((jsonString : String?) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        let url = "\(PingPong.shared.documentEndpoint)/document"
        
        // Send the request
        request(.PUT, url, parameters: self.toDictionary(), headers: headerDict, encoding: .JSON)
            .responseJSON { response in
                if response.response?.statusCode == 200 {
                    print("Document \(self.valueForKey("docType")!) synced!")
                    
                    if let value = response.result.value {
                        let json = JSON(value);
                        let documentJson = json["data"].rawString(NSUTF8StringEncoding, options: NSJSONWritingOptions(rawValue: 0))!
                        
                        // Update stash
                        DataStore.sharedDataStore.stashDocument(documentJson)
                        
                        // Send notification of update
                        NSNotificationCenter.defaultCenter().postNotificationName(SyncObject.getUpdatedNotification(self.id), object: nil)
                        
                        success?(jsonString: documentJson)
                    } else {
                        success?(jsonString: nil);
                    }
                } else {
                    if let request = response.request, body = request.HTTPBody {
                        let strBody = NSString(data: body, encoding: NSUTF8StringEncoding)
                        print(strBody!)
                    }
                    
                    print("There was a problem syncing the document")
                    print("Response code is \(response.response?.statusCode)")
                }
        }
    }
}

enum SyncObjectError: ErrorType {
    case SerializationErrorUnsupportedType
    case SerializationErrorUnsupportedSubType
}