//
//  DataService.swift
//  Deshazo
//
//  Created by Zane Kellogg on 5/21/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation
import Alamofire

class DataService {
    
    static var sharedService : DataService = DataService();
    
    init() {}
    
    // Called to retrieve the bulk of information for technicians
    func getTechnicianData(technicianId : String, progressBar: UIProgressView, success : (((technician:User, tickets:[Ticket], completedTickets:Int, hours:Double )) -> ())? ) {
        if technicianId == "" {
            return;
        }
        
        let headerDict = [
            "Authorization" : "Token token=\(Globals.authToken)"
        ];
        
        let getUrl = "\(Globals.endpointUrl)/app/technician/\(technicianId)";
        
        let request = Alamofire.request(.GET, getUrl, parameters: nil, headers: headerDict)
        
        request.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
            print(totalBytesRead)
            dispatch_async(dispatch_get_main_queue()) {
                let progress = request.progress.fractionCompleted
                progressBar.setProgress(Float(progress), animated: true)
                print(progress)
            }
        }
        
        request.responseJSON { response in
//                print(response.request)  // original URL request
//                print(response.response) // URL response
//                print(response.data)     // server data
//                print(response.result)   // result of response serialization
                
                switch response.result {
                    case .Success:
                        if let value = response.result.value {
                            let json = JSON(value)

                            // Map the technician
                            let techJson = json["technician"];
                            let tech : User = User()
                            tech.fromJSON(techJson.rawString()!)
                            
                            // Map the tickets
                            var tickets : [Ticket] = []
                            if let ticketsJson = json["tickets"].array {
                                for ticketJson in ticketsJson {
                                    let ticket = Ticket()
                                    ticket.fromJSON(ticketJson.rawString()!)
                                    tickets.append(ticket)
                                }
                            }
                            
                            // Map the completed tickets
                            let completedTickets = json["completedTickets"].int ?? 0;
                            
                            // Map the hours
                            let hours = json["hours"].double ?? 0;
                            
                            let returnObj = (tech, tickets, completedTickets, hours);
                            if let callableSuccess = success {
                                callableSuccess(returnObj)
                            }
                        }
                    case .Failure(let error):
                        print(error)
                }
        }
    }

    // Called to retrieve list of all technicians
    func getTechnicians(success : ((technicians : [User]) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(Globals.authToken)"
        ];
        
        let getUrl = "\(Globals.endpointUrl)/technicians";
        
        Alamofire.request(.GET, getUrl, parameters: nil, headers: headerDict)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    var result : [User] = []
                    // Does response have a valid value
                    if let value = response.result.value {
                        // Can parse the json as an array of techs
                        if let techsJson = JSON(value).array {
                            // Deserialize the data
                            for techJson in techsJson {
                                let technician = User()
                                technician.fromJSON(techJson.rawString()!)
                                result.append(technician)
                            }
                        }
                    }
                    
                    // Return techs
                    if let callableSuccess = success {
                        callableSuccess(technicians: result)
                    }
                case .Failure(let error):
                    print(error)
                }
        }
    }
    
    // Called to retrieve list of all cranes
    func getCranes(success : ((cranes : [Crane]) -> ())? ) {
        let headerDict = [
            "Authorization" : "Token token=\(Globals.authToken)"
        ];
        
        let getUrl = "\(Globals.endpointUrl)/cranes";
        
        Alamofire.request(.GET, getUrl, parameters: nil, headers: headerDict)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    var result : [Crane] = []
                    // Does response have a valid value
                    if let value = response.result.value {
                        // Can parse the json as an array of cranes
                        if let cranesJson = JSON(value).array {
                            // Deserialize the data
                            for craneJson in cranesJson {
                                let crane = Crane()
                                crane.fromJSON(craneJson.rawString()!)
                                result.append(crane)
                            }
                        }
                    }
                    
                    // Return techs
                    if let callableSuccess = success {
                        callableSuccess(cranes: result)
                    }
                case .Failure(let error):
                    print(error)
                }
        }

    }

}