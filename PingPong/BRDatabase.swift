//
//  BRDatabase.swift
//  PingPong
//
//  Created by Juan Manuel Pereira on 8/11/17.
//  Copyright © 2017 Beloved Robot. All rights reserved.
//

import Foundation
import FMDB

class BRDatabase {

    static let sharedBRDatabase = BRDatabase()

    var databaseVersion: Float = 0.0
    var scripts = [String: String]()
    var databasePath: String?
    var database: FMDatabase?
    var databaseQueue: FMDatabaseQueue?

    private init() {}

    func dropExistingDatabase(databaseName: String) {
        let dbPath = self.getDatabasePathWithName(databaseName: databaseName)

        do {
            try FileManager.default.removeItem(atPath: dbPath)
        } catch  {
            print("There was an error deleting the database.")
        }
    }

    func initialize(databaseName: String, databaseVersion: Float, success: (() -> Void)?) {
        self.databaseVersion = databaseVersion
        self.scripts = self.getScriptsFromBundle()
        self.databasePath = self.getDatabasePathWithName(databaseName: databaseName)
        self.database = self.initializeFMDatabaseInstance()

        let needsToUpgrade = self.databaseDoesNeedUpgradeFromVersion()

        if !needsToUpgrade {
            if let success = success {
                success()
            }

            return
        }

        let versionsNeeded = self.getVersionsToUpgradeToFromOldVersion()

        self.executeUpgradesWithVersions(versions: versionsNeeded)

        print("Database version is: ", self.getCurentDatabaseVersion())

        self.databaseQueue = FMDatabaseQueue.init(path: self.databasePath)

        if let success = success {
            success()
        }
    }

    private func executeUpgradesWithVersions(versions: [String]) {
        versions.forEach { (version) in
            if let database = self.database {
                database.open()

                let upgradeScript = self.getStringFromScriptAt(path: self.scripts[version]!)
                let success = database.executeStatements(upgradeScript)

                if !success {
                    print("Update failed.")
                }
            } else {
                print("Error not intialized.")
            }
        }
    }

    private func getVersionsToUpgradeToFromOldVersion() -> [String] {
        let actualDatabaseVersion = self.getCurentDatabaseVersion()
        var versionsNeeded = [String]()

        let sortedKeys = self.scripts.keys.sorted { (obj1, obj2) -> Bool in
            let float1 = Float(obj1)
            let float2 = Float(obj2)

            return float1! > float2!
        }

        sortedKeys.forEach { (version) in
            let candidateVersion = Float(version)

            if (Float(actualDatabaseVersion) < candidateVersion! && candidateVersion! <= self.databaseVersion) {
                versionsNeeded.append(version)
            }
        }

        return versionsNeeded
    }

    private func databaseDoesNeedUpgradeFromVersion() -> Bool {
        let actualDatabaseVersion = self.getCurentDatabaseVersion()

        return actualDatabaseVersion < Double(self.databaseVersion)
    }

    private func getCurentDatabaseVersion() -> Double {
        if let database = self.database {
            var returnValue: Double = -1

            database.open()

            do {
                let result =  try database.executeQuery("SELECT databaseVersion FROM Version ORDER BY versionID DESC LIMIT 1;", values: nil)

                if result.next() {
                    returnValue = result.double(forColumnIndex: 0)
                }

                result.close()
                database.close()

                return returnValue
            } catch {
                print("Error getting databaseVersion")
                return -1
            }
        } else {
            print("Database not initialized")
            return -1
        }
    }

    private func initializeFMDatabaseInstance() -> FMDatabase {
        let fileExists = FileManager.default.fileExists(atPath: self.databasePath!)

        if !fileExists {
            let database = FMDatabase.init(path: self.databasePath)

            if database.open() {
                print("Opening the new db was successful")
                let installScript = self.getStringFromScriptAt(path: self.scripts["0.0"]!)
                let success = database.executeStatements(installScript)

                if !success {
                    print("Update failed")
                }
            }

            database.close()
        }

        return FMDatabase.init(path: databasePath)
    }

    private func getStringFromScriptAt(path: String) -> String {
        let frameworkBundle = Bundle(for: PingPong.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PingPong.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        let bundlePath = String.init(format: "%@/%@", resourceBundle!.bundlePath, path)
        if let string = try? String.init(contentsOfFile: bundlePath) { return string }

        return ""
    }

    private func getDatabasePathWithName(databaseName: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docsPath = paths[0]

        return docsPath.appending("/" + databaseName)
    }

    private func getScriptsFromBundle() -> [String: String] {
        let fileManager = FileManager.default
        var scriptsPath = [String: String]()

        do {
            let frameworkBundle = Bundle(for: PingPong.self)
            let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("PingPong.bundle")
            let resourceBundle = Bundle(url: bundleURL!)
            let contents = try fileManager.contentsOfDirectory(atPath: resourceBundle!.bundlePath)
            let scripts = contents.filter({ $0.hasSuffix(".sql") })
            scripts.forEach({ (path) in
                if path.range(of: "DatabaseInstall") != nil {
                    scriptsPath["0.0"] = path
                } else {
                    let parts = path.components(separatedBy: "_")

                    if (parts.count > 1) {
                        let major = parts[0]
                        let minor = parts[1]
                        let key = major + "." + minor
                        scriptsPath[key] = path
                    }
                }
            })
        } catch {
            print("Error getting the scripts")
        }
        
        return scriptsPath
    }
}
