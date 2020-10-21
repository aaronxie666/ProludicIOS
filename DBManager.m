//
//  DBManager.m
//  Proludic
//
//  Created by Geoff Baker on 21/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBManager.h"

static DBManager *sharedInstance = nil;
static sqlite3 *database = nil;
static sqlite3_stmt *statement = nil;

@implementation DBManager

+(DBManager*)getSharedInstance{
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:NULL]init];
        //[sharedInstance createDB];
    }
    return sharedInstance;
}

-(BOOL)createDB{
    NSString *docsDir;
    NSArray *dirPaths;
    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:
                    [docsDir stringByAppendingPathComponent: @"ExercisesDB.db"]];
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
        
        const char *dbpath = [databasePath UTF8String];
        if (sqlite3_open(dbpath, &database) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt =
            "create table if not exists ExercisesDB (ExerciseObjId text primary key, ExerciseName text, NumRepeat integer)";
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg)
                != SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table --------------");
            }
            sqlite3_close(database);
            NSLog(@"Success to create table --------------");
            return  isSuccess;
        }
        else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database -----------");
        }
    } else { // already created
        isSuccess = NO;
    }
    return isSuccess;
}

- (BOOL) saveData:(NSString*)exerciseObjId :(NSString*)name :(int) NumRepeat
{
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into ExercisesDB (ExerciseObjId, ExerciseName, NumRepeat) values (\"%@\",\"%@\",\"%d\")",exerciseObjId, name, NumRepeat];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            sqlite3_finalize(statement);
            return YES;
        }
        else {
            sqlite3_finalize(statement);
            return NO;
        }
    }
    return NO;
}
- (BOOL) updateData:(NSString*)exerciseObjId :(int) NumRepeat
{
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *updateSQL = [NSString stringWithFormat:@"update ExercisesDB set NumRepeat = \"%d\" where ExerciseObjId=\"%@\"",NumRepeat, exerciseObjId];
        NSLog(@"%@", updateSQL);
        const char *update_stmt = [updateSQL UTF8String];
        sqlite3_prepare_v2(database, update_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            sqlite3_finalize(statement);
            return YES;
        }
        else {
            NSLog(@"Error %s while preparing statement", sqlite3_errmsg(database));
            sqlite3_finalize(statement);
            return NO;
        }
    }
    return NO;
}

- (NSArray*) findNumRepeat:(NSString*)ExerciseObjectId
{
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select NumRepeat from ExercisesDB where ExerciseObjId=\"%@\"",ExerciseObjectId];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(database,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                
                int numRepeat = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)] intValue];
                [resultArray addObject:[NSNumber numberWithInt:numRepeat]];
                sqlite3_finalize(statement);
                return resultArray;
            }
            else{
                NSLog(@"Not found");
                sqlite3_finalize(statement);
                return nil;
            }
            
        }
    }
    return nil;
}

- (NSArray*) showTable
{
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select * from ExercisesDB order by NumRepeat DESC"];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(database,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *objectId = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                
                int numRepeat = [[[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 2)] intValue];
                
                id objects[] = { objectId, @(numRepeat)};
                id keys[] = { @"exerciseObjId",  @"exerciseNumRepeat"};
                NSUInteger count = sizeof(objects) / sizeof(id);
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects
                                                                       forKeys:keys
                                                                         count:count];
                [resultArray addObject:dictionary];
                
            }
            sqlite3_finalize(statement);
            return resultArray;
            
        } else {
            NSLog(@"Error %s while preparing statement", sqlite3_errmsg(database));
        }
    }
    return nil;
}

- (BOOL) deleteData
{
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *deleteSQL = @"delete from ExercisesDB";
        const char *delete_stmt = [deleteSQL UTF8String];
        sqlite3_prepare_v2(database, delete_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"--------- Table delete successful");
            return YES;
        }
        else {
            NSLog(@"--------- Failed to delete table");
            return NO;
        }
        sqlite3_reset(statement);
    }
    return NO;
}
@end
