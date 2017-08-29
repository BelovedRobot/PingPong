//
//  FetchTeams.swift
//  CandidateInterview
//
//  Created by Zane Kellogg on 6/21/17.
//  Copyright © 2017 Beloved Robot. All rights reserved.
//

import Foundation
import PingPong
import Alamofire
import SwiftyJSON

protocol FetchTeamsSyncProtocol {
    func onTeamsSync(team: [Team])
}

class FetchTeams : SyncTask {
    var docType: String? = ""
    var automaticTask: Bool = true

    func sync(jsonString: String?, success: (() -> ())?) {
        let headerDict = [
            "Authorization" : "Token token=\(PingPong.shared.authorizationToken)"
        ]

        let url = "\(PingPong.shared.documentEndpoint)/document/type/team"

        request(url, headers: headerDict)
            .validate()
            .response(
                responseSerializer: DataRequest.jsonResponseSerializer(),
                completionHandler: { response in
                    self.onRequestResponse(result: response.result, success: success)
            }
        )
    }

    private func onRequestResponse(result: Result<Any>, success: (() -> ())?) {
        DispatchQueue.backgroundQueue.async {
            switch result {
            case .success(let value):
                self.parseResponse(value: value)
                success?()
            case .failure(let error):
                print("Fetch Contacts: \(error)")
                success?()
            }
        }
    }

    private func parseResponse(value: Any) {
        let jsonTeams = JSON(value)

        jsonTeams.forEach { (string, json) in
            let team = Team()
            team.fromJSON(json: json.rawString()!)

            team.safeStashFromCloud()
        }

        NotificationCenter.default.post(name: Notification.Name("NewTeamsNotification"), object: nil)
    }
}
