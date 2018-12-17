//
//  Syncable.swift
//  Alamofire
//
//  Created by Zane Kellogg on 12/1/18.
//

import Foundation
import Alamofire

public protocol Syncable : Codable {
    init(docType: String)
    
    var docType: String { get }
    
    var id: String { get set }
    
    var synced : Bool { get set }
    
    var deleted : Bool { get set }
}
