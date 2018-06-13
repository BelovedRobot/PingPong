//
//  SyncTask.swift
//
//  Created by Zane Kellogg on 11/16/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

public protocol SyncTask {
    // Sets whether the task will be performed for every background sync. It automaticTask is set to true than everytime PingPong syncs it will
    // execute this task. If it is set to false the task will only be executive if a document of the specified type (see docType) is in the sync 
    // queue
    var automaticTask : Bool { get set }
    
    // The docType field specifies what document type this sync task is associated with. The field is option because some background
    // sync tasks are associated with documents and some are simply tasks to run for every sync
    var docType : String? { get set }
    
    // This function is what PingPong will call when performing the sync
    func sync(jsonString: String?, success: (()->())?)
}
