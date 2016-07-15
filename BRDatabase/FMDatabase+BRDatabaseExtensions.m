////
////  FMDatabase+BRDatabaseManager.m
////  FMDB_CocoaPods
////
////  Created by Zane Kellogg on 10/16/13.
////  Copyright (c) 2013 Beloved Robot LLC. All rights reserved.
////
//
//#import "FMDatabase+BRDatabaseExtensions.h"
//
//@implementation FMDatabase (FMDatabase_BRDatabaseExtensions)
//
//- (BOOL)executeBatchWithSqlScript:(NSString *)sql outError:(NSError**)error;
//{
//    char* errorOutput;
//    int responseCode = sqlite3_exec([self sqliteHandle], [sql UTF8String], NULL, NULL, &errorOutput);
//    
//    if (errorOutput != nil)
//    {
//        *error = [NSError errorWithDomain:[NSString stringWithUTF8String:errorOutput] code:responseCode userInfo:nil];
//        return false;
//    }
//    
//    return true;
//}
//
//@end
