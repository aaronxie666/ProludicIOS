//
//  AppDelegate.m
//  Produlic
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <Bolts/Bolts.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "SWRevealViewController.h"
#import "ExercisesViewController.h"
#import "Flurry.h"
#import <Tapjoy/Tapjoy.h>
@import HealthKit;

@interface AppDelegate ()

@property (nonatomic) HKHealthStore *healthStore;

@end

@implementation AppDelegate

@synthesize kochavaTracker;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //
    //    [defaults setObject:@"Yes" forKey:@"ShowLogin"];
    
    //    MyOffersViewController *frontViewController = [[MyOffersViewController alloc] init];
    //    SWRevealViewController *rearViewController = [[SWRevealViewController alloc] init];
    //
    //    UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
    //    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];
    //    SWRevealViewController *mainRevealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    //
    //    self.window.rootViewController = mainRevealController;
    
    [[NSUserDefaults standardUserDefaults] setInteger:-25 forKey:@"sideScrollerOffSet"];
    
    //Parse SDK
    // [Optional] Power your app with Local Datastore. For more info, go to
    // https://parse.com/docs/ios/guide#local-datastore
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    //Once The database has been transfered to Shashido, comment this
    // [Parse setApplicationId:@"6b4hLjVKOd9FiOEBT8RkvTBxQmVJfyRAZ33PY4On"
    //               clientKey:@"YCadXfYwDuVWUKvSYXeE7AA21YvA0QDGvbAwe2dI"];
    
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NSLog(@"%@", countryCode);
    if([countryCode containsString:@"AU"]) {
        [Parse initializeWithConfiguration:[ParseClientConfiguration
                                            configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
                                                configuration.applicationId = @"glbjtY86z2710bI9iVuSp4R6UBOCaVY5MMVRPShT";
                                                configuration.clientKey = @"NViz00oX6HbhwIsc2lH2Q8ixTaYUBRQgYSMMFbCP";
                                                configuration.server = @"https://pg-app-jy8nrp2wkljerdty2ibyugezjfjajr.scalabl.cloud/1/";
                                            }]];
        
    } else {
        
        [Parse initializeWithConfiguration:[ParseClientConfiguration
                                            configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
                                                configuration.applicationId = @"v7nlBfEXBTOFeS4nVDXk3ZQYi8hiITeEMEGJPz8k";
                                                configuration.clientKey = @"NuzWJ7b4UheIoOufV7m7wgZVNJVPTiQzI8i8IOEE";
                                                configuration.server = @"https://pg-app-lg48xzrdk8qyfv1d6zi0ebeld3i9ku.scalabl.cloud/1/";
                                            }]];
        
    }
    

    

    
    NSDictionary *initDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"koknowfootball-vmodeazp", @"kochavaAppId",
                              @"usd", @"currency", // optional - usd is default
                              @"0", @"limitAdTracking", // optional - 0 is default
                              @"0", @"enableLogging", // optional - 0 is default
                              nil];
    
    kochavaTracker = [[KochavaTracker alloc] initKochavaWithParams:initDict];
    
    // [Optional] Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    //Facebook SDK
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    //Flurry SDK
    [Flurry startSession:@"6ZT2KCXZBCBZ3WKPBBWP"];
    
    //Tapjoy
    //Set up success and failure notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectSuccess:)
                                                 name:TJC_CONNECT_SUCCESS
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tjcConnectFail:)
                                                 name:TJC_CONNECT_FAILED
                                               object:nil];
    //Turn on Tapjoy debug mode
    
    [Tapjoy setDebugEnabled:NO]; //Do not set this for any version of the game released to an app store!
    //The Tapjoy connect call
    [Tapjoy connect:@"MLoyJXQ0RNSzqP6ocPn1-wEB0ohWHvLDqANV58HvqbT3tPYtgUWYdtALSk3e"];
    
    //If you are not using Tapjoy Managed currency, you would set your own user ID here.
    //[Tapjoy setUserID:@"A_UNIQUE_USER_ID"];
    
    //Push Notifications
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes  categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    //Local Notifications
    UILocalNotification *localNotif =
    [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotif) {
        NSLog(@"%@", [localNotif.userInfo objectForKey:@"objectId"]);
        application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1;
    }
    
    self.healthStore = [[HKHealthStore alloc] init];
    
    return YES;
}

-(void)tjcConnectSuccess:(NSNotification*)notifyObj{
    NSLog(@"Tapjoy connect Succeeded");
}
-(void)tjcConnectFail:(NSNotification*)notifyObj{
    
    NSLog(@"Tapjoy connect Failed");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    //removes the bagde from icon once the app is being opened
    application.applicationIconBadgeNumber = 0;
    
    //Refreshes the number of badges in Parse
    PFInstallation *currentInstallation = [PFInstallation  currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
    
    [FBSDKAppEvents activateApp];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"BackgroundRefresh" object: nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    //[self saveContext];
    NSLog(@"Close app");
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark - Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    //currentInstallation.channels = @[ @"global" ];
    NSLog(@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
    [currentInstallation setValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"appVersionInstalled"];
    [currentInstallation saveInBackground];
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(error.description);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    [Flurry logEvent:@"User Received Push Notification" timed:YES];
    [PFPush handlePush:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName: @"PushNotificationRefresh" object: nil];
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    NSLog(@"%@",notification);
    NSString *itemName = [notification.userInfo objectForKey:@"objectId"];
    NSLog(@"%@",itemName);
    application.applicationIconBadgeNumber = notification.applicationIconBadgeNumber - 1;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:notification.alertTitle message:notification.alertBody preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [alert dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    alertWindow.rootViewController = [[UIViewController alloc] init];
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    [alertWindow makeKeyAndVisible];
    [alertWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    application.applicationIconBadgeNumber = notification.applicationIconBadgeNumber - 1;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.icncorporate.Produlic" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Proludic" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Proludic.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
@end
