//
//  SyncTask.swift
//
//  Created by Zane Kellogg on 11/16/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

public protocol SyncTask {
    // The docType field specifies what document type this sync task is associated with. The field is option because some background
    // sync tasks are associated with documents and some are simply tasks to run for every sync
    var docType : String? { get set }
    
    // This function is what PingPong will call when performing the sync
    func sync(jsonString: String?, success: (()->())?)
}
