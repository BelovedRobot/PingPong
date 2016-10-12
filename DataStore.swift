//
//  DataStore.swift
//  Deshazo
//
//  Created by Zane Kellogg on 5/31/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class DataStore {
    static let sharedDataStore : DataStore = DataStore()
    private static let databaseName : String = "br-data-store.sqlite3"
    private var queue : FMDatabaseQueue
    
    init() {
        // Get and unwrap instance of BRDatabase
        let sharedDatabase = BRDatabase.sharedBRDatabase() as! BRDatabase
        
        // If database path is nil then we are assured that it has not yet been created
        if let path = sharedDatabase.databasePath {
            NSLog("DB created at path: \(path)")
        } else {
            sharedDatabase.initializeWithDatabaseName(DataStore.databaseName, withDatabaseVersion: 0.0, withSuccess: nil)
            print("SQLite path is \(sharedDatabase.databasePath)")
        }
        
        // Initialize the queue
        let appDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let dbPath = "\(appDir)/\(DataStore.databaseName)"
        queue = FMDatabaseQueue(path: dbPath)
    }
    
    func addDocumentToSyncQueue(documentId : String) {
        queue.inDatabase { (database) in
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue WHERE id == ?;", documentId)
                if (results.next()) {
                    // The id already exists in the sync queue so skip
                    results.close()
                    return
                }
                results.close()

                // If you're still here then add to the queue
                try database.executeUpdate("INSERT INTO sync_queue (id) VALUES (?);", documentId)
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    func hasPendingSync(documentId : String) -> Bool {
        var hasChanges = false
        
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        
        queue.inDatabase { (database) in
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue WHERE id == ?;", documentId)
                if (results.next()) {
                    // The id already exists in the sync queue return true
                    hasChanges = true
                }
                results.close()
                dispatch_semaphore_signal(sema)
                
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
        
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(20 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
        return hasChanges

    }
    
    func removeDocumentFromSyncQueue(documentId : String) {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM sync_queue WHERE id == ?;", documentId)
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    func removeOrphanedSyncQueueEntries() {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM sync_queue WHERE id NOT IN (SELECT id FROM documents);")
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    func stashDocument(documentJson : String) {
        let json = JSON.parse(documentJson)
        
        if let id = json["id"].string {
            queue.inDatabase { (database) -> Void in
                do {
                    // First see if document already exists
                    let results = try database.executeQuery("SELECT * FROM documents WHERE id = ?;", id)
                    if (results.next()) {
                        // The document does exist so update
                        try database.executeUpdate("UPDATE documents SET json = ? WHERE id = ?;", documentJson, id)
                        results.close()
                        return;
                    }
                    results.close()
                    
                    // Document does not exist so we insert
                    try database.executeUpdate("INSERT INTO documents (id, json) VALUES(?, ?);", id, documentJson);
                } catch {
                    print("There was an error executing database queries or updates.")
                }
            }
        }
    }
    
    func retrieveDocumentJSON(id : String, callback: (String?) -> ()) {
        queue.inDatabase { (database) in
            do {
                var jsonResult : String? = nil
                let results = try database.executeQuery("SELECT json FROM documents WHERE id = ?;", id)
                if (results.next()) {
                    jsonResult = results.stringForColumn("json")
                }
                results.close()
                callback(jsonResult)
            } catch {
                print("There was an error executing database queries or updates.")
                
            }
        }
    }
    
    func retrieveDocumentJSONSynchronous(id : String) -> String? {
        var result : String?
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        DataStore.sharedDataStore.retrieveDocumentJSON(id, callback: { jsonResult in
            if let json = jsonResult {
                result = json
            }
            dispatch_semaphore_signal(sema)
        })
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(20 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
        return result
    }
    
    func deleteDocument(id : String) {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM documents WHERE id = ?;", id)
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    func deleteDocumentsOfType(docType : String) {
        // Create semaphore to await results
        let sema : dispatch_semaphore_t = dispatch_semaphore_create(0)
        var documentsJson : [JSON] = []
        
        self.queryDocumentStore(("docType", docType)) { json in
            documentsJson = json
            dispatch_semaphore_signal(sema)
        }
        
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, Int64(20 * Double(NSEC_PER_SEC)))) // Waits 20 seconds, more than enough time
        
        for docJson in documentsJson {
            if let id = docJson["id"].string {
                self.deleteDocument(id)
            }
        }
    }
    
    func queryDocumentStore(parameters : (property: String, value: String)..., callback : ([JSON]) -> ()) {
        queue.inDatabase { (database) in
            // Load all json objects AHHHHHH
            var documents = [JSON]()
            
            do {
                let results = try database.executeQuery("SELECT * FROM documents;")
                while (results.next()) {
                    documents.append(JSON.parse(results.stringForColumn("json")))
                }
                results.close()
            } catch {
                print("There was an error executing database queries or updates.")
            }
            
            // Filter documents by parameters
            for (property, value) in parameters {
                documents = documents.filter({ (json) -> Bool in
                    if let val = json[property].string {
                        if (val == value) {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        // Property does not exist on document
                        return false
                    }
                })
            }
            
            callback(documents);
        }
    }
    
    func retrieveQueuedDocuments(callback: ([String]?) -> ()) {
        queue.inDatabase { (database) in
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue;")
                var syncIds : [String] = []
                while (results.next()) {
                    let id = results.stringForColumn("id")
                    syncIds.append(id)
                }
                results.close()
                
                // For each ID get the json
                var documents : [String] = []
                for id in syncIds {
                    let docResult = try database.executeQuery("SELECT json FROM documents WHERE id = ?;", id)
                    if (docResult.next()) {
                        let json = docResult.stringForColumn("json")
                        documents.append(json)
                    }
                    docResult.close()
                }
                callback(documents)
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    private func fatalAlert(message: String) {
        print("DataStore FATAL ERROR -> \(message)")
    }
}