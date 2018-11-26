//
//  DataStore.swift
//
//  Created by Zane Kellogg on 5/31/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import FMDB
import SwiftyJSON

public class DataStore {
    public static let sharedDataStore : DataStore = DataStore()
    public static let databaseName : String = "br-data-store.sqlite3"
    private var queue : FMDatabaseQueue
    
    private init() {
        // Get and unwrap instance of BRDatabase
        let sharedDatabase = BRDatabase.sharedBRDatabase 
        
        // If database path is nil then we are assured that it has not yet been created
        if let path = sharedDatabase.databasePath {
            print("DB created at path: \(path)")
        } else {
            sharedDatabase.initialize(databaseName: DataStore.databaseName, databaseVersion: 0.0, success: nil)
            print("SQLite path is \(String(describing: sharedDatabase.databasePath))")
        }
        
        // Initialize the queue
        let appDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = "\(appDir)/\(DataStore.databaseName)"
        queue = FMDatabaseQueue(path: dbPath)!
    }
    
    public func stashObjects(objects: [StashObject]) -> Bool{
        var success : Bool = false
        queue.inTransaction() { database, rollback in
            for stashableObject in objects {
                do {
                    let documentJson = stashableObject.toJSON()
                    
                    if !stashableObject.id.isEmpty {
                        let id = stashableObject.id
                        // First see if document already exists
                        //   print("CHECKING FOR A DEF DOCUMENT HERE \(id)")
                        let results = try database.executeQuery("SELECT * FROM documents WHERE id = ?;", values: [id])
                        if (results.next()) {
                            // The document does exist so update
                            try database.executeUpdate("UPDATE documents SET json = ? WHERE id = ?;", values: [documentJson, id])
                        }else{
                            try database.executeUpdate("INSERT INTO documents (id, json) VALUES(?, ?);", values: [id, documentJson])
                        }
                        results.close()

                        
                        // Document does not exist so we insert
                        
                        success = true
                    }
                } catch {
                    rollback.pointee = true
                    print("There was an error executing database queries or updates.")
                    success = false
                }
            }
        }
        return success
    }
    
    public func addDocumentToSyncQueue(documentId : String) {
        queue.inDatabase { database in
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue WHERE id == ?;", values: [documentId])
                if (results.next()) {
                    // The id already exists in the sync queue so skip
                    results.close()
                    return
                }
                results.close()

                // If you're still here then add to the queue
                try database.executeUpdate("INSERT INTO sync_queue (id) VALUES (?);", values: [documentId])
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    public func hasPendingSync(documentId : String) -> Bool {
        var hasChanges = false
        
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        
        queue.inDatabase { (database) in
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue WHERE id == ?;", values: [documentId])
                if (results.next()) {
                    // The id already exists in the sync queue return true
                    hasChanges = true
                }
                results.close()
                sema.signal()
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
        
        let _ = sema.wait()
        
        return hasChanges

    }
    
    public func removeDocumentFromSyncQueue(documentId : String) {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM sync_queue WHERE id == ?;", values: [documentId])
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    public func removeOrphanedSyncQueueEntries() {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM sync_queue WHERE id NOT IN (SELECT id FROM documents);", values: nil)
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    public func stashDocument(documentJson : String) {
        let json = JSON.init(parseJSON: documentJson)
        
        if let id = json["id"].string {
            queue.inDatabase { (database) -> Void in
                do {
                    // First see if document already exists
                    let results = try database.executeQuery("SELECT * FROM documents WHERE id = ?;", values: [id])
                    if (results.next()) {
                        // The document does exist so update
                        try database.executeUpdate("UPDATE documents SET json = ? WHERE id = ?;", values: [documentJson, id])
                        results.close()
                        return
                    }
                    results.close()
                    
                    // Document does not exist so we insert
                    try database.executeUpdate("INSERT INTO documents (id, json) VALUES(?, ?);", values: [id, documentJson])
                } catch {
                    print("There was an error executing database queries or updates.")
                }
            }
        }
    }
    
    public func retrieveDocumentJSON(id : String, callback: @escaping (String?) -> ()) {
        queue.inDatabase { (database) in
            do {
                var jsonResult : String? = nil
                let results = try database.executeQuery("SELECT json FROM documents WHERE id = ?;", values: [id])
                if (results.next()) {
                    jsonResult = results.string(forColumn: "json")
                }
                results.close()
                callback(jsonResult)
            } catch {
                print("There was an error executing database queries or updates.")
                
            }
        }
    }
    
    public func retrieveDocumentJSONSynchronous(id : String) -> String? {
        var result : String?
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        DataStore.sharedDataStore.retrieveDocumentJSON(id: id, callback: { jsonResult in
            if let json = jsonResult {
                result = json
            }
            sema.signal()
        })
        let _ = sema.wait()
        return result
    }
    
    public func deleteDocument(id : String) {
        queue.inDatabase { (database) in
            do {
                try database.executeUpdate("DELETE FROM documents WHERE id = ?;", values: [id])
            } catch {
                print("There was an error executing database queries or updates.")
            }
        }
    }
    
    public func deleteDocumentsOfType(docType : String) {
        // Create semaphore to await results
        let sema = DispatchSemaphore(value: 0)
        var documentsJson : [JSON] = []
        
        self.queryDocumentStore(parameters: ("docType", docType)) { json in
            documentsJson = json
            sema.signal()
        }
        
        sema.wait()
        
        for docJson in documentsJson {
            if let id = docJson["id"].string {
                self.deleteDocument(id: id)
            }
        }
    }
    
    public func countQueryDocumentJSON(parameters : (property: String, value: Any)..., callback : @escaping (Int) -> ()) {
        queue.inDatabase { (database) in
            var count :Int = 0
            
            //Build WHERE clause(s)
            let (whereString, searchValues) = self.buildSQLWhereForJSONParams(parameters: parameters)
            
            //Run query
            do {
                let results = try database.executeQuery("SELECT count(id) as count FROM documents\(whereString)", values: searchValues)
                if (results.next()) {
                    count = Int(results.int(forColumn: "count"))
                }
                results.close()
            } catch {
                print("There was an error executing database queries or updates.")
            }
            callback(count);
        }
    }
    
    public func queryDocumentStore(parameters : (property: String, value: Any)..., callback : @escaping ([JSON]) -> ()) {
        queue.inDatabase { (database) in
            var documents = [JSON]()

            //Build WHERE clause(s)
            let (whereString, searchValues) = self.buildSQLWhereForJSONParams(parameters: parameters)
            
            //Run query
            do {
                let results = try database.executeQuery("SELECT json FROM documents\(whereString)", values: searchValues)
                
                while (results.next()) {
                    documents.append(JSON.init(parseJSON: results.string(forColumn: "json")!))
                }
                results.close()
            } catch {
                print("There was an error executing database queries or updates.")
            }
            callback(documents);
        }
    }
    
    public func queryDocumentStore(query : String, callback: @escaping ([JSON]) -> ()) {
        queue.inDatabase { (database) in
            var documents = [JSON]()
            
            //Run query
            do {
                let results = try database.executeQuery(query, values: nil)
                
                while (results.next()) {
                    documents.append(JSON.init(parseJSON: results.string(forColumn: "json")!))
                }
                results.close()
            } catch {
                print("There was an error executing database queries or updates.")
            }
            callback(documents);
        }
    }
    
    public func retrieveQueuedDocuments(callback: @escaping ([String]?) -> ()) {
        queue.inDatabase { (database) in   
            do {
                let results = try database.executeQuery("SELECT * FROM sync_queue", values: nil)
                var syncIds : [String] = []
                while (results.next()) {
                    let id = results.string(forColumn: "id")
                    syncIds.append(id!)
                }
                results.close()
                
                // For each ID get the json
                var documents : [String] = []
                for id in syncIds {
                    let docResult = try database.executeQuery("SELECT json FROM documents WHERE id = ?;", values:[id])
                    if (docResult.next()) {
                        let json = docResult.string(forColumn: "json")
                        documents.append(json!)
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
    
    private func buildSQLWhereForJSONParams(parameters:Array<(property: String, value: Any)>) ->(String, Array<String>) {
        
        /* FMDB warns against creating query strings without the use of their
         placeholder "?" because the code becomes susceptible to sql injection.
         So I jump through a few hoops to do that. There is likely a better way
         */
        
        var searchStrings = [String]()
        var searchValues = [String]()
        var whereString:String = ""
        
        for (property, value) in parameters {
            searchStrings.append("(json LIKE ?)") //for sql string

            if let str = value as? String {
                searchValues.append("%\"\(property)\":\"\(str)\"%") //for FMDB replacement variables
            } else {
                searchValues.append("%\(property)\":\(value)%") //for FMDB replacement variables
            }
        }
        if !searchStrings.isEmpty {
            whereString = " WHERE " + searchStrings.joined(separator: " and ")
        }
        return (whereString, searchValues)
    }
    
    public func resetDatabase() {
        let appDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = "\(appDir)/\(DataStore.databaseName)"
        try! FileManager.default.removeItem(atPath: dbPath)
        
        // Initialize the queue
        queue = FMDatabaseQueue(path: dbPath)!
        
        // Get and unwrap instance of BRDatabase
        let sharedDatabase = BRDatabase.sharedBRDatabase
        
        // Re-init the db
        sharedDatabase.initialize(databaseName: DataStore.databaseName, databaseVersion: 0.0, success: nil)
        print("SQLite path is \(String(describing: sharedDatabase.databasePath))")
    }
}
