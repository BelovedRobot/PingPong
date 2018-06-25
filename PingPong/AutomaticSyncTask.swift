//
//  AutomaticSyncTask.swift
//  Alamofire
//
//  Created by Zane Kellogg on 6/25/18.
//

import Foundation

public enum AutomaticSyncOrder {
    case beforeDocumentSync
    case afterDocumentsSync
}

public protocol AutomaticSyncTask {
    // This variable declares whether it is run before or after the document syncs
    var order : AutomaticSyncOrder { get }
    
    // This function is what PingPong will call when performing the sync
    func sync(success: (()->())?)
}
