import Foundation
import UIKit
import PingPong

class CreateTeamViewController: BaseViewController {

    fileprivate let playerIdentifier = "playerTableViewCellIdentifier"

    @IBOutlet weak var teamNameTextField: UITextField!
    @IBOutlet weak var sportTextField: UITextField!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var primaryColorTextField: UITextField!
    @IBOutlet weak var playersTableView: UITableView!
    @IBOutlet weak var playerTextField: UITextField!

    fileprivate var players = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Create team"
        self.setupTableView()
    }

    @IBAction func OnSaveTeamAction(_ sender: UIButton) {
        if (areFieldsValid()) {
            createTeam()
            showSuccessMessage()
        } else {
            showMessage(title: "Error!", message: "Fields cannot be empty", completion: nil)
        }
    }

    @IBAction func OnAddPlayerAction(_ sender: Any) {
        if (!self.playerTextField.text!.isEmpty) {
            self.players.append(self.playerTextField.text!)
            self.playerTextField.text = ""
            self.playersTableView.reloadData()
        }
    }

    private func setupTableView() {
        self.playersTableView.delegate = self
        self.playersTableView.dataSource = self
    }

    private func createTeam() {
        let team = Team()
        team.name = teamNameTextField.text!
        team.sport = sportTextField.text!
        team.nickname = nicknameTextField.text!
        team.primaryColor = primaryColorTextField.text!
        team.id = UUID().uuidString.lowercased()
        team.players = self.players

        team.saveEventually()
    }

    private func showSuccessMessage() {
        showMessage(title: "Success", message: "Team created successfully") {
            self.navigationController?.popViewController(animated: false)
        }
    }

    private func areFieldsValid() -> Bool {
        return !teamNameTextField.text!.isEmpty && !sportTextField.text!.isEmpty && !nicknameTextField.text!.isEmpty && !primaryColorTextField!.text!.isEmpty
    }

}

extension CreateTeamViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerIdentifier)
        let player = self.players[indexPath.row]

        if let cell = cell {
            cell.textLabel?.text = player
            return cell
        } else {
            let newCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: playerIdentifier)
            newCell.textLabel?.text = player

            return newCell
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.players.count
    }
}

