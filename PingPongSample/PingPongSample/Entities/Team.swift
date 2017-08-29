import PingPong

class Team: SyncObject {

    var docType = "team"
    var name: String = ""
    var nickname: String = ""
    var primaryColor: String = ""
    var sport: String = ""
    var players = [String]()

    override func fromJSON(json: String) {
        super.fromJSON(json: json)

        if let players = self.deserializationExceptions["players"]?.array {
            for player in players {
                self.players.append(player.rawString()!)
            }
        }
    }
}
