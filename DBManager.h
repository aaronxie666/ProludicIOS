//
//  Proludic
//
//  Created by Geoff Baker on 21/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface DBManager : NSObject
{
    NSString *databasePath;
}

+(DBManager*)getSharedInstance;

-(BOOL)createDB;
-(BOOL) saveData:(NSString*)exerciseObjId :(NSString*)name :(int) NumRepeat;
-(NSArray*) findNumRepeat:(NSString*)ExerciseObjectId;
-(BOOL) updateData:(NSString*)exerciseObjId :(int) NumRepeat;
-(NSArray*) showTable;
-(BOOL) deleteData;
@end

