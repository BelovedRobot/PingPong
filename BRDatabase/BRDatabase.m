//
//  BRDatabase.m
//  FMDB_CocoaPods
//
//  Created by Zane Kellogg on 10/17/13.
//  Copyright (c) 2013 Beloved Robot LLC. All rights reserved.
//
// Implementation Notes: There are several specific things that must be done to properly upgrade a database using this framework.
// 1) There should be a folder titled "Scripts" in the project that will be deployed when the app is bundled/installed.
// 2) Your database should be defined in a script titled "DatabaseInstall.sql"
//   2.1) There should be a table called "Version" that has a databaseVersion INT column.
//        Example Script: CREATE TABLE Version (versionId INTEGER PRIMARY KEY ASC, databaseVersion INT, description TEXT);
// 3) The variables in this file should specify which target version the application is expecting.
//   3.1) Set the databaseVersion property to the version the application is expecting.
//   3.2) When upgrading, add the version to the array defined in getDatabaseVersionHistory.
// 4) The actual upgrade script should be included in this project.
//   4.1) Each version of the database should include a database script with the file name format
//        "<major version>_<minor version><revision>_upgrade.sql".
//        Example Script: To upgrade the database to version 1.2.3 the script would be "1_23_upgrade.sql".
//   4.2) The minor version and revision only support single digits, 0 - 9.
//   4.3) The script files should be set to be copied into bundled resources.
//

#import "BRDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDB.h"

@implementation BRDatabase

@synthesize database = _database;
@synthesize databaseQueue = _databaseQueue;
@synthesize databasePath = _databasePath;
@synthesize databaseVersion = _databaseVersion;
@synthesize scripts = _scripts;

+ (id)sharedBRDatabase {
    static BRDatabase *sharedBRDatabase = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBRDatabase = [[self alloc] init];
    });
    return sharedBRDatabase;
}

- (void)dropExistingDatabase:(NSString *)databaseName {
    NSString *dbPath = [self getDatabasePathWithDatabaseName:databaseName];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:&error];
    
    if (error) {
        NSLog(@"There was an error deleting the database.");
    }
}

- (void)initializeWithDatabaseName:(NSString *)databaseName withDatabaseVersion:(float)databaseVersion withSuccess:(void (^)())success {
    // 1 - Set Version
    _databaseVersion = databaseVersion;
    
    // 2 - Parse Script Files
    _scripts = [self getScriptsFromBundle];
    
    // 3 - Get path of database file
    _databasePath = [self getDatabasePathWithDatabaseName:databaseName];
    
    // 4 - See if the database exists then create FMDatabase instance
    _database = [self initializeFMDatabaseInstance];
    
    // 5 - Check version
    float actualDatabaseVersion;
    bool needsToUpgrade = [self databaseDoesNeedUpgradeFromVersion:&actualDatabaseVersion];
    
    if (!needsToUpgrade) {
        // Execute Success Block
        if (success)
            success();

        NSLog(@"Database version is %.01f", [self getCurrentDatabaseVersion]);
        return;
    }
    
    // 6 - Detarmine which versions are necessary for upgrade
    NSArray *versionsNeeded = [self getVersionsToUpgradeToFromOldVersion:actualDatabaseVersion];
    
    // 7 - Iterate versions and execute upgrades
    [self executeUpgradesWithVersions:versionsNeeded];
    
    NSLog(@"Database version is %0.01f", [self getCurrentDatabaseVersion]);
    
    // 8 - Init the database queue
    _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:_databasePath];
    
    // Execute Success Block
    if (success)
        success();
}

// This method builds the database path with name.
- (NSString *)getDatabasePathWithDatabaseName:(NSString *)databaseName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    return [docsPath stringByAppendingPathComponent:databaseName];
}

// This method initializes an instance of FMDatabase. If the database is new the
// installation script is run against it.
- (FMDatabase *)initializeFMDatabaseInstance {
    FMDatabase* database;

    // If the file does not exist then this is a new installation. We need to run the install script.
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:_databasePath];
    if (!fileExists) {
        
        // The database does not exist so create it
        database = [FMDatabase databaseWithPath:_databasePath];
        
        if ([database open]) {
            NSLog(@"Opening the new db was successful");
        
            // Get the Database Install
            NSString *installScript = [self getStringFromScriptPath:[_scripts objectForKey:@"0.0"]];
            
            bool success = [database executeStatements:installScript];
            if (!success) {
                NSLog(@"Update failed");
            }
        }
        
        [database close];
    }
    
    // Re-init the database, since it may have already existed
    return[FMDatabase databaseWithPath:_databasePath];
}

// This method executes a script on the current database to determine the version and then compares
// it to the version specified by the property "databaseVersion".
- (BOOL)databaseDoesNeedUpgradeFromVersion:(float *)actualDatabaseVersion {

    // For each version of the database we insert a row, if the version of the latest is less than the
    // version hard specified by this file then we need an upgrade.
    *actualDatabaseVersion = [self getCurrentDatabaseVersion];
    return *actualDatabaseVersion < _databaseVersion;
}

// This method returns an array of database versions that need to be upgraded to.
- (NSArray *)getVersionsToUpgradeToFromOldVersion:(float)actualVersion {
    NSMutableArray *versionsNeeded = [NSMutableArray new];
    
    // Sort the script keys (versions) in ascending order
    NSArray *sortedKeys = [[_scripts allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 floatValue] > [(NSString *)obj2 floatValue];
    }];
    
    for (NSString *version in sortedKeys) {
        float candidateVersion = [version floatValue];
        if (actualVersion < candidateVersion && candidateVersion <= _databaseVersion) {
            [versionsNeeded addObject:version];
        }
    }
    
    return [NSArray arrayWithArray:versionsNeeded];
}

// This method will iterate the versioning scripts and execute them.
- (BOOL)executeUpgradesWithVersions:(NSArray*)versions {
    for (NSString *version in versions) {
        [_database open];
        
        NSString *upgradeScript = [self getStringFromScriptPath:[_scripts objectForKey:version]];
        
        bool success = [_database executeStatements:upgradeScript];
        if (!success)
            NSLog(@"Update failed.");
        
        [_database close];
    }
    
    return true;
}

// This method parses all of the sql files in the app bundle (root) and builds a hashtable of all the versions. With 0.0 being
// the database install.
- (NSDictionary *)getScriptsFromBundle {
    // Get all *.sql files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:nil];
    NSPredicate *sqlPredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sql'"];
    NSArray *scripts = [contents filteredArrayUsingPredicate:sqlPredicate];
    
    // The results
    NSMutableDictionary *scriptPaths = [NSMutableDictionary new];
    
    // Parse each path
    for (NSString *path in scripts) {

        // Check for Install Script
        NSRange range = [path rangeOfString:@"DatabaseInstall"];
        if (range.location != NSNotFound) {
            [scriptPaths setObject:path forKey:@"0.0"];
            continue;
        }
        
        // Parse the version
        NSArray *parts = [path componentsSeparatedByString:@"_"];
        NSString *major = [parts objectAtIndex:0];
        NSString *minor =[parts objectAtIndex:1];
        
        if (major == nil || minor == nil) {
            continue;
        }
        
        [scriptPaths setObject:path forKey:[NSString stringWithFormat:@"%@.%@", major, minor]];
    }

    return [NSDictionary dictionaryWithDictionary:scriptPaths];
}

// The method simply converts the contents of the script file to a string for execution
- (NSString *)getStringFromScriptPath:(NSString *)path {
    NSString *bundledPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], path];
    return [NSString stringWithContentsOfFile:bundledPath encoding:NSUTF8StringEncoding error:nil];
}

// This method calls the existing database and pulls the last verion
- (double)getCurrentDatabaseVersion {
    double returnValue = -1;

    [_database open];
    FMResultSet *result = [_database executeQuery:@"SELECT databaseVersion FROM Version ORDER BY versionID DESC LIMIT 1;"];
    if ([result next]) {
        returnValue = [result doubleForColumnIndex:0];
    }
    [result close];
    [_database close];
    
    return returnValue;
}

@end
