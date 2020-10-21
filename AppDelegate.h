//
//  AppDelegate.h
//  Produlic
//
//  Created by Vu San Ha Huynh on 23/05/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "TrackAndAd.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>
- (KochavaTracker *) kochavaTracker;

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property(readonly) KochavaTracker *kochavaTracker;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

