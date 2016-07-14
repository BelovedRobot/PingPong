//
//  BRDatabase.h
//  FMDB_CocoaPods
//
//  Created by Zane Kellogg on 10/17/13.
//  Copyright (c) 2013 Beloved Robot LLC. All rights reserved.
//
// Purpose: This class is meant to be a single gateway to FMDB app-wide.
// I'm not completely sure this is a good idea or even necessary. My goals
// are to 1) provide a simple way to version the database, 2) limit access
// to a single FMDatabase/FMDatabaseQueue to prevent database collisions and
// 3) to have a single place to get the database path, name, version,
// instance, etc without using Interface Builder or the AppDelegate.

#import <Foundation/Foundation.h>
#import "FMDatabaseQueue.h"

@interface BRDatabase : NSObject

@property (strong) FMDatabase *database;
@property (strong) FMDatabaseQueue *databaseQueue;
@property (strong) NSString *databasePath;
@property float databaseVersion;
@property (strong) NSDictionary *scripts;

+ (id)sharedBRDatabase;
- (void)dropExistingDatabase:(NSString *)databaseName;
- (void)initializeWithDatabaseName:(NSString *)databaseName withDatabaseVersion:(float)databaseVersion withSuccess:(void (^)())success;

@end
