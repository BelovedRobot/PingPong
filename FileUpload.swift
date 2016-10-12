//
//  FileUpload.swift
//  Deshazo
//
//  Created by Zane Kellogg on 7/5/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class FileUpload : StashObject {
    // The data will be used by the API to associate the upload with the right document.
    var docType : String = "fileUpload";
    var localFilePath : String = ""; // This path will very likely have a ~ in it...meaning it needs to be expanded
    var targetId : String = "";
    var targetDocType : String = "";
    var targetProperty : String = "";
    var subTargetId : String = "";
    var subTargetDocType : String = "";
    var subTargetProperty : String = "";
    
    override init() {
        super.init()
        self.id = NSUUID().UUIDString
    }
    
    init(localFilePath : String, targetId : String, targetDocType : String, targetProperty : String) {
        super.init()
        self.id = NSUUID().UUIDString
        
        self.localFilePath = localFilePath
        self.targetId = targetId
        self.targetDocType = targetDocType
        self.targetProperty = targetProperty
    }
}