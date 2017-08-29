class MockDataStore: DataStoreProtocol {

    static var sharedDataStore: DataStoreProtocol = MockDataStore()
    
    private var teamsArray = [JSON]()

    func stashObjects(objects: [StashObject]) -> Bool {
        return true
    }

    func addDocumentToSyncQueue(documentId : String) {
    }

    func hasPendingSync(documentId : String) -> Bool {
        return false
    }

    func removeDocumentFromSyncQueue(documentId : String) {
    }

    func removeOrphanedSyncQueueEntries() {
    }

    func stashDocument(documentJson : String) {
        self.teamsArray.append(JSON.parse(documentJson))
    }

    func retrieveDocumentJSON(id : String, callback: @escaping (String?) -> ()) {
    }

    func retrieveDocumentJSONSynchronous(id : String) -> String? {
        return ""
    }

    func deleteDocument(id : String) {
    }

    func deleteDocumentsOfType(docType : String) {
    }

    func countQueryDocumentJSON(parameters : (property: String, value: Any)..., callback : @escaping (Int) -> ()) {

    }

    func queryDocumentStore(parameters : (property: String, value: Any)..., callback : @escaping ([JSON]) -> ()) {
        if (teamsArray.isEmpty) {
            generateTeams()
        }

        let property = parameters[0].property
        let value = parameters[0].value as! String

        if (property == "docType" && value == "team") {
            callback(self.teamsArray)
        }
    }

    private func generateTeams() {
        self.teamsArray.removeAll()

        for index in 0...2 {
            let team = Team()
            team.name = "Test" + String(index)
            team.nickname = "TestNickname" + String(index)
            team.sport = "TestSport" + String(index)
            team.primaryColor = "TestColor" + String(index)
            team.players.append("Player" + String(index))

            self.teamsArray.append(JSON.parse(team.toJSON()))
        }
    }

    func retrieveQueuedDocuments(callback: @escaping ([String]?) -> ()) {
    }
}
