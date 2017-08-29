//
//  TeamsViewController.swift
//  CandidateInterview
//
//  Created by Zane Kellogg on 6/21/17.
//  Copyright © 2017 Beloved Robot. All rights reserved.
//

import UIKit
import PingPong
import SwiftyJSON

class TeamsViewController: UIViewController {

    fileprivate let teamIdentifier = "teamsTableViewCellIdentifier"
    fileprivate let teamDetailSegueIdentifier = "teamDetailViewSegueIdentifier"
    fileprivate let createTeamSegueIdentifier = "createTeamSegueIdentifier"

    fileprivate var teams = [Team]()
    fileprivate var selectedTeam: Team?

    private var refreshControl: UIRefreshControl!

    @IBOutlet weak var teamsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupToolbar()
        setupTeamsTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getTeams), name: Notification.Name("NewTeamsNotification"), object: nil)

        getTeams()
    }

    private func setupToolbar() {
        let addButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(onAddTeamAction))
        self.navigationItem.rightBarButtonItem = addButton
        self.title = "Teams"
    }

    private func setupTeamsTableView() {
        teamsTableView.delegate = self
        teamsTableView.dataSource = self

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        teamsTableView.addSubview(refreshControl)
    }

    private func parseFromStorage(teams: [JSON]) {
        self.teams.removeAll()

        teams.forEach { (json) in
            let team = Team()
            team.fromJSON(json: json.rawString()!)


            self.teams.append(team)
        }

        self.teams.sort { (teamA, teamB) -> Bool in
            teamA.name < teamB.name
        }

        self.teamsTableView.reloadData()
    }

    public func onAddTeamAction() {
        performSegue(withIdentifier: createTeamSegueIdentifier, sender: nil)
    }

    public func getTeams() {
        DataStore.sharedDataStore.queryDocumentStore(parameters: (property: "docType", value: "team")) { (teams) in
            DispatchQueue.main.async(){
                self.parseFromStorage(teams: teams)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == teamDetailSegueIdentifier) {
            let destinationViewController = segue.destination as! DetailTeamViewController
            destinationViewController.team = self.selectedTeam
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("NewTeamsNotification"), object: nil)
    }

    func handleRefresh() {
        PingPong.shared.backgroundSync.manualSync()
        refreshControl.endRefreshing()
    }
}

extension TeamsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: teamIdentifier)
        let team = teams[indexPath.row]

        if let cell = cell {
            return setupCellWithTeam(cell: cell, team: team)
        } else {
            let newCell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: teamIdentifier)

            return setupCellWithTeam(cell: newCell, team: team)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if teams.isEmpty {
            showEmptyTeamsLabel()
            return 0
        } else {
            teamsTableView.backgroundView = nil
            return teams.count
        }
    }

    private func showEmptyTeamsLabel() {
        let noTeamsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: teamsTableView.bounds.size.width, height: teamsTableView.bounds.size.height))
        noTeamsLabel.text          = "No teams available!"
        noTeamsLabel.textColor     = UIColor.black
        noTeamsLabel.textAlignment = .center
        teamsTableView.backgroundView  = noTeamsLabel
        teamsTableView.separatorStyle  = .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedTeam = self.teams[indexPath.row]
        self.performSegue(withIdentifier: teamDetailSegueIdentifier, sender: nil)
    }

    private func setupCellWithTeam(cell: UITableViewCell, team: Team) -> UITableViewCell {
        cell.textLabel!.text = team.name
        cell.detailTextLabel!.text = team.sport

        return cell
    }
}
