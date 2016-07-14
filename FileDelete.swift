//
//  FileDelete.swift
//  Deshazo
//
//  Created by Zane Kellogg on 7/6/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

class FileDelete : StashObject {
    // The data will be used by the API to associate the upload with the right document.
    var docType : String = "fileDelete";
    var fileUrl : String = "";
    
    override init() {
        super.init()
        self.id = NSUUID().UUIDString
    }
    
    init(fileUrl : String) {
        super.init()
        self.id = NSUUID().UUIDString
        
        self.fileUrl = fileUrl
    }
}