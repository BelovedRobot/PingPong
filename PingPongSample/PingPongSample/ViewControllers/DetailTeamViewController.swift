import Foundation
import UIKit

class DetailTeamViewController: BaseViewController {

    fileprivate let playerIdentifier = "playerTableViewCellIdentifier"

    @IBOutlet weak var teamNameLbl: UILabel!
    @IBOutlet weak var sportLbl: UILabel!
    @IBOutlet weak var nicknameLbl: UILabel!
    @IBOutlet weak var primaryColorLbl: UILabel!
    @IBOutlet weak var playersTableView: UITableView!

    var team: Team?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Team detail"
        self.loadUI()
    }

    private func loadUI() {
        if let team = self.team {
            self.loadTeamUI(team: team)
            self.setupTableView()
        } else {
            self.showTeamNotSetError()
        }
    }

    private func setupTableView() {
        self.playersTableView.delegate = self
        self.playersTableView.dataSource = self

        self.playersTableView.reloadData()
    }

    private func loadTeamUI(team: Team) {
        self.teamNameLbl.text = team.name
        self.sportLbl.text = team.sport
        self.nicknameLbl.text = team.nickname
        self.primaryColorLbl.text = team.primaryColor

    }

    private func showTeamNotSetError() {
        showMessage(title: "Error!", message: "Team not set.", completion: { () in
            self.navigationController?.popViewController(animated: true)
        })
    }
}

extension DetailTeamViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerIdentifier)
        let player = self.team!.players[indexPath.row]

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
        return self.team!.players.count
    }
}


