//
//  SyncObject.swift
//
//  Created by Zane Kellogg on 6/2/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire

extension Syncable {
    
    public func saveEventually() {
        // Update the local stash
        self.stash()
        
        // Stash DocId in Database and let it go
        DataStore.sharedDataStore.addDocumentToSyncQueue(documentId: self.id)
    }
    
    public func backgroundSync(completion : @escaping (_ success : Bool) -> ()) {
        // Check for an identifier
        if (self.id == "") {
            print("Invalid Document, the ID has not been set.")
            completion(false)
            return
        }
        
        // Determine if Delete
        if (self.deleted) {
            self.delete(completion: completion)
            return
        }
        
        // Determine Post/Put
        var method = HTTPMethod.post
        if (self.synced) {
            method = HTTPMethod.put
        }
        
        self.postPut(method: method, completion: completion)
    }
    
    // POST/PUT Document
    private func postPut(method : HTTPMethod, completion : @escaping (_ success : Bool) -> () ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        // Add the id if a PUT
        var urlStr = "\(PingPong.shared.documentEndpoint)/document"
        if (method == .put) {
            urlStr = "url/\(self.id)"
        }
        
        // Convert URL
        guard let url : URL = URL(string: urlStr) else {
            print("Invalid URL provided, please check the default document endpoint")
            completion(false)
            return
        }
        
        // Create the request
        guard var urlRequest = try? URLRequest(url: url, method: method, headers: headerDict) else {
            print("Invalid URL Request, please check the authentication token")
            completion(false)
            return
        }
        
        // Set the body
        guard let body = self.toJSON()?.data(using: .utf8) else {
            print("Invalid object, data is nil")
            completion(false)
            return
        }
        urlRequest.httpBody = body
        
        // Send the request
        request(urlRequest)
            .validate()
            .response(
                queue: DispatchQueue.backgroundQueue,
                responseSerializer: DataRequest.dataResponseSerializer(),
                completionHandler: { response in
                    switch response.result {
                    case .success( _):
                        print("Document \(self.docType):\(self.id) synced!")
                        
                        // Create copy of self and stash as synced
                        var copy = self
                        copy.synced = true
                        copy.stash()
                        
                        completion(true)
                    case .failure(let error):
                        print("There was a problem syncing the document: \(error.localizedDescription)")
                        print("Response code is \(String(describing: response.response?.statusCode))")
                        completion(false)
                    }
            })
    }
    
    // DELETE Document
    private func delete(completion : @escaping (_ success : Bool) -> () ) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
            "Content-Type" : "application/json"
        ];
        
        // Add the id if a PUT
        let urlStr = "\(PingPong.shared.documentEndpoint)/document/\(self.id)"
        
        // Convert URL
        guard let url : URL = URL(string: urlStr) else {
            print("Invalid URL provided, please check the default document endpoint")
            completion(false)
            return
        }
        
        // Create the request
        guard let urlRequest = try? URLRequest(url: url, method: .delete, headers: headerDict) else {
            print("Invalid URL Request, please check the authentication token")
            completion(false)
            return
        }
        
        // Send the request
        request(urlRequest)
            .validate()
            .response(
                queue: DispatchQueue.backgroundQueue,
                responseSerializer: DataRequest.dataResponseSerializer(),
                completionHandler: { response in
                    switch response.result {
                    case .success( _):
                        print("Document \(self.docType):\(self.id) deleted!")
                        
                        completion(true)
                    case .failure(let error):
                        print("There was a problem deleting the document: \(error.localizedDescription)")
                        print("Response code is \(String(describing: response.response?.statusCode))")
                        completion(false)
                    }
            })
    }
    
    //    // GET Document
    //    private static func get(id : String, completion : @escaping (_ success : Bool, _ object : Syncable) -> () ) {
    //        let headerDict = [
    //            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)",
    //            "Content-Type" : "application/json"
    //        ];
    //
    //        // Add the id if a PUT
    //        let urlStr = "\(PingPong.shared.documentEndpoint)/document/\(id)"
    //
    //        // Convert URL
    //        guard let url : URL = URL(string: urlStr) else {
    //            print("Invalid URL provided, please check the default document endpoint")
    //            completion(false)
    //            return
    //        }
    //
    //        // Create the request
    //        guard let urlRequest = try? URLRequest(url: url, method: .get, headers: headerDict) else {
    //            print("Invalid URL Request, please check the authentication token")
    //            completion(false)
    //            return
    //        }
    //
    //        // Send the request
    //        request(urlRequest)
    //            .validate()
    //            .response(
    //                queue: DispatchQueue.backgroundQueue,
    //                responseSerializer: DataRequest.jsonResponseSerializer(),
    //                completionHandler: { response in
    //                    switch response.result {
    //                    case .success(let value):
    //
    //                        print("Document \(self.docType):\(self.id) deleted!")
    //
    //                        completion(true)
    //                    case .failure(let error):
    //                        print("There was a problem deleting the document: \(error.localizedDescription)")
    //                        print("Response code is \(String(describing: response.response?.statusCode))")
    //                        completion(false)
    //                    }
    //            })
    //    }
    
    
}
