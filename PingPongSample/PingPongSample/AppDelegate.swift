//
//  AppDelegate.swift
//  CandidateInterview
//
//  Created by Zane Kellogg on 6/21/17.
//  Copyright © 2017 Beloved Robot. All rights reserved.
//

import UIKit
import PingPong

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Configure and Start PingPong 🏓
        let syncTasks = [ FetchTeams() ]

        PingPong.shared.start(documentEndpoint: Constants.documentEndpoint, authorizationToken: Constants.authorizationToken, backGroundSyncInterval: 30, syncTasks: syncTasks)

//        if CommandLine.arguments.contains("--uitesting") {
//            DataStore.sharedDataStore = MockDataStore()
//        }

        return true
    }
}

