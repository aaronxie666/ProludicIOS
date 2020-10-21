//
//  DashboardViewController.m
//  KnowFootball
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <HealthKit/HealthKit.h>
#import "DashboardViewController.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"
#import "CustomAlert.h"

@interface DashboardViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation DashboardViewController{
    UIView *tmpView;
    UIView *popUpView;
    UIImageView *profilePicture;
    UIImage *selectedProfileImage;
    UIScrollView *sideScroller;
    UIScrollView *pageScroller;
    NSUserDefaults *defaults;
    UIButton *findParksButton;
    CLLocationManager *locationManager;
    int iteration;
    bool refreshView;
    bool userIsOnOverlay;
    bool libraryPicked;
    bool viewHasFinishedLoading;
    bool isFindingNearestParkOn;
    bool autoFind;
    int distanceMovedScroll;
    
    
    IBOutlet UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    
    //
    UIView *homeParkView;
    NSString *requiredID;
    
    UIScrollView *friendsSideScroller;
    NSArray *friendIds;
    NSArray *collectedFriends;
    
    //PFObjects
    PFObject *selectedMatchObject;
    PFObject *selectedOpponent;
    PFObject *achievementsObject;
    NSMutableArray *locationsObj;
    
    //AnimationImage
    UIImageView *glowImageView;
    
    UIScrollView *addInfoView;
    UIButton *backAusMapButton;
    UIView *showMapAus1;
    UIScrollView *showMapAus2;
    UIScrollView *showMapAus3;
    NSString *selectedAusState;
    UITextField *heightTextField1;
    UITextField *weightTextField;
    
    //Custom Alert
    CustomAlert *alertVC;
    
    NSMutableArray *parkStatsArray;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    userIsOnOverlay = NO;
    viewHasFinishedLoading = NO;
    // Do any additional setup after loading the view.
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [Flurry logEvent:@"User Opened Dashboard Page" timed:YES];
    
    parkStatsArray = [[NSMutableArray alloc] init];
    
    //Language
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSLog(@" - %@", language);
    if([language containsString:@"fr"]) {
        [PFUser currentUser][@"isFrench"] = @YES;
        [[PFUser currentUser] saveInBackground];
    } else {
        [PFUser currentUser][@"isFrench"] = @NO;
        [[PFUser currentUser] saveInBackground];
    }
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];
    self.navigationController.navigationBarHidden = NO;
    
    
    UIImageView *navigationImage = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        navigationImage.frame = CGRectMake(0, 0, 60, 35);
    } else {
        navigationImage.frame = CGRectMake(0, 0, 60, 35);
    }
    navigationImage.image=[UIImage imageNamed:@"proludic_logo_title"];
    
    UIImageView *workaroundImageView = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        workaroundImageView.frame = CGRectMake(0, -3, 34, 34);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        workaroundImageView.frame = CGRectMake(0, -3, 34, 34);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        workaroundImageView.frame = CGRectMake(0, 0, 34, 34);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        workaroundImageView.frame = CGRectMake(0, 0, 42, 42);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        workaroundImageView.frame = CGRectMake(0, 0, 42, 72);
    } else {
        workaroundImageView.frame = CGRectMake(0, 0, 42, 72);
    }
    
    [workaroundImageView addSubview:navigationImage];
    self.navigationItem.titleView=workaroundImageView;
    self.navigationItem.titleView.center = self.view.center;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // Build your regular UIBarButtonItem with Custom View
    UIImage *image = [UIImage imageNamed:@"hamburger2"];
    UIButton *leftBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBarButton.frame = CGRectMake(0, 10, 22, 15);
    [leftBarButton addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchDown];
    [leftBarButton setBackgroundImage:image forState:UIControlStateNormal];
    
    // Make BarButton Item
    UIBarButtonItem *navLeftButton = [[UIBarButtonItem alloc] initWithCustomView:leftBarButton];
    self.navigationItem.leftBarButtonItem = navLeftButton;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    /*
     Observer For Push Notifications
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationRefresh) name:@"PushNotificationRefresh" object:nil];
    
    /*
     Observer For App Background Handling
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundRefresh) name:@"BackgroundRefresh" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    //Change the host name here to change the server you want to monitor.
    NSString *remoteHostName = @"www.apple.com";
    
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    [self updateInterfaceWithReachability:self.wifiReachability];
    
    //[[DBManager getSharedInstance]createDB];
    
    //BackgroundImage
    UIImageView *background = [[UIImageView alloc] init];
    background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    background.image = [UIImage imageNamed:@"BG"];
    [self.view addSubview:background];
    
    //Navigational Bar
    UIView *navigationalBarImage = [[UIView alloc] init];
    navigationalBarImage.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        navigationalBarImage.frame = CGRectMake(-5, 43, self.view.frame.size.width+20, 50); //Image scaled
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        navigationalBarImage.frame = CGRectMake(-5, 43, self.view.frame.size.width+20, 50); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        navigationalBarImage.frame = CGRectMake(-5, 44, self.view.frame.size.width+20, 50); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        navigationalBarImage.frame = CGRectMake(-5, 44, self.view.frame.size.width+20, 50); //Image scaled
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        navigationalBarImage.frame = CGRectMake(-5, 88, self.view.frame.size.width+20, 50); //Image scaled
    }else if([[UIScreen mainScreen] bounds].size.height == 896){    //iPone xR / iPhone X max
        navigationalBarImage.frame = CGRectMake(-5, 88, self.view.frame.size.width+20, 50); //Image scaled
    }
    else {
        navigationalBarImage.frame = CGRectMake(-5, 88, self.view.frame.size.width+20, 50); //Image scaled
    }
    
    [self.view addSubview:navigationalBarImage];
    
    // Create the UI Side Scroll View
    sideScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        sideScroller.frame = CGRectMake(0, 43, self.view.frame.size.width, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        sideScroller.frame = CGRectMake(0, 43, self.view.frame.size.width, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        sideScroller.frame = CGRectMake(0, 44, self.view.frame.size.width, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        sideScroller.frame = CGRectMake(0, 44, self.view.frame.size.width, 50); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        sideScroller.frame = CGRectMake(0, 88, self.view.frame.size.width, 50); //Position of the scroller
    }else if([[UIScreen mainScreen] bounds].size.height == 896){
        sideScroller.frame = CGRectMake(0, 88, self.view.frame.size.width, 50); //Position of the scroller
    } else {
        sideScroller.frame = CGRectMake(0, 88, self.view.frame.size.width, 50); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    sideScroller.bounces = NO;
    sideScroller.scrollEnabled = NO;
    
    NavBar *navBar = [[NavBar alloc] init];
    
    int sideScrollerSize = [navBar getSize];
    
    sideScroller.contentSize = CGSizeMake(sideScrollerSize, 50);
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 30) animated:NO];
    [sideScroller setShowsHorizontalScrollIndicator:NO];
    [sideScroller setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:sideScroller];
    
    
    
    NSLog(@"%ld",(long)[defaults integerForKey:@"sideScrollerOffSet"]);
    //[self performSelector:@selector(setsideScrollerToPlace) withObject:nil afterDelay:0.01];
    
    
    //Get the array of Nav bar objects
    
    NSArray *arrayOfNavBarTitles = [navBar getTitles];
    NSArray *arrayOfXPositions = [navBar getXPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfButtonWidths = [navBar getButtonWidth:[[UIScreen mainScreen] bounds].size.height];
    NSLog(@"Pixels: %f",[[UIScreen mainScreen] bounds].size.height);
    
    //Add NavBar elements
    
    
    
    for (int i = 0; i < arrayOfNavBarTitles.count; i++) {
        NSString *title = [arrayOfNavBarTitles objectAtIndex:i];
        if (i == 0) { // Home
            title = [title stringByAppendingString:@"_Active"];
        }
        UIButton *navBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if([[UIScreen mainScreen] bounds].size.height == 896){  //iphone XR/Max
            navBarButton.frame = CGRectMake([[arrayOfXPositions objectAtIndex:i] integerValue] + 22, 10, [[arrayOfButtonWidths objectAtIndex:i] intValue], sideScroller.frame.size.height - 20);
        }
        else{
            navBarButton.frame = CGRectMake([[arrayOfXPositions objectAtIndex:i] integerValue], 10, [[arrayOfButtonWidths objectAtIndex:i] intValue], sideScroller.frame.size.height - 20);
        }
        
        
        navBarButton.tag = i + 1;
        [navBarButton addTarget:self action:@selector(tapNavButton:) forControlEvents:UIControlEventTouchUpInside];
        [navBarButton setBackgroundImage:[UIImage imageNamed:title] forState:UIControlStateNormal];
        navBarButton.titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:25];
        [navBarButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sideScroller addSubview:navBarButton];
    }
    
    if ([HKHealthStore isHealthDataAvailable]) {
        HKHealthStore *healthStore = [[HKHealthStore alloc] init];
        
        if ([HKHealthStore isHealthDataAvailable]) {
            NSSet *writeDataTypes = [self dataTypesToWrite];
            NSSet *readDataTypes = [self dataTypesToRead];
            
            [healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
                    
                    return;
                }
                
                [PFUser currentUser][@"AppleHealth"] = @YES;
                [[PFUser currentUser] saveInBackground];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSString *strCurrentDate;
                    NSString *strNewDate;
                    NSDate *date = [NSDate date];
                    NSDateFormatter *df =[[NSDateFormatter alloc]init];
                    [df setDateStyle:NSDateFormatterMediumStyle];
                    [df setTimeStyle:NSDateFormatterMediumStyle];
                    strCurrentDate = [df stringFromDate:date];
                    int minsToAdd = 3;
                    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    [components setMinute:minsToAdd];
                    NSDate *newDate= [calendar dateByAddingComponents:components toDate:date options:0];
                    [df setDateStyle:NSDateFormatterMediumStyle];
                    [df setTimeStyle:NSDateFormatterMediumStyle];
                    strNewDate = [df stringFromDate:newDate];
                    
                    // Provide summary information when creating the workout.
                    HKWorkout *run = [HKWorkout workoutWithActivityType:HKWorkoutActivityTypeCrossTraining
                                                              startDate:[NSDate date]
                                                                endDate:newDate
                                                               duration:0
                                                      totalEnergyBurned:nil
                                                          totalDistance:nil
                                                               metadata:nil];
                    
                    // Save the workout before adding detailed samples.
                    [healthStore saveObject:run withCompletion:^(BOOL success, NSError *error) {
                        if (!success) {
                            // Perform proper error handling here...
                            NSLog(@"*** An error occurred while saving the "
                                  @"workout: %@ ***", error.localizedDescription);
                            
                            
                        }
                        
                    }];
                });
            }];
        } else {
            NSLog(@"Can not use health kit");
        }
    } else {
        NSLog(@"Can not use health kit");
    }
    
    
    [self loadParseContent];
}

#pragma mark - HealthKit Permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet *)dataTypesToWrite {
    HKObjectType *workoutType = [HKObjectType workoutType];
    return [NSSet setWithObjects:workoutType, nil];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    
    return [NSSet setWithObjects:heightType, weightType, birthdayType, biologicalSexType, nil];
}

-(void)loadParseContent{
    // Create the UI Scroll View
    
    [pageScroller removeFromSuperview];
    [Hud removeFromSuperview];
    
    pageScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.frame = CGRectMake(0, 92, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 93, self.view.frame.size.width, 500); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 450);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 450);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 300);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 200);
    } else {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 300);
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    pageScroller.bounces = NO;
    [pageScroller setShowsVerticalScrollIndicator:NO];
    //[pageScroller setPagingEnabled : YES];
    [self.view addSubview:pageScroller];
    
    // Create the UI Side Scroll View
    friendsSideScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 105); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 105); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 110); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 115); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 115); //Position of the scroller
    } else {
        friendsSideScroller.frame = CGRectMake(-5, 520, self.view.frame.size.width+20, 115); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    friendsSideScroller.bounces = YES;
    friendsSideScroller.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    friendsSideScroller.delegate = self;
    friendsSideScroller.scrollEnabled = YES;
    friendsSideScroller.userInteractionEnabled = YES;
    [friendsSideScroller setShowsHorizontalScrollIndicator:NO];
    [friendsSideScroller setShowsVerticalScrollIndicator:NO];
    
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = @"Loading";
    
    //Loading Animation UIImageView
    
    //Create the first status image and the indicator view
    UIImage *statusImage = [UIImage imageNamed:@"load_anim000"];
    activityImageView = [[UIImageView alloc]
                         initWithImage:statusImage];
    
    
    //Add more images which will be used for the animation
    activityImageView.animationImages = [NSArray arrayWithObjects:
                                         [UIImage imageNamed:@"load_anim000"],
                                         [UIImage imageNamed:@"load_anim001"],
                                         [UIImage imageNamed:@"load_anim002"],
                                         [UIImage imageNamed:@"load_anim003"],
                                         [UIImage imageNamed:@"load_anim004"],
                                         [UIImage imageNamed:@"load_anim005"],
                                         [UIImage imageNamed:@"load_anim006"],
                                         [UIImage imageNamed:@"load_anim007"],
                                         [UIImage imageNamed:@"load_anim008"],
                                         [UIImage imageNamed:@"load_anim009"],
                                         nil];
    
    //Set the duration of the animation (play with it
    //until it looks nice for you)
    activityImageView.animationDuration = 0.5;
    
    activityImageView.animationRepeatCount = 0;
    
    
    //Position the activity image view somewhere in
    //the middle of your current view
    activityImageView.frame = CGRectMake(
                                         self.view.frame.size.width/2
                                         -25,
                                         self.view.frame.size.height/2
                                         -25,
                                         50,
                                         50);
    
    //Start the animation
    [activityImageView startAnimating];
    
    
    //Add your custom activity indicator to your current view
    [pageScroller addSubview:activityImageView];
    
    // Add stuff to view here
    Hud.customView = activityImageView;
    
    if (![PFUser currentUser]) {
        [self showLoginView];
    } else {
        
        //Check if user current installation is the same as device installation
        [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject * userObject, NSError * error) {
            //[[PFUser currentUser] fetch];
            if (!error) {
                
                [[PFInstallation currentInstallation] fetchInBackgroundWithBlock:^(PFObject * installationObject, NSError * error) {
                    if (!error) {
                        //Check for unique installation device
                        
                        if ([installationObject[@"appRefresh"] boolValue]) { //If installation was resetted by cloud code
                            
                            [PFInstallation currentInstallation][@"appRefresh"] = @NO;
                            
                            [[PFInstallation currentInstallation] saveInBackground];
                            [PFUser logOut]; //log out the user
                            [self loadParseContent];
                        } else {
                            
                            if (userObject[@"currentInstallation"] == nil) { //if user has no user associated with installation, add current installation
                                [PFUser currentUser][@"currentInstallation"] = [PFInstallation currentInstallation];
                                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                    if (succeeded && !error) {
                                        
                                        [PFInstallation currentInstallation][@"user"] = [PFUser currentUser];
                                        [PFInstallation currentInstallation][@"userId"] = [[PFUser currentUser] objectId];
                                        [PFInstallation currentInstallation][@"appRefresh"] = @NO;
                                        //Set current installation with user values
                                        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                            if (succeeded && !error) {
                                                //                                                [self loadUser]; //Load the view
                                                [self checkForLoginDate];
                                            }
                                        }];
                                        
                                    } else {
                                        
                                        NSLog(@"Something went wrong! reason:%@", error.description);
                                        [Hud removeFromSuperview];
                                        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error!"
                                                                                       message:error.description delegate:nil
                                                                             cancelButtonTitle:@"OK"
                                                                             otherButtonTitles:nil, nil];
                                        [alert show];
                                        
                                        [self loadParseContent];
                                    }
                                }];
                                
                            } else {
                                
                                //Cloud code that deletes the duplicate installations
                                if ([[[userObject objectForKey:@"currentInstallation"] objectId] isEqualToString:[PFInstallation currentInstallation].objectId]) {
                                    
                                    
                                    if ([PFInstallation currentInstallation][@"user"] == nil) {
                                        [PFInstallation currentInstallation][@"user"] = [PFUser currentUser];
                                        [PFInstallation currentInstallation][@"userId"] = [[PFUser currentUser] objectId];
                                        [PFInstallation currentInstallation][@"appRefresh"] = @NO;
                                        //Set current installation with user values
                                        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                            if (succeeded && !error) {
                                                //                                                [self loadUser]; //Load the view
                                                [self checkForLoginDate];
                                            }
                                        }];
                                    } else {
                                        
                                        //                                        [self loadUser]; //if installation and user are matching load the view normally
                                        [self checkForLoginDate];
                                    }
                                    
                                } else {
                                    
                                    //Load Cloud function
                                    /*[PFCloud callFunctionInBackground:@"deleteDuplicateInstallations" withParameters:@{@"objectId": [PFUser currentUser].objectId} block:^(id  object, NSError * error) {
                                     if (!error) {
                                     [PFUser currentUser][@"currentInstallation"] = [PFInstallation currentInstallation]; //set the user to the installation
                                     [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                     if (succeeded && !error) {
                                     //set installation to user
                                     [PFInstallation currentInstallation][@"user"] = [PFUser currentUser];
                                     [PFInstallation currentInstallation][@"userId"] = [[PFUser currentUser] objectId];
                                     [PFInstallation currentInstallation][@"appRefresh"] = @NO;
                                     
                                     [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                     if (succeeded && !error) {
                                     //                                                            [self loadUser];//If success load the view normally
                                     [self checkForLoginDate];
                                     }
                                     }];
                                     } else {
                                     
                                     NSLog(@"Something went wrong! reason:%@", error.description);
                                     [Hud removeFromSuperview];
                                     UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error!"
                                     message:error.description delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil, nil];
                                     [alert show];
                                     
                                     [self loadParseContent];
                                     }
                                     }];
                                     } else {
                                     // Error here
                                     NSLog(@"%@",error.description);
                                     }
                                     }];*/
                                    [PFUser currentUser][@"currentInstallation"] = [PFInstallation currentInstallation]; //set the user to the installation
                                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                        if (succeeded && !error) {
                                            //set installation to user
                                            [PFInstallation currentInstallation][@"user"] = [PFUser currentUser];
                                            [PFInstallation currentInstallation][@"userId"] = [[PFUser currentUser] objectId];
                                            [PFInstallation currentInstallation][@"appRefresh"] = @NO;
                                            
                                            [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                if (succeeded && !error) {
                                                    //                                                            [self loadUser];//If success load the view normally
                                                    [self checkForLoginDate];
                                                }
                                            }];
                                        } else {
                                            
                                            NSLog(@"Something went wrong! reason:%@", error.description);
                                            [Hud removeFromSuperview];
                                            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error!"
                                                                                           message:error.description delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil, nil];
                                            [alert show];
                                            
                                            [self loadParseContent];
                                        }
                                    }];
                                    
                                }
                                
                            }
                        }
                    }
                }];
            }
        }];
    }
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [pageScroller addSubview:friendsSideScroller];
}


-(void)scrollViewDidScroll:(UIScrollView *)friendsSideScroller{
    
}

-(void)showLoginView{
    
    SWRevealViewController *LoginControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"InitialLogin"];
    
    [self.navigationController pushViewController:LoginControl animated:NO];
}

-(void)checkForLoginDate{
    
    BOOL sameDay = [[NSCalendar currentCalendar] isDateInToday:[[PFUser currentUser] objectForKey:@"lastLoginDate"]];
    
    if (sameDay) {
        
        
    } else {
        
    }
    [self loadUser];
}

-(void)loadUser{
    if(![[[PFUser currentUser] objectForKey:@"login"] isEqualToString:@"Facebook"] && [PFUser currentUser][@"height"] == nil) {
        static dispatch_once_t onceToken;
        //all yours mate, chang was just adding his code on factory view
        dispatch_once (&onceToken, ^{
            
            //CHECKS CURRENT LOCATION
            if([[[PFUser currentUser] objectForKey:@"HomePark"] isEqualToString:@"NotSelected"]) {
                [self autoFindNearestPark:nil];
            } else {
                [self autoFindNearestPark:nil];
            }
        });
    }
    
    //Profile Group View
    UIImageView *profileGroupView = [[UIImageView alloc] init];
    profileGroupView.contentMode = UIViewContentModeScaleAspectFit;
    profileGroupView.clipsToBounds = YES;
    [profileGroupView setBackgroundColor:[UIColor colorWithRed:0.90 green:0.72 blue:0.54 alpha:1.0]];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 80);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 120);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 120);
    } else {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 120);
    }
    [pageScroller addSubview:profileGroupView];
    
    //Profile Picture
    
    profilePicture = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        profilePicture.frame = CGRectMake(20, 5, 70, 70);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        profilePicture.frame = CGRectMake(20, 5, 70, 70);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        profilePicture.frame = CGRectMake(30, 5, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        profilePicture.frame = CGRectMake(30, 5, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        profilePicture.frame = CGRectMake(30, 15, 90, 90);
    } else {
        profilePicture.frame = CGRectMake(30, 15, 90, 90);
    }
    
    CALayer *imageLayer = profilePicture.layer;
    [imageLayer setCornerRadius:5];
    [imageLayer setBorderWidth:1];
    [profilePicture.layer setCornerRadius:profilePicture.frame.size.width/2];
    [imageLayer setMasksToBounds:YES];
    profilePicture.layer.borderWidth = 3.0f;
    profilePicture.contentMode = UIViewContentModeScaleAspectFill;
    profilePicture.clipsToBounds = YES;
    profilePicture.layer.borderColor = [UIColor colorWithRed:0.29 green:0.28 blue:0.28 alpha:1.0].CGColor;
    
    [pageScroller addSubview:profilePicture];
    
    UIActivityIndicatorView *activityView1 = [[UIActivityIndicatorView alloc]
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        activityView1.frame = CGRectMake(16, 2, 80, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        activityView1.frame = CGRectMake(16, 2, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        activityView1.frame = CGRectMake(30, 5, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        activityView1.frame = CGRectMake(32, 5, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        activityView1.frame = CGRectMake(32, 5, 100, 100);
    } else {
        activityView1.frame = CGRectMake(32, 5, 100, 100);
    }
    [activityView1 startAnimating];
    [pageScroller addSubview:activityView1];
    
    //Change Profile Button
    
    UIButton *changeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        changeImageButton.frame = CGRectMake(20, 5, 80, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        changeImageButton.frame = CGRectMake(20, 5, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        changeImageButton.frame = CGRectMake(30, 5, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        changeImageButton.frame = CGRectMake(32, 5, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        changeImageButton.frame = CGRectMake(32, 15, 90, 90);
    } else {
        changeImageButton.frame = CGRectMake(32, 15, 90, 90);
    }
    changeImageButton.backgroundColor = [UIColor clearColor];
    changeImageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    changeImageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    changeImageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [pageScroller addSubview:changeImageButton];
    
    NSString *typeOfUser = [[PFUser currentUser] objectForKey:@"login"];
    if([typeOfUser isEqualToString:@"Facebook"] && [PFUser currentUser][@"height"] == nil) {
        pageScroller.scrollEnabled = NO;
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = NO;
        }
        
        addInfoView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
        addInfoView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        [addInfoView setBackgroundColor:[UIColor blackColor]];
        addInfoView.layer.zPosition = 1;
        addInfoView.alpha = 0.95;
        addInfoView.userInteractionEnabled = YES;
        addInfoView.scrollEnabled = NO;
        
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [addInfoView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [addInfoView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
         }];
        [self setupAddInfoGrid];
        [self.view addSubview:addInfoView];
    }
    if([typeOfUser isEqualToString:@"Facebook"] && [PFUser currentUser][@"profilePicture"] == nil){
        [changeImageButton addTarget:self action:@selector(tapChangeKit) forControlEvents:UIControlEventTouchUpInside];
        //Facebook User
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[PFUser currentUser][@"facebookID"]]]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                [activityView1 stopAnimating];
                [activityView1 removeFromSuperview];
                profilePicture.image =  [UIImage imageWithData:data];
                [PFUser currentUser][@"profilePicture"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[PFUser currentUser][@"facebookID"]];
                [[PFUser currentUser] saveInBackground];
            });
        });
        
    }else {
        //Email user
        [changeImageButton addTarget:self action:@selector(tapChangeImage) forControlEvents:UIControlEventTouchUpInside];
        if (![[PFUser currentUser][@"profilePicture"] isEqualToString:@"NoPicture"]) {
            
            NSString *imageUrl = [PFUser currentUser][@"profilePicture"];
            
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [activityView1 stopAnimating];
                    [activityView1 removeFromSuperview];
                    profilePicture.image =  [UIImage imageWithData:data];
                    
                    //Change Profile Button
                    
                    UIButton *changeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                    {
                        changeImageButton.frame = CGRectMake(20, 5, 80, 80);
                        
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                    {
                        changeImageButton.frame = CGRectMake(20, 5, 80, 80);
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                    {
                        changeImageButton.frame = CGRectMake(30, 5, 90, 90);
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                    {
                        changeImageButton.frame = CGRectMake(30, 5, 100, 100);
                    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                    {
                        changeImageButton.frame = CGRectMake(30, 15, 90, 90);
                    }
                    
                    [changeImageButton addTarget:self action:@selector(tapChangeImage) forControlEvents:UIControlEventTouchUpInside];
                    changeImageButton.backgroundColor = [UIColor clearColor];
                    changeImageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                    changeImageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
                    changeImageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
                    [pageScroller addSubview:changeImageButton];
                    
                });
            });
        } else {
            
            [activityView1 stopAnimating];
            [activityView1 removeFromSuperview];
            //User hasnt set a profile picture
            profilePicture.image = [UIImage imageNamed:@"profile_pic"];
            
            
        }
        
    }
    
    if([[PFUser currentUser][@"notReferred"] isEqual:@YES]) {
        
        [self referFriendAlert];
        
    }
    
    
    // Name Label
    UILabel *nameLabel = [[UILabel alloc]init];
    nameLabel.textColor = [UIColor blackColor];
    //nameLabel.backgroundColor = [UIColor whiteColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        nameLabel.frame = CGRectMake(90, 5, 200, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        nameLabel.frame = CGRectMake(90, 5, 200, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        nameLabel.frame = CGRectMake(190, 5, 140, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16];
        nameLabel.frame = CGRectMake(180, 5, 210, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16];
        nameLabel.frame = CGRectMake(180, 5, 210, 41);
    } else {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16];
        nameLabel.frame = CGRectMake(180, 5, 210, 41);
    }
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = [[PFUser currentUser] objectForKey:@"username"];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:nameLabel];
    
    // Park Label
    UILabel *parkLabel = [[UILabel alloc]init];
    parkLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        parkLabel.frame = CGRectMake(90, 34, 200, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        parkLabel.frame = CGRectMake(90, 34, 200, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(140, 41, 230, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        parkLabel.frame = CGRectMake(160, 41, 250, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(160, 41, 250, 20);
    } else {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(160, 41, 250, 20);
    }
    if([[[PFUser currentUser] objectForKey:@"HomePark"] isEqualToString:@"NotSelected"]) {
        parkLabel.text = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Park Not Selected", nil)];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
        [query whereKey:@"objectId" equalTo:[[PFUser currentUser] objectForKey:@"HomePark"]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!object) {
                NSLog(@"The getFirstObject request failed.");
                [Hud removeFromSuperview];
            } else {
                // The find succeeded.
                NSLog(@"Successfully retrieved the object.");
                parkLabel.text = [NSString stringWithFormat:@"%@",object[@"Location"]];
            }
        }];
    }
    
    parkLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:parkLabel];
    
    // heart Label
    
    UIImageView *heartImage = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage.frame = CGRectMake(155, 55, 20, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage.frame = CGRectMake(155, 55, 20, 20);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage.frame = CGRectMake(215, 66, 25, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage.frame = CGRectMake(245, 71, 25, 25);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage.frame = CGRectMake(245, 71, 25, 25);
    } else {
        heartImage.frame = CGRectMake(245, 71, 25, 25);
    }
    heartImage.image = [UIImage imageNamed:@"Heart"];
    heartImage.contentMode = UIViewContentModeScaleAspectFit;
    heartImage.clipsToBounds = YES;
    [pageScroller addSubview:heartImage];
    
    UILabel *heartLabel = [[UILabel alloc]init];
    heartLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartLabel.frame = CGRectMake(180, 57, 100, 15);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartLabel.frame = CGRectMake(180, 57, 100, 15);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(245, 71, 100, 15);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        heartLabel.frame = CGRectMake(275, 76, 150, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(275, 76, 150, 15);
    } else {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(275, 76, 150, 15);
    }
    heartLabel.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"Hearts"]];
    heartLabel.textAlignment = NSTextAlignmentLeft;
    //heartLabel.backgroundColor = [UIColor yellowColor];
    [pageScroller addSubview:heartLabel];
    
    
    // Weekly Target Label
    UILabel *weeklyTargetRouting = [[UILabel alloc]init];
    weeklyTargetRouting.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        weeklyTargetRouting.frame = CGRectMake(0, 90, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        weeklyTargetRouting.frame = CGRectMake(0, 90, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        weeklyTargetRouting.frame = CGRectMake(0, 113, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        weeklyTargetRouting.frame = CGRectMake(0, 130, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        weeklyTargetRouting.frame = CGRectMake(0, 130, self.view.frame.size.width, 20);
    } else {
        weeklyTargetRouting.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        weeklyTargetRouting.frame = CGRectMake(0, 130, self.view.frame.size.width, 20);
    }
    weeklyTargetRouting.text = [NSString stringWithFormat:NSLocalizedString(@"Weekly target routine", nil)];
    
    weeklyTargetRouting.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:weeklyTargetRouting];
    
    //Navigational Bar
    UIImageView *weeklyTargetImage = [[UIImageView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weeklyTargetImage.frame = CGRectMake(0, 120, self.view.frame.size.width, 150); //Image scaled
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weeklyTargetImage.frame = CGRectMake(0, 120, self.view.frame.size.width, 150); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weeklyTargetImage.frame = CGRectMake(0, 145, self.view.frame.size.width, 150); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weeklyTargetImage.frame = CGRectMake(0, 160, self.view.frame.size.width, 150); //Image scaled
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weeklyTargetImage.frame = CGRectMake(0, 160, self.view.frame.size.width, 150); //Image scaled
    } else {
        weeklyTargetImage.frame = CGRectMake(0, 160, self.view.frame.size.width, 150); //Image scaled
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Extras"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
            [Hud removeFromSuperview];
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object.");
            PFQuery *query2 = [PFQuery queryWithClassName:@"Exercises"];
            [query2 whereKey:@"objectId" equalTo:[object[@"ExerciseWeekly"] objectId]];
            [query2 getFirstObjectInBackgroundWithBlock:^(PFObject *object2, NSError *error) {
                if (!object2) {
                    NSLog(@"The getFirstObject request failed.");
                    [Hud removeFromSuperview];
                } else {
                    // The find succeeded.
                    NSLog(@"Successfully retrieved the object.");
                    PFFile *imageFile = object2[@"ExerciseImage"];
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        
                        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                        if ( data == nil )
                            return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[activityView1 stopAnimating];
                            //[activityView1 removeFromSuperview];
                            weeklyTargetImage.image =  [UIImage imageWithData:data];
                            
                        });
                    });
                    
                }
            }];
            
        }
    }];
    [pageScroller addSubview:weeklyTargetImage];
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Top Rank Label
    NSString * language5 = [[NSLocale preferredLanguages] objectAtIndex:0];
    UILabel *topRank5 = [[UILabel alloc]init];
    topRank5.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topRank5.frame = CGRectMake(0, 290, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank5.frame = CGRectMake(0, 290, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topRank5.frame = CGRectMake(0, 290, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank5.frame = CGRectMake(0, 290, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank5.frame = CGRectMake(0, 310, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank5.frame = CGRectMake(0, 310, self.view.frame.size.width/2, 20);
        }
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:16];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 20);
        }
    } else {
        if([language5 containsString:@"fr"]) {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 30);
        } else {
            topRank5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank5.frame = CGRectMake(0, 325, self.view.frame.size.width/2, 20);
        }
    }
    if([language5 containsString:@"fr"]) {
        topRank5.numberOfLines = 2;
    }
    topRank5.text = [NSString stringWithFormat:NSLocalizedString(@"This Week", nil)];
    topRank5.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topRank5];
    
    //Top Rank Picture
    
    /*UIImageView *topRankPicture5 = [[UIImageView alloc]init];
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     topRankPicture5.frame = CGRectMake(self.view.frame.size.width/4 - 40, 330, 80, 80);
     
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
     {
     topRankPicture5.frame = CGRectMake(self.view.frame.size.width/4 - 40, 330, 80, 80);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     topRankPicture5.frame = CGRectMake(self.view.frame.size.width/4 - 45, 350, 90, 90);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     topRankPicture5.frame = CGRectMake(self.view.frame.size.width/4 - 50, 350, 100, 100);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     topRankPicture5.frame = CGRectMake(self.view.frame.size.width/4 - 50, 350, 100, 100);
     }
     
     CALayer *topRankimageLayer5 = topRankPicture5.layer;
     [topRankimageLayer5 setCornerRadius:5];
     [topRankimageLayer5 setBorderWidth:1];
     [topRankPicture5.layer setCornerRadius:topRankPicture5.frame.size.width/2];
     [topRankimageLayer5 setMasksToBounds:YES];
     topRankPicture5.layer.borderWidth = 3.0f;
     topRankPicture5.contentMode = UIViewContentModeScaleAspectFill;
     topRankPicture5.layer.borderColor = [UIColor clearColor].CGColor;
     
     [pageScroller addSubview:topRankPicture5];*/
    
    UIImageView *topRankPicture7 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        //topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328, 88, 88);
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328, 88, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        //topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328, 88, 88);
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328, 88, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        //topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 49, 348, 98, 98);
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 49, 348, 98, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        //topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348, 108, 108);
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348, 108, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        //topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348, 108, 108);
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348, 108, 100);
    } else {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348, 108, 100);
    }
    //topRankPicture7.image = [UIImage imageNamed:@"leaderboard_rank"];
    topRankPicture7.image = [UIImage imageNamed:@"heart_orange"];
    [pageScroller addSubview:topRankPicture7];
    UILabel *topRankName5 = [[UILabel alloc]init];
    topRankName5.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankName5.frame = CGRectMake(0, 430, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankName5.frame = CGRectMake(0, 430, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName5.frame = CGRectMake(0, 450, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:17];
        topRankName5.frame = CGRectMake(0, 460, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName5.frame = CGRectMake(0, 460, self.view.frame.size.width/2, 20);
    } else {
        topRankName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName5.frame = CGRectMake(0, 460, self.view.frame.size.width/2, 20);
    }
    topRankName5.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topRankName5];
    
    
    /*UILabel *topRankHeart5 = [[UILabel alloc]init];
     topRankHeart5.textColor = [UIColor blackColor];
     if ([[UIScreen mainScreen] bounds].size.height == 480)
     {
     topRankHeart5.font = [UIFont fontWithName:@"Open Sans" size:12];
     topRankHeart5.frame = CGRectMake(0, 395, self.view.frame.size.width/2, 20);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 568)
     {
     topRankHeart5.font = [UIFont fontWithName:@"Open Sans" size:12];
     topRankHeart5.frame = CGRectMake(0, 395, self.view.frame.size.width/2, 20);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     topRankHeart5.font = [UIFont fontWithName:@"Open Sans" size:14];
     topRankHeart5.frame = CGRectMake(0, 425, self.view.frame.size.width/2, 20);
     
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     topRankHeart5.font = [UIFont fontWithName:@"Open Sans" size:17];
     topRankHeart5.frame = CGRectMake(0, 432, self.view.frame.size.width/2, 20);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     topRankHeart5.font = [UIFont fontWithName:@"Open Sans" size:14];
     topRankHeart5.frame = CGRectMake(0, 432, self.view.frame.size.width/2, 20);
     }
     topRankHeart5.textAlignment = NSTextAlignmentCenter;
     [pageScroller addSubview:topRankHeart5];*/
    
    
    
    
    
    //UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(dialogContainer.bounds.size.width/2, 0, buttonSpacerHeight, dialogContainer.bounds.size.height)];
    //lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    //[dialogContainer addSubview:lineView];
    
    // Top Achiever Label
    UILabel *topAchiever5 = [[UILabel alloc]init];
    topAchiever5.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 290, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 290, self.view.frame.size.width/2, 20);
        }
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 290, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 290, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 310, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 310, self.view.frame.size.width/2, 20);
        }
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:16];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 20);
        }
    } else {
        if([language5 containsString:@"fr"]) {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 30);
        } else {
            topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever5.frame = CGRectMake(self.view.frame.size.width/2, 325, self.view.frame.size.width/2, 20);
        }
    }
    if([language5 containsString:@"fr"]) {
        topAchiever5.numberOfLines = 2;
    }
    topAchiever5.text = [NSString stringWithFormat:NSLocalizedString(@"Best Week", nil)];
    
    topAchiever5.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchiever5];
    
    
    //Top Achiever Picture
    
    /*UIImageView *topAchieverPicture5 = [[UIImageView alloc]init];
     
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 330, 80, 80);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
     {
     topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 330, 80, 80);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 350, 90, 90);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 50, 350, 100, 100);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 50, 350, 100, 100);
     }
     
     CALayer *topAchieverimageLayer5 = topAchieverPicture5.layer;
     [topAchieverimageLayer5 setCornerRadius:5];
     [topAchieverimageLayer5 setBorderWidth:1];
     [topAchieverPicture5.layer setCornerRadius:topAchieverPicture5.frame.size.width/2];
     [topAchieverimageLayer5 setMasksToBounds:YES];
     topAchieverPicture5.layer.borderWidth = 3.0f;
     topAchieverPicture5.contentMode = UIViewContentModeScaleAspectFill;
     topAchieverPicture5.layer.borderColor = [UIColor clearColor].CGColor;
     
     [pageScroller addSubview:topAchieverPicture5];
     */
    
    UIImageView *topAchieverPicture7 = [[UIImageView alloc]init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        //topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328, 88, 88);
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328, 88, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        //topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328, 88, 88);
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328, 88, 88);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        //topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 49, 348, 98, 98);
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 49, 348, 98, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        
    {
        //topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348, 108, 108);
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348, 108, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        //topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348, 108, 108);
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348, 108, 100);
    } else {
        topAchieverPicture7.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348, 108, 100);
    }
    //topAchieverPicture7.image = [UIImage imageNamed:@"leaderboard_rank"];
    topAchieverPicture7.image = [UIImage imageNamed:@"heart_gold"];
    [pageScroller addSubview:topAchieverPicture7];
    
    
    UILabel *topAchieverName5 = [[UILabel alloc]init];
    topAchieverName5.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 430, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 430, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 450, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:17];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 460, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 460, self.view.frame.size.width/2, 20);
    } else {
        topAchieverName5.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName5.frame = CGRectMake(self.view.frame.size.width/2, 460, self.view.frame.size.width/2, 20);
    }
    topAchieverName5.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchieverName5];
    
    /*UILabel *topAchieverHeart5 = [[UILabel alloc]init];
     topAchieverHeart5.textColor = [UIColor blackColor];
     if ([[UIScreen mainScreen] bounds].size.height == 480)
     {
     topAchieverHeart5.font = [UIFont fontWithName:@"Open Sans" size:12];
     topAchieverHeart5.frame = CGRectMake(self.view.frame.size.width/2, 395, self.view.frame.size.width/2, 20);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 568)
     {
     topAchieverHeart5.font = [UIFont fontWithName:@"Open Sans" size:12];
     topAchieverHeart5.frame = CGRectMake(self.view.frame.size.width/2, 395, self.view.frame.size.width/2, 20);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     topAchieverHeart5.font = [UIFont fontWithName:@"Open Sans" size:14];
     topAchieverHeart5.frame = CGRectMake(self.view.frame.size.width/2, 425, self.view.frame.size.width/2, 20);
     
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     topAchieverHeart5.font = [UIFont fontWithName:@"Open Sans" size:17];
     topAchieverHeart5.frame = CGRectMake(self.view.frame.size.width/2, 432, self.view.frame.size.width/2, 20);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     topAchieverHeart5.font = [UIFont fontWithName:@"Open Sans" size:14];
     topAchieverHeart5.frame = CGRectMake(self.view.frame.size.width/2, 432, self.view.frame.size.width/2, 20);
     }
     topAchieverHeart5.textAlignment = NSTextAlignmentCenter;
     [pageScroller addSubview:topAchieverHeart5];*/
    
    
    /*PFQuery *queryTopAchiever5 = [PFQuery queryWithClassName:@"Locations"];
     [queryTopAchiever5 orderByDescending:@"TotalParkHearts"];
     queryTopAchiever5.limit = 1;
     [queryTopAchiever5 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
     if (error) {
     NSLog(@"Top achiever request failed.");
     [Hud removeFromSuperview];
     } else {
     // The find succeeded.
     NSLog(@"Successfully retrieved the object top achiever.");
     topAchieverName5.text = [objects objectAtIndex:0][@"Location"];
     topAchieverHeart5.text = [NSString stringWithFormat:@"%@",[objects objectAtIndex:0][@"TotalParkHearts"]];
     PFFile *imageFile = [objects objectAtIndex:0][@"Image"];
     NSString * language5 = [[NSLocale preferredLanguages] objectAtIndex:0];
     dispatch_async(dispatch_get_global_queue(0,0), ^{
     
     NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
     if ( data == nil )
     return;
     dispatch_async(dispatch_get_main_queue(), ^{
     //[activityView1 stopAnimating];
     //[activityView1 removeFromSuperview];
     topAchieverPicture5.image =  [UIImage imageWithData:data];
     
     });
     });
     }
     }];*/
    NSDate *currentDate = [NSDate date];
    NSMutableArray *datesOfCurrentWeek = [self datesOfWeekFromDate:currentDate];
    PFQuery *queryTopRank5 = [PFQuery queryWithClassName:@"TrackedEvents"];
    [queryTopRank5 whereKey:@"User" equalTo:[PFUser currentUser]];
    [queryTopRank5 whereKey:@"Date" containedIn:datesOfCurrentWeek];
    queryTopRank5.limit = 1000;
    [queryTopRank5 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Top rank request failed.");
            [Hud removeFromSuperview];
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object top rank.");
            int totalHeartsThisWeek = 0;
            for (PFObject *object in objects) {
                totalHeartsThisWeek += [object[@"Hearts"] intValue];
            }
            topRankName5.text = [NSString stringWithFormat:@"%d", totalHeartsThisWeek];
            
            if(totalHeartsThisWeek > [[PFUser currentUser][@"BestWeekHearts"] intValue]) {
                [PFUser currentUser][@"BestWeekHearts"] = @(totalHeartsThisWeek);
                [[PFUser currentUser] saveInBackground];
                topAchieverName5.text = [NSString stringWithFormat:@"%d", totalHeartsThisWeek];
            } else {
                topAchieverName5.text = [NSString stringWithFormat:@"%d", [[PFUser currentUser][@"BestWeekHearts"] intValue]];
            }
            
            
            /*topRankHeart5.text = [NSString stringWithFormat:@"%@",[objects objectAtIndex:0][@"Hearts"]];
             NSString *imageUrl = [objects objectAtIndex:0][@"profilePicture"];
             dispatch_async(dispatch_get_global_queue(0,0), ^{
             
             NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
             if ( data == nil )
             return;
             dispatch_async(dispatch_get_main_queue(), ^{
             
             topRankPicture5.image =  [UIImage imageWithData:data];
             
             });
             });*/
            
        }
    }];
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //Parse Friends
    if(![[PFUser currentUser][@"Friends"] count] == 0) {
        //QUERY FOR GETTING MY EXERCISES
        PFQuery * browseMyQuery = [PFUser query];
        [browseMyQuery orderByDescending:@"updatedAt"];
        [browseMyQuery whereKey:@"objectId" containedIn:[PFUser currentUser][@"Friends"]];
        [browseMyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error) {
                 collectedFriends = objects;
                 [self setFriendsGrid:objects : [PFUser currentUser][@"Friends"]];
                 
                 friendIds = [objects valueForKeyPath:@"objectId"];
                 NSLog(@"-x-x-x-x-x-x-x- %@", friendIds);
             }
             else {
                 NSLog(@"THIS DIDNT WORK!");
             }
         }];
    }
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Top Rank Label
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    UILabel *topRank = [[UILabel alloc]init];
    topRank.textColor = [UIColor blackColor];
    int x = 0;
    int y = 0;
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        x = 320;
        y = 170;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topRank.frame = CGRectMake(0, 290 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank.frame = CGRectMake(0, 290 + x, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        x = 320;
        y = 170;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topRank.frame = CGRectMake(0, 290 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank.frame = CGRectMake(0, 290 + x, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        x = 335;
        y = 210;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank.frame = CGRectMake(0, 310 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank.frame = CGRectMake(0, 310 + x, self.view.frame.size.width/2, 20);
        }
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        x = 320;
        y = 210;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:16];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        x = 320;
        y = 210;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 20);
        }
    } else {
        x = 320;
        y = 210;
        if([language containsString:@"fr"]) {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topRank.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topRank.frame = CGRectMake(0, 325 + x, self.view.frame.size.width/2, 20);
        }
    }
    if([language containsString:@"fr"]) {
        topRank.numberOfLines = 2;
    }
    topRank.text = [NSString stringWithFormat:NSLocalizedString(@"Top Rank", nil)];
    topRank.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topRank];
    
    //Top Rank Picture
    
    UIImageView *topRankPicture = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 40, 330 + x, 80, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 40, 330 + x, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 45, 350 + x, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    } else {
        topRankPicture.frame = CGRectMake(self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    }
    
    CALayer *topRankimageLayer = topRankPicture.layer;
    [topRankimageLayer setCornerRadius:5];
    [topRankimageLayer setBorderWidth:1];
    [topRankPicture.layer setCornerRadius:topRankPicture.frame.size.width/2];
    [topRankimageLayer setMasksToBounds:YES];
    topRankPicture.layer.borderWidth = 3.0f;
    topRankPicture.contentMode = UIViewContentModeScaleAspectFill;
    topRankPicture.layer.borderColor = [UIColor clearColor].CGColor;
    
    [pageScroller addSubview:topRankPicture];
    
    UIImageView *topRankPicture2 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328 + x, 88, 88);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 44, 328 + x, 88, 88);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 49, 348 + x, 98, 98);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    } else {
        topRankPicture2.frame = CGRectMake(self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    }
    topRankPicture2.image = [UIImage imageNamed:@"leaderboard_rank"];
    [pageScroller addSubview:topRankPicture2];
    UILabel *topRankName = [[UILabel alloc]init];
    topRankName.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankName.frame = CGRectMake(0, 430 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankName.frame = CGRectMake(0, 430 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName.frame = CGRectMake(0, 450 + x, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:17];
        topRankName.frame = CGRectMake(0, 460 + x, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName.frame = CGRectMake(0, 460 + x, self.view.frame.size.width/2, 20);
    } else {
        topRankName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankName.frame = CGRectMake(0, 460 + x, self.view.frame.size.width/2, 20);
    }
    topRankName.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topRankName];
    
    
    UILabel *topRankHeart = [[UILabel alloc]init];
    topRankHeart.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankHeart.frame = CGRectMake(0, 395 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:12];
        topRankHeart.frame = CGRectMake(0, 395 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankHeart.frame = CGRectMake(0, 425 + x, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:17];
        topRankHeart.frame = CGRectMake(0, 432 + x, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankHeart.frame = CGRectMake(0, 432 + x, self.view.frame.size.width/2, 20);
    } else {
        topRankHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topRankHeart.frame = CGRectMake(0, 432 + x, self.view.frame.size.width/2, 20);
    }
    topRankHeart.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topRankHeart];
    
    
    PFQuery *queryTopRank = [PFUser query];
    [queryTopRank orderByDescending:@"Hearts"];
    queryTopRank.limit = 1;
    [queryTopRank findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Top rank request failed.");
            [Hud removeFromSuperview];
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object top rank.");
            topRankName.text = [objects objectAtIndex:0][@"name"];
            topRankHeart.text = [NSString stringWithFormat:@"%@",[objects objectAtIndex:0][@"Hearts"]];
            NSString *imageUrl = [objects objectAtIndex:0][@"profilePicture"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    topRankPicture.image =  [UIImage imageWithData:data];
                    
                });
            });
            
        }
    }];
    
    
    
    //UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(dialogContainer.bounds.size.width/2, 0, buttonSpacerHeight, dialogContainer.bounds.size.height)];
    //lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    //[dialogContainer addSubview:lineView];
    
    // Top Achiever Label
    UILabel *topAchiever = [[UILabel alloc]init];
    topAchiever.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 290 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 290 + x, self.view.frame.size.width/2, 20);
        }
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:10];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 290 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 290 + x, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 310 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 310 + x, self.view.frame.size.width/2, 20);
        }
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:16];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 20);
        }
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 20);
        }
    } else {
        if([language containsString:@"fr"]) {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 30);
        } else {
            topAchiever.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            topAchiever.frame = CGRectMake(self.view.frame.size.width/2, 325 + x, self.view.frame.size.width/2, 20);
        }
    }
    if([language containsString:@"fr"]) {
        topAchiever.numberOfLines = 2;
    }
    topAchiever.text = [NSString stringWithFormat:NSLocalizedString(@"Top Achiever", nil)];
    
    topAchiever.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchiever];
    
    
    //Top Achiever Picture
    
    UIImageView *topAchieverPicture = [[UIImageView alloc]init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 330 + x, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 330 + x, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 350 + x, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    } else {
        topAchieverPicture.frame = CGRectMake(3*self.view.frame.size.width/4 - 50, 350 + x, 100, 100);
    }
    
    CALayer *topAchieverimageLayer = topAchieverPicture.layer;
    [topAchieverimageLayer setCornerRadius:5];
    [topAchieverimageLayer setBorderWidth:1];
    [topAchieverPicture.layer setCornerRadius:topAchieverPicture.frame.size.width/2];
    [topAchieverimageLayer setMasksToBounds:YES];
    topAchieverPicture.layer.borderWidth = 3.0f;
    topAchieverPicture.contentMode = UIViewContentModeScaleAspectFill;
    topAchieverPicture.layer.borderColor = [UIColor clearColor].CGColor;
    
    [pageScroller addSubview:topAchieverPicture];
    
    UIImageView *topAchieverPicture2 = [[UIImageView alloc]init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328 + x, 88, 88);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 44, 328 + x, 88, 88);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 49, 348 + x, 98, 98);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        
    {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    } else {
        topAchieverPicture2.frame = CGRectMake(3*self.view.frame.size.width/4 - 54, 348 + x, 108, 108);
    }
    topAchieverPicture2.image = [UIImage imageNamed:@"leaderboard_rank"];
    [pageScroller addSubview:topAchieverPicture2];
    
    
    UILabel *topAchieverName = [[UILabel alloc]init];
    topAchieverName.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 430 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 430 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 450 + x, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:17];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 460 + x, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 460 + x, self.view.frame.size.width/2, 20);
    } else {
        topAchieverName.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverName.frame = CGRectMake(self.view.frame.size.width/2, 460 + x, self.view.frame.size.width/2, 20);
    }
    topAchieverName.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchieverName];
    
    UILabel *topAchieverHeart = [[UILabel alloc]init];
    topAchieverHeart.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 395 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:12];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 395 + x, self.view.frame.size.width/2, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 425 + x, self.view.frame.size.width/2, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:17];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 432 + x, self.view.frame.size.width/2, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 432 + x, self.view.frame.size.width/2, 20);
    } else {
        topAchieverHeart.font = [UIFont fontWithName:@"Open Sans" size:14];
        topAchieverHeart.frame = CGRectMake(self.view.frame.size.width/2, 432 + x, self.view.frame.size.width/2, 20);
    }
    topAchieverHeart.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchieverHeart];
    
    
    PFQuery *queryTopAchiever = [PFQuery queryWithClassName:@"Locations"];
    [queryTopAchiever orderByDescending:@"TotalParkHearts"];
    queryTopAchiever.limit = 1;
    [queryTopAchiever findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Top achiever request failed.");
            [Hud removeFromSuperview];
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object top achiever.");
            topAchieverName.text = [objects objectAtIndex:0][@"Location"];
            topAchieverHeart.text = [NSString stringWithFormat:@"%@",[objects objectAtIndex:0][@"TotalParkHearts"]];
            PFFile *imageFile = [objects objectAtIndex:0][@"Image"];
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[activityView1 stopAnimating];
                    //[activityView1 removeFromSuperview];
                    topAchieverPicture.image =  [UIImage imageWithData:data];
                    
                });
            });
        }
    }];
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    
    UILabel *advertNotice = [[UILabel alloc] init];
    //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        advertNotice.frame = CGRectMake(25, 605 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:12];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        advertNotice.frame = CGRectMake(25, 605 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:12];
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        advertNotice.frame = CGRectMake(25, 630 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:14];
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        advertNotice.frame = CGRectMake(25, 630 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:16];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        advertNotice.frame = CGRectMake(25, 630 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:14];
    } else {
        advertNotice.frame = CGRectMake(25, 630 + y, self.view.frame.size.width - 50, 100);//Position of the button
        advertNotice.font = [UIFont fontWithName:@"Open Sans" size:14];
    }
    advertNotice.numberOfLines = 4;
    advertNotice.textAlignment = NSTextAlignmentCenter;
    advertNotice.text = NSLocalizedString(@"Learn how to use the Proludic Sport app to its full potential, read the FAQ's and Terms & Conditions below!", nil);
    [pageScroller addSubview:advertNotice];
    
    UIButton *faqBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        faqBtn.frame = CGRectMake(75, 680 + y, self.view.frame.size.width-150, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        faqBtn.frame = CGRectMake(75, 690 + y, self.view.frame.size.width-150, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        faqBtn.frame = CGRectMake(75, 730 + y, self.view.frame.size.width - 150, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        faqBtn.frame = CGRectMake(90, 730 + y, self.view.frame.size.width-180, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        faqBtn.frame = CGRectMake(90, 730 + y, self.view.frame.size.width-180, 35);//Position of the button
    } else {
        faqBtn.frame = CGRectMake(90, 730 + y, self.view.frame.size.width-180, 35);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [faqBtn setBackgroundImage:[UIImage imageNamed:@"btn_faq_french"] forState:UIControlStateNormal];
    } else {
        [faqBtn setBackgroundImage:[UIImage imageNamed:@"btn_faq"] forState:UIControlStateNormal];
    }
    [faqBtn addTarget:self action:@selector(viewFAQ) forControlEvents:UIControlEventTouchUpInside];
    
    [pageScroller addSubview:faqBtn];
    
    if([[PFUser currentUser][@"HomePark"]  isEqual: @"NotSelected"]) {
        //Add Home Park
        UIButton *addHomeParkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            addHomeParkButton.frame = CGRectMake(75, 670 + y, self.view.frame.size.width-150, 30);//Position of the button
            
        } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
        {
            addHomeParkButton.frame = CGRectMake(75, 670 + y, self.view.frame.size.width-150, 30);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
        {
            addHomeParkButton.frame = CGRectMake(75, 780 + y, self.view.frame.size.width - 150, 40);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            addHomeParkButton.frame = CGRectMake(90, 780 + y, self.view.frame.size.width-180, 40);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            addHomeParkButton.frame = CGRectMake(90, 780 + y, self.view.frame.size.width-180, 35);//Position of the button
        } else {
            addHomeParkButton.frame = CGRectMake(90, 780 + y, self.view.frame.size.width-180, 35);//Position of the button
        }
        if([language containsString:@"fr"]) {
            [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choosepark_french"] forState:UIControlStateNormal];
        } else {
            [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choose"] forState:UIControlStateNormal];
        }
        [addHomeParkButton addTarget:self action:@selector(addHomePark:) forControlEvents:UIControlEventTouchUpInside];
        
        [pageScroller addSubview:addHomeParkButton];
        
    } else {
        // Find nearest Park
        isFindingNearestParkOn = false;
        findParksButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            findParksButton.frame = CGRectMake(75, 720 + y, self.view.frame.size.width-150, 30);//Position of the button
            
        } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
        {
            findParksButton.frame = CGRectMake(75, 720 + y, self.view.frame.size.width-150, 30);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
        {
            findParksButton.frame = CGRectMake(75, 780 + y, self.view.frame.size.width - 150, 40);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            findParksButton.frame = CGRectMake(90, 780 + y, self.view.frame.size.width - 180, 40);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            findParksButton.frame = CGRectMake(90, 770 + y, self.view.frame.size.width - 180, 35);//Position of the button
        } else {
            findParksButton.frame = CGRectMake(90, 770 + y, self.view.frame.size.width - 180, 35);//Position of the button
        }
        NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
        if([language containsString:@"fr"]) {
            [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_french"] forState:UIControlStateNormal];
        } else {
            [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_2"] forState:UIControlStateNormal];
        }
        [findParksButton addTarget:self action:@selector(tapfindNearestParksButton:) forControlEvents:UIControlEventTouchUpInside];
        
        [pageScroller addSubview:findParksButton];
        
    }
    if ([FBSDKAccessToken currentAccessToken]) {
        
        [self getFBFriends];
    }
    
    if([[[PFUser currentUser] objectId]  isEqualToString: @"X4hOIrTlal"]) {
        
        UIButton *parkStats = [[UIButton alloc] init];
        parkStats.frame = CGRectMake(0, 750 + y, 20, 20);
        parkStats.backgroundColor = [UIColor greenColor];
        [parkStats addTarget:self action:@selector(parkStatsBtn) forControlEvents:UIControlEventTouchUpInside];
        [pageScroller addSubview:parkStats];
        
        UIButton *shareBtn = [[UIButton alloc] init];
        shareBtn.frame = CGRectMake(20, 750 + y, 20, 20);
        shareBtn.backgroundColor = [UIColor blueColor];
        [shareBtn addTarget:self action:@selector(tappedHamburger) forControlEvents:UIControlEventTouchUpInside];
        [pageScroller addSubview:shareBtn];
        
        UIButton *trackedEventBtn = [[UIButton alloc] init];
        trackedEventBtn.frame = CGRectMake(40, 750 + y, 20, 20);
        trackedEventBtn.backgroundColor = [UIColor redColor];
        [trackedEventBtn addTarget:self action:@selector(tapTackedEventsBtn) forControlEvents:UIControlEventTouchUpInside];
        [pageScroller addSubview:trackedEventBtn];
        
        UIButton *userStats = [[UIButton alloc] init];
        userStats.frame = CGRectMake(60, 750 + y, 20, 20);
        userStats.backgroundColor = [UIColor yellowColor];
        [userStats addTarget:self action:@selector(tapUserStatsBtn) forControlEvents:UIControlEventTouchUpInside];
        [pageScroller addSubview:userStats];
        
        
    }
    
    [Hud removeFromSuperview];
    
}

-(void)setFriendsGrid:(NSArray*) objects :(NSArray*) collectedFriends {
    
    int count = 0;
    friendsSideScroller.contentSize = CGSizeMake([objects count] * 65, 50);
    for (PFObject *object in objects) {
        
        //Exercise Bar Label
        UILabel *friendHeartsLabel;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 65, 45)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 65, 45)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 70, 50)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 75, 55)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 75, 55)];
        } else {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 38, 75, 55)];
        }
        
        friendHeartsLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        friendHeartsLabel.textColor = [UIColor blackColor];
        friendHeartsLabel.numberOfLines = 1;
        friendHeartsLabel.textAlignment = NSTextAlignmentCenter;
        friendHeartsLabel.text = [object objectForKey:@"username"];
        
        UILabel *friendsActiveLabel;
        UIImageView *heartImg;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 65, 45)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 10, 77, 10, 10)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 65, 45)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 10, 77, 10, 10)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 70, 50)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 7, 77, 10, 10)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 75, 55)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 10, 77, 10, 10)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 75, 55)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 10, 77, 10, 10)];
        } else {
            friendsActiveLabel = [[UILabel alloc] initWithFrame:CGRectMake(count*63, 58, 75, 55)];
            heartImg = [[UIImageView alloc] initWithFrame:CGRectMake(count*63 + 10, 77, 10, 10)];
        }
        
        friendsActiveLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        friendsActiveLabel.textColor = [UIColor blackColor];
        friendsActiveLabel.numberOfLines = 1;
        friendsActiveLabel.textAlignment = NSTextAlignmentCenter;
        /*NSDate *createdAt = [object updatedAt];
         NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
         formatter.dateFormat = @"dd/MM/yy";
         NSString *string = [formatter stringFromDate:createdAt];
         friendsActiveLabel.text = string;*/
        NSString *string = [NSString stringWithFormat:@"%d", object[@"Hearts"]];
        friendsActiveLabel.text = string;
        heartImg.image = [UIImage imageNamed:@"Heart"];
        
        
        UIButton *friendPictureBtn = [[UIButton alloc]init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
            
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
        } else {
            friendPictureBtn.frame = CGRectMake(count*63 + 15, 13, 40, 40);
        }
        
        [friendPictureBtn setTitle:[object objectId] forState:UIControlStateNormal];
        friendPictureBtn.titleLabel.layer.opacity = 0.0f;
        friendPictureBtn.layer.cornerRadius = friendPictureBtn.frame.size.width / 2;
        friendPictureBtn.clipsToBounds = YES;
        friendPictureBtn.contentMode = UIViewContentModeScaleAspectFill;
        
        if([object[@"profilePicture"] isEqualToString:@"NoPicture"]) {
            //User hasnt set a profile picture
            [friendPictureBtn setBackgroundImage:[UIImage imageNamed:@"profile_pic"] forState:UIControlStateNormal];
        } else {
            NSString *imageUrl = [object objectForKey:@"profilePicture"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [friendPictureBtn setBackgroundImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
                    
                });
            });
        }
        
        [friendsSideScroller addSubview:friendHeartsLabel];
        [friendsSideScroller addSubview:friendsActiveLabel];
        [friendsSideScroller addSubview:friendPictureBtn];
        [friendsSideScroller addSubview:heartImg];
        
        count++;
        
    }
    
    UIView *friendLabelView = [[UIView alloc] init];
    friendLabelView.frame = CGRectMake(0, 490, self.view.frame.size.width, 30);
    friendLabelView.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    [pageScroller addSubview:friendLabelView];
    
    UILabel *friendsLabel = [[UILabel alloc] init];
    friendsLabel.frame = CGRectMake(0, 5, self.view.frame.size.width, 30);
    friendsLabel.text = NSLocalizedString(@"Friends Activity", nil);
    friendsLabel.textAlignment = NSTextAlignmentCenter;
    friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
    [friendLabelView addSubview:friendsLabel];
    
}

-(void)tapShareBtn  {
    NSString *shareString = [NSString stringWithFormat:@"I'm using the Proludic Sport App! You should join and add me as a friend. My username is %@.\n\n https://itunes.apple.com/us/app/proludic-sport/id1268691512?mt=8", [PFUser currentUser][@"username"]];
    NSArray* sharedObjects=[NSArray arrayWithObjects:shareString,  nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
    
}

-(void)parkStatsBtn {
    
    PFQuery *locationQuery = [PFQuery queryWithClassName:@"Locations"];
    [locationQuery setLimit:999];
    [locationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            
            for(PFObject *object in objects) {
                
                PFQuery *userQuery = [PFUser query];
                [userQuery setLimit:999];
                [userQuery findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
                    if(!error) {
                        
                        NSMutableArray *parkArray = [[NSMutableArray alloc] init];
                        
                        for(PFObject *user in users) {
                            
                            if(!user[@"HomePark"] == nil) {
                                NSString *homeParkString = user[@"HomePark"];
                                [parkArray addObject:homeParkString];
                            }
                            
                        }
                        
                        int occurrences = 0;
                        for(NSString *string in parkArray){
                            occurrences += ([string isEqualToString:[object objectId]]?1:0);
                        }
                        
                        NSLog(@"Park Name: %@ Number of Users: %d", object[@"Location"], occurrences);
                        NSString *parkStatToAdd = [NSString stringWithFormat:@"Park Name: %@ Number of Users: %d", object[@"Location"], occurrences];
                        [parkStatsArray addObject:parkStatToAdd];
                        
                        
                    } else {
                        NSLog(@"%@", error.description);
                    }
                }];
                
            }
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(void)tappedHamburger {
    NSLog(@"%@", parkStatsArray);
}

-(void)tapTackedEventsBtn {
    PFQuery *query = [PFQuery queryWithClassName:@"TrackedEvents"];
    [query setLimit:999];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            
            int count = 0;
            int heartCount = 0;
            int exerciseCount = 0;
            for(PFObject *object in objects) {
                if([object[@"Date"] isEqualToString:@"28/11/2017"] || [object[@"Date"] isEqualToString:@"27/11/2017"] || [object[@"Date"] isEqualToString:@"26/11/2017"] || [object[@"Date"] isEqualToString:@"25/11/2017"] || [object[@"Date"] isEqualToString:@"24/11/2017"] || [object[@"Date"] isEqualToString:@"23/11/2017"] || [object[@"Date"] isEqualToString:@"29/11/2017"]) {
                    
                    int heartInt = [object[@"Hearts"] intValue];
                    int exerciseInt = [object[@"Exercises"] intValue];
                    
                    heartCount = heartCount + heartInt;
                    exerciseCount = exerciseCount + exerciseInt;
                    
                    count++;
                }
            }
            
            NSLog(@"%d %d %d", exerciseCount, heartCount, count);
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(void)tapUserStatsBtn {
    PFQuery *query = [PFUser query];
    [query setLimit:999];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            
            int count = 0;
            int maleCount = 0;
            int ahCount = 0;
            for(PFObject *object in objects) {
                int maleInt = [object[@"isMale"] intValue];
                int ahInt = [object[@"AppleHealth"] intValue];
                
                maleCount = maleCount + maleInt;
                ahCount = ahCount + ahInt;
                
                count++;
            }
            
            NSLog(@"%d %d %d", ahCount, maleCount, count);
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(void)viewFAQ {
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        SWRevealViewController *TermControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Terms"];
        
        [self.navigationController pushViewController:TermControl animated:NO];
    } else {
        SWRevealViewController *FAQControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"FAQ"];
        
        [self.navigationController pushViewController:FAQControl animated:NO];
    }
    
}

-(IBAction)autoFindNearestPark:(id)sender {
    if(!isFindingNearestParkOn) {
        isFindingNearestParkOn = true;
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
            [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
        
        autoFind = YES;
    }
}

-(IBAction)addHomePark:(id)sender {
    
    [self tapfindNearestParksButton:nil];
}

-(IBAction)tapfindNearestParksButton:(id)sender
{
    if(!isFindingNearestParkOn) {
        NSLocale *currentLocale = [NSLocale currentLocale];
        NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
        NSLog(@"%@", countryCode);
        if([countryCode containsString:@"AU"]) {
            pageScroller.scrollEnabled = NO;
            for(UIView *subview in [pageScroller subviews]) {
                subview.userInteractionEnabled = NO;
            }
            if ([[UIScreen mainScreen] bounds].size.height == 812) {//iPhone X size
                showMapAus1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
            }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
                showMapAus1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height+200, self.view.frame.size.width, self.view.frame.size.height)];
            }
            else {
                showMapAus1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
            }
            
            [showMapAus1 setBackgroundColor:[UIColor whiteColor]];
            showMapAus1.layer.zPosition = 1;
            showMapAus1.alpha = 0.95;
            showMapAus1.userInteractionEnabled = YES;
            
            backAusMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [backAusMapButton setFrame:CGRectMake(self.view.frame.size.width - 45, 50, 35, 35)];
            backAusMapButton.tag = 1;
            [backAusMapButton addTarget:self action:@selector(backTappedShowMapAus:) forControlEvents:UIControlEventTouchUpInside];
            [backAusMapButton setImage:[UIImage imageNamed:@"btn_x_black"] forState:UIControlStateNormal];
            [showMapAus1 addSubview:backAusMapButton];
            [UIView animateWithDuration:0.5f // This can be changed.
                             animations:^
             {
                 if ([[UIScreen mainScreen] bounds].size.height == 812) {
                     [showMapAus1 setFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height)];
                 }
                 else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
                     [showMapAus1 setFrame:CGRectMake(0, 320, self.view.frame.size.width, self.view.frame.size.height)];
                 }
                 else {
                     [showMapAus1 setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                 }
             }
                             completion:^(BOOL finished)
             {
                 if ([[UIScreen mainScreen] bounds].size.height == 812) {//iPhone XR/Max size
                     [showMapAus1 setFrame:CGRectMake(0, 120, self.view.frame.size.width, self.view.frame.size.height)];
                 }
                 else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
                     [showMapAus1 setFrame:CGRectMake(0, 320, self.view.frame.size.width, self.view.frame.size.height)];
                 }
                 else {
                     [showMapAus1 setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                 }
             }];
            
            [self setupShowMapAus];
            [self.view addSubview:showMapAus1];
            
            
        } else {
            NSLog(@"CLICK THE NEAREST BUTTON");
            isFindingNearestParkOn = true;
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
                [locationManager requestWhenInUseAuthorization];
            
            [locationManager startUpdatingLocation];
        }
    }
}
-(void) setupShowMapAus {
    showMapAus2 = [[UIScrollView alloc] init];
    showMapAus3 = [[UIScrollView alloc] init];
    UIImageView *ausMap = [[UIImageView alloc] init];
    ausMap.image = [UIImage imageNamed:@"australia"];
    UIButton *ausMapButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton3 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton4 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton5 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton6 = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *ausMapButton7 = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        showMapAus2.frame = CGRectMake(0, 300, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 200, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 200, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    } else {
        showMapAus2.frame = CGRectMake(0, 100, self.view.frame.size.width*2, self.view.frame.size.height - 100); //Position of the scroller
        ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 170, 100, 340, 300);//Position of the button
        ausMapButton1.frame = CGRectMake(self.view.frame.size.width/2 - 170, 120, 135, 200);//Position of the button
        ausMapButton2.frame = CGRectMake(self.view.frame.size.width/2 - 40, 100, 80, 130);//Position of the button
        ausMapButton3.frame = CGRectMake(self.view.frame.size.width/2 - 40, 230, 100, 150);//Position of the button
        ausMapButton4.frame = CGRectMake(self.view.frame.size.width/2 + 40, 100, 150, 150);//Position of the button
        ausMapButton5.frame = CGRectMake(self.view.frame.size.width/2 + 60, 250, 110, 65);//Position of the button
        ausMapButton6.frame = CGRectMake(self.view.frame.size.width/2 + 60, 315, 80, 40);//Position of the button
        ausMapButton7.frame = CGRectMake(self.view.frame.size.width/2 + 85, 360, 50, 50);//Position of the button
        showMapAus3.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height - 10);//Position of the button
        //showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3 .frame.size.height*100 + 200);
    }
    showMapAus2.bounces = YES;
    //showMapAus2.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    showMapAus2.delegate = self;
    showMapAus2.scrollEnabled = NO;
    showMapAus2.userInteractionEnabled = YES;
    [showMapAus2 setShowsHorizontalScrollIndicator:NO];
    [showMapAus2 setShowsVerticalScrollIndicator:NO];
    
    showMapAus3.delegate = self;
    showMapAus3.scrollEnabled = YES;
    showMapAus3.userInteractionEnabled = YES;
    [showMapAus3 setShowsHorizontalScrollIndicator:NO];
    [showMapAus3 setShowsVerticalScrollIndicator:NO];
    [showMapAus1 addSubview:showMapAus2];
    
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0, 5, self.view.frame.size.width, 30);
    label.text = NSLocalizedString(@"Select your state", nil);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Ethnocentric" size:14];
    [showMapAus2 addSubview:label];
    
    /*
     [showMapAus3 setBackgroundColor:[UIColor yellowColor]];
     [ausMapButton1 setBackgroundColor:[UIColor blackColor]];
     [ausMapButton2 setBackgroundColor:[UIColor brownColor]];
     [ausMapButton3 setBackgroundColor:[UIColor redColor]];
     [ausMapButton4 setBackgroundColor:[UIColor yellowColor]];
     [ausMapButton5 setBackgroundColor:[UIColor greenColor]];
     [ausMapButton6 setBackgroundColor:[UIColor blueColor]];
     [ausMapButton7 setBackgroundColor:[UIColor grayColor]];
     ausMapButton1.alpha = 0.5;
     ausMapButton2.alpha = 0.5;
     ausMapButton3.alpha = 0.5;
     ausMapButton4.alpha = 0.5;
     ausMapButton5.alpha = 0.5;
     ausMapButton6.alpha = 0.5;
     ausMapButton7.alpha = 0.5;
     */
    
    ausMapButton1.tag = 1;
    ausMapButton2.tag = 2;
    ausMapButton3.tag = 3;
    ausMapButton4.tag = 4;
    ausMapButton5.tag = 5;
    ausMapButton6.tag = 6;
    ausMapButton7.tag = 7;
    [ausMapButton1 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton2 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton3 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton4 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton5 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton6 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    [ausMapButton7 addTarget:self action:@selector(chooseAusRegion:) forControlEvents:UIControlEventTouchUpInside];
    
    [showMapAus2 addSubview:ausMap];
    [showMapAus2 addSubview:ausMapButton1];
    [showMapAus2 addSubview:ausMapButton2];
    [showMapAus2 addSubview:ausMapButton3];
    [showMapAus2 addSubview:ausMapButton4];
    [showMapAus2 addSubview:ausMapButton5];
    [showMapAus2 addSubview:ausMapButton6];
    [showMapAus2 addSubview:ausMapButton7];
    [showMapAus2 addSubview:showMapAus3];
}
-(IBAction)chooseAusRegion: (UIButton*) sender {
    for(UIView *subview in [showMapAus3 subviews]) {
        [subview removeFromSuperview];
    }
    isFindingNearestParkOn = true;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
    
    backAusMapButton.tag = 2;
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0, 5, self.view.frame.size.width, 30);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"Ethnocentric" size:14];
    [showMapAus3 addSubview:label];
    
    UIImageView *ausMap = [[UIImageView alloc] init];
    ausMap.frame = CGRectMake(self.view.frame.size.width/2 - 115, 50, 230, 200);//Position of the button
    [showMapAus3 addSubview:ausMap];
    
    UILabel *label2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 568) {
        label2.frame = CGRectMake(0, 250, self.view.frame.size.width, 30);
    } else {
        label2.frame = CGRectMake(0, 280, self.view.frame.size.width, 30);
    }
    label2.text = NSLocalizedString(@"Nearest Parks To You", nil);
    label2.textAlignment = NSTextAlignmentCenter;
    label2.font = [UIFont fontWithName:@"Ethnocentric" size:14];
    [showMapAus3 addSubview:label2];
    switch (sender.tag) {
        case 1:
            label.text = NSLocalizedString(@"Western Australia", nil);
            ausMap.image = [UIImage imageNamed:@"western"];
            selectedAusState = @"Western Australia";
            break;
        case 2:
            label.text = NSLocalizedString(@"Northern Territory", nil);
            ausMap.image = [UIImage imageNamed:@"northern"];
            selectedAusState = @"Northern Territory";
            break;
        case 3:
            label.text = NSLocalizedString(@"South Australia", nil);
            ausMap.image = [UIImage imageNamed:@"southern"];
            selectedAusState = @"South Australia";
            break;
        case 4:
            label.text = NSLocalizedString(@"Queensland", nil);
            ausMap.image = [UIImage imageNamed:@"queensland"];
            selectedAusState = @"Queensland";
            break;
        case 5:
            label.text = NSLocalizedString(@"New South Wales", nil);
            ausMap.image = [UIImage imageNamed:@"newsouthwales"];
            selectedAusState = @"New South Wales";
            break;
        case 6:
            label.text = NSLocalizedString(@"Victoria", nil);
            ausMap.image = [UIImage imageNamed:@"victoria"];
            selectedAusState = @"Victoria";
            break;
        case 7:
            label.text = NSLocalizedString(@"Tasmania", nil);
            ausMap.image = [UIImage imageNamed:@"tasmania"];
            selectedAusState = @"Tasmania";
            break;
        default:
            break;
    }
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        showMapAus2.contentOffset = CGPointMake(self.view.frame.size.width, 0);
    } completion:NULL];
}
-(IBAction)backTappedShowMapAus:(UIButton*)sender {
    if(sender.tag == 1) {
        pageScroller.scrollEnabled = YES;
        isFindingNearestParkOn = false;
        
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = YES;
        }
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             self.navigationController.navigationBar.alpha = 1;
             [showMapAus1 setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             self.navigationController.navigationBar.alpha = 1;
             [showMapAus1 setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
             [showMapAus1 removeFromSuperview];
         }];
    } else {
        backAusMapButton.tag = 1;
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            showMapAus2.contentOffset = CGPointMake(0, 0);
        } completion:NULL];
    }
}
-(void)showLoading
{
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = @"Loading";
    //Start the animation
    [activityImageView startAnimating];
    
    
    //Add your custom activity indicator to your current view
    [pageScroller addSubview:activityImageView];
    Hud.customView = activityImageView;
}

-(void)getFBFriends {
    if ([FBSDKAccessToken currentAccessToken]) {
        
        NSMutableArray *appFBFriends = [[NSMutableArray alloc] init];
        
        
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"me/friends"
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            
            
            // Handle the result
            if (!error) {
                NSArray* friends = [result objectForKey:@"data"];
                NSLog(@"-------------123--------------%@",result);
                NSLog(@"-------------123--------------%d",[friends count]);
                for (NSDictionary<FBSDKGraphRequestConnectionDelegate>* friend in friends) {
                    [appFBFriends addObject:friend[@"id"]];//Add the ID to the array.
                }
                
                NSLog(@"Friends who have the app installed: %@",appFBFriends);
                
                if (appFBFriends.count == 0) {
                    [Hud removeFromSuperview];
                } else {
                    PFQuery *friendsQuery = [PFUser query];
                    
                    [friendsQuery whereKey:@"facebookID" containedIn:appFBFriends];
                    
                    [friendsQuery findObjectsInBackgroundWithBlock:^(NSArray * objects, NSError * error) {
                        if (!error) {
                            if (objects.count == 0) {
                                [Hud removeFromSuperview];
                            }else{
                                NSMutableArray *arrayOfFriends = [[NSMutableArray alloc] initWithArray:[PFUser currentUser][@"Friends"] copyItems:YES];
                                
                                int friendsCounter = 0;
                                
                                for (PFObject *object in objects) {
                                    
                                    if (![arrayOfFriends containsObject:object.objectId]) {
                                        [arrayOfFriends addObject:object.objectId];
                                        [PFCloud callFunctionInBackground:@"AddNewFriend"
                                                           withParameters:@{@"senderUserId": [[PFUser currentUser] objectId], @"recipientUserId": [object objectId]}
                                                                    block:^(NSString *addFriendString, NSError *error12) {
                                                                        if (!error12) {
                                                                            
                                                                        } else {
                                                                            NSLog(error12.description);
                                                                        }
                                                                    }];
                                        friendsCounter++;
                                    }
                                    
                                }
                                
                                NSLog(@"%@", arrayOfFriends);
                                
                                if (friendsCounter > 0) {
                                    [PFUser currentUser][@"Friends"] = arrayOfFriends;
                                    
                                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                        if (succeeded && !error) {
                                            [Hud removeFromSuperview];
                                        }
                                    }];
                                } else {
                                    [Hud removeFromSuperview];
                                }
                                
                                
                            }
                        }
                    }];
                }
            } else {
                NSLog(@"Error: %@",error.description);
                [Hud removeFromSuperview];
            }
        }];
    }
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if (currentLocation != nil) {
        [self showLoading];
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        NSLog(@"Longitude: %@",[NSString stringWithFormat:@"%.8f",currentLocation.coordinate.longitude]);
        NSLog(@"Latitude: %@",[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude]);
        
        if(autoFind) {
            NSLog(@"AUTO FIND ACTIVATED");
            autoFind = NO;
            
            PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
            [query setLimit:999];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    
                    int count = 1;
                    NSMutableArray *collectedObjects = [[NSMutableArray alloc] init];
                    NSMutableArray *collectedDistances =[[NSMutableArray alloc] init];
                    
                    for (PFObject *object in objects) {
                        
                        PFGeoPoint *geoPoint = object[@"StartingPoint"];
                        CLLocation *parkLocation = [[CLLocation alloc]init];
                        [parkLocation initWithLatitude: geoPoint.latitude longitude:geoPoint.longitude];
                        CLLocationDistance distanceInMeters = [currentLocation getDistanceFrom:parkLocation];
                        float distanceinMiles;
                        
                        if([language containsString:@"fr"]) {
                            distanceinMiles = distanceInMeters / 1000; // IT IS ACTUALLY KILOMETERS
                        } else {
                            distanceinMiles = distanceInMeters * 0.000621371;
                        }
                        
                        
                        if (distanceinMiles < 0.5) {
                            [collectedObjects addObject:object];
                            [collectedDistances addObject:@(distanceinMiles)];
                        }
                    }
                    
                    for (int i = 0; i < [collectedDistances count]; i++) {
                        
                        for (int j = i+1; j < [collectedDistances count]; j++) {
                            if([[collectedDistances objectAtIndex:j] floatValue] < [[collectedDistances objectAtIndex:i] floatValue]) {
                                float tmp = [[collectedDistances objectAtIndex:i] floatValue];
                                [collectedDistances replaceObjectAtIndex:i withObject:[collectedDistances objectAtIndex:j]];
                                [collectedDistances replaceObjectAtIndex:j withObject:@(tmp)];
                                
                                PFObject *tmp2 = [collectedObjects objectAtIndex:i];
                                [collectedObjects replaceObjectAtIndex:i withObject:[collectedObjects objectAtIndex:j]];
                                [collectedObjects replaceObjectAtIndex:j withObject:tmp2];
                            }
                        }
                    }
                    
                    for (int i = 0; i < [collectedObjects count]; i++) {
                        
                        PFObject *object = [collectedObjects objectAtIndex:i];
                        if([[object objectId] isEqualToString:[PFUser currentUser][@"HomePark"]]) {
                            NSLog(@"THIS IS THIS CURRENT HOME PARK DO NOTHING");
                        } else {
                            //NSLog(@"123123123123123123123123123123123");
                            NSString *parkName = object[@"Location"];
                            requiredID = [object objectId];
                            
                            homeParkView = [[UIView alloc] init];
                            homeParkView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 175);
                            homeParkView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.95];
                            homeParkView.alpha = 0;
                            [self.view addSubview:homeParkView];
                            
                            UILabel *updateLabel = [[UILabel alloc] init];
                            updateLabel.frame = CGRectMake(30, 15, self.view.frame.size.width - 60, 30);
                            updateLabel.text = NSLocalizedString(@"Update", nil);
                            updateLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
                            updateLabel.textColor = [UIColor whiteColor];
                            updateLabel.textAlignment = NSTextAlignmentCenter;
                            [homeParkView addSubview:updateLabel];
                            
                            UITextView *updateText = [[UITextView alloc] init];
                            updateText.frame = CGRectMake(30, 45, self.view.frame.size.width - 60, 80);
                            updateText.editable = NO;
                            updateText.backgroundColor = [UIColor clearColor];
                            updateText.text = [NSString stringWithFormat:@"We have found a park closer to your location that is not currently set as your home park named %@. Would you like to set it as your home park?", parkName];
                            updateText.font = [UIFont fontWithName:@"Open Sans" size:12];
                            updateText.textColor = [UIColor whiteColor];
                            updateText.textAlignment = NSTextAlignmentCenter;
                            [homeParkView addSubview:updateText];
                            
                            UIButton *yesBtn = [[UIButton alloc] init];
                            if([language containsString:@"fr"]) {
                                [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
                            } else {
                                [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
                            }
                            [yesBtn addTarget:self action:@selector(tapYesBtn) forControlEvents:UIControlEventTouchUpInside];
                            yesBtn.frame = CGRectMake(40, 120, 120, 35);
                            [homeParkView addSubview:yesBtn];
                            
                            UIButton *noBtn = [[UIButton alloc] init];
                            if([language containsString:@"fr"]) {
                                [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
                            } else {
                                [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
                            }
                            [noBtn addTarget:self action:@selector(tapNoBtn) forControlEvents:UIControlEventTouchUpInside];
                            noBtn.frame = CGRectMake(self.view.frame.size.width - 160, 120, 120, 35);
                            [homeParkView addSubview:noBtn];
                            
                            [UIView animateWithDuration:0.4f animations:^{
                                [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height - 175, self.view.frame.size.width, 175)];
                                homeParkView.alpha = 1;
                            } completion:^(BOOL finished) {
                                [UIView animateWithDuration:0.2f animations:^{
                                    [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height - 170, self.view.frame.size.width, 175)];
                                }];
                            }];
                            
                        }
                    }
                    
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
                [Hud removeFromSuperview];
            }];
            
        } else {
            int y = 0;
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                y = 170;
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
            {
                y = 170;
            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
            {
                y = 210;
            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                y = 210;
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                y = 210;
            }
            NSLocale *currentLocale = [NSLocale currentLocale];
            NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
            NSLog(@"%@", countryCode);
            if([countryCode containsString:@"AU"]) {
                PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
                [query setLimit:999];
                [query whereKey:@"State" equalTo:selectedAusState];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        if([objects count] <= 0) {
                            UILabel *label2 = [[UILabel alloc] init];
                            label2.frame = CGRectMake(0,350, self.view.frame.size.width, 30);
                            label2.text = NSLocalizedString(@"There is no park nearby.", nil);
                            label2.textAlignment = NSTextAlignmentCenter;
                            label2.font = [UIFont fontWithName:@"Open Sans" size:16];
                            [showMapAus3 addSubview:label2];
                        } else {
                            UIButton *viewMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                            locationsObj = [[NSMutableArray alloc] init];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 200, 30, 30);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 200, 30, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 300, 40, 40);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 300, 40, 40);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 300, 40, 40);//Position of the button
                            }
                            [viewMapButton setBackgroundImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
                            [viewMapButton addTarget:self action:@selector(tapViewMapBtn:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [showMapAus3 addSubview:viewMapButton];
                            // The find succeeded.
                            NSLog(@"Successfully retrieved %d locations.", objects.count);
                        }
                        // Do something with the found objects
                        int count = 1;
                        //pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 100);
                        NSMutableArray *collectedObjects = [[NSMutableArray alloc] init];
                        NSMutableArray *collectedDistances =[[NSMutableArray alloc] init];
                        
                        for (PFObject *object in objects) {
                            
                            PFGeoPoint *geoPoint = object[@"StartingPoint"];
                            CLLocation *parkLocation = [[CLLocation alloc]init];
                            [parkLocation initWithLatitude: geoPoint.latitude longitude:geoPoint.longitude];
                            CLLocationDistance distanceInMeters = [currentLocation getDistanceFrom:parkLocation];
                            float distanceinKm;
                            
                            distanceinKm = distanceInMeters/1000;
                            //if (distanceinMiles < 25) {
                            [collectedObjects addObject:object];
                            [collectedDistances addObject:@(distanceinKm)];
                            //}
                        }
                        
                        for (int i = 0; i < [collectedDistances count]; i++) {
                            
                            for (int j = i+1; j < [collectedDistances count]; j++) {
                                if([[collectedDistances objectAtIndex:j] floatValue] < [[collectedDistances objectAtIndex:i] floatValue]) {
                                    float tmp = [[collectedDistances objectAtIndex:i] floatValue];
                                    [collectedDistances replaceObjectAtIndex:i withObject:[collectedDistances objectAtIndex:j]];
                                    [collectedDistances replaceObjectAtIndex:j withObject:@(tmp)];
                                    
                                    PFObject *tmp2 = [collectedObjects objectAtIndex:i];
                                    [collectedObjects replaceObjectAtIndex:i withObject:[collectedObjects objectAtIndex:j]];
                                    [collectedObjects replaceObjectAtIndex:j withObject:tmp2];
                                }
                            }
                        }
                        
                        
                        for (int i = 0; i < [collectedObjects count]; i++) {
                            
                            PFObject *object = [collectedObjects objectAtIndex:i];
                            
                            [locationsObj addObject:object];
                            UILabel *nearestPark = [[UILabel alloc]init];
                            UILabel *nearestParkBg = [[UILabel alloc]init];
                            nearestPark.numberOfLines = 1;
                            nearestPark.textColor = [UIColor blackColor];
                            UITextView *nearestParkDistance = [[UITextView alloc]init];
                            nearestParkDistance.editable = NO;
                            nearestParkDistance.textColor = [UIColor blackColor];
                            UIButton *addParkBtn = [[UIButton alloc] init];
                            UIButton *viewParkBtn = [[UIButton alloc] init];
                            
                            if ([[UIScreen mainScreen] bounds].size.height == 480)
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestPark.frame = CGRectMake(5, 250 + count * 50, 120, 30);
                                nearestParkBg.frame = CGRectMake(0, 250 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestParkDistance.frame = CGRectMake(0, 250 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(250, 250 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(285, 250 + count * 50, 30, 30);
                                
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568) // iPhone 5/5S
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestPark.frame = CGRectMake(5, 250 + count * 50, 120, 30);
                                nearestParkBg.frame = CGRectMake(0, 250 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestParkDistance.frame = CGRectMake(0, 250 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(250, 250 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(285, 250 + count * 50, 30, 30);
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(5, 300 + count * 50, 130, 30);
                                nearestParkBg.frame = CGRectMake(0, 300 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(0, 300 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(300, 300 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(335, 300 + count * 50, 30, 30);
                                
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:16];
                                nearestPark.frame = CGRectMake(5, 350 + count * 50, 140, 30);
                                nearestParkBg.frame = CGRectMake(0, 350 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:16];
                                nearestParkDistance.frame = CGRectMake(0, 350 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(325, 350 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(360, 350 + count * 50, 30, 30);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 350 + count * 50, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 350 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 350 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(295, 350 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(330, 350 + count * 50, 30, 30);
                            }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 350 + count * 50, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 350 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 350 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(295, 350 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(330, 350 + count * 50, 30, 30);
                            } else {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 350 + count * 50, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 350 + count * 50, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 350 + count * 50, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(295, 350 + count * 50, 30, 30);
                                viewParkBtn.frame = CGRectMake(330, 350 + count * 50, 30, 30);
                            }
                            nearestPark.textAlignment = NSTextAlignmentLeft;
                            nearestParkDistance.textAlignment = NSTextAlignmentCenter;
                            nearestParkDistance.textContainerInset = UIEdgeInsetsMake(5, 0, 0, 5);
                            if(count % 2 == 0) {
                                nearestParkBg.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                            }
                            nearestParkDistance.backgroundColor = [UIColor clearColor];
                            nearestPark.text = object[@"Location"];
                            if([language containsString:@"fr"]) {
                                nearestParkDistance.text = [NSString stringWithFormat:@"%.2f km", [[collectedDistances objectAtIndex:i] floatValue]];
                            } else {
                                nearestParkDistance.text = [NSString stringWithFormat:@"%.2f km", [[collectedDistances objectAtIndex:i] floatValue]];
                            }
                            
                            [addParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
                            [addParkBtn setImage:[UIImage imageNamed:@"btn_addhome"] forState:UIControlStateNormal];
                            [addParkBtn addTarget:self action:@selector(tapAddParkBtn:) forControlEvents:UIControlEventTouchUpInside];
                            [viewParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
                            [viewParkBtn setImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
                            [viewParkBtn addTarget:self action:@selector(tapViewParkBtn:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [showMapAus3 addSubview:nearestParkBg];
                            [showMapAus3 addSubview:nearestPark];
                            
                            [showMapAus3  addSubview:nearestParkDistance];
                            [showMapAus3  addSubview:addParkBtn];
                            [showMapAus3  addSubview:viewParkBtn];
                            count++;
                            
                            
                            
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3.frame.size.height + count * 51);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568){
                                showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3.frame.size.height + count * 51);
                            } else {
                                showMapAus3.contentSize = CGSizeMake(self.view.frame.size.width, showMapAus3.frame.size.height + count * 51);
                            }
                        }
                    } else {
                        // Log details of the failure
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                    }
                    [Hud removeFromSuperview];
                }];
            } else {
                PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
                [query setLimit:999];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        UIButton *viewMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
                        //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                        locationsObj = [[NSMutableArray alloc] init];
                        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 700 + y, 30, 30);//Position of the button
                            
                        } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 700 + y, 30, 30);//Position of the button
                        } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 800 + y, 40, 40);//Position of the button
                        } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 800 + y, 40, 40);//Position of the button
                        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 800 + y, 40, 40);//Position of the button
                        }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
                        {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 1010 + y, 40, 40);//Position of the button
                        } else {
                            viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 800 + y, 40, 40);//Position of the button
                        }
                        [viewMapButton setBackgroundImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
                        [viewMapButton addTarget:self action:@selector(tapViewMapBtn:) forControlEvents:UIControlEventTouchUpInside];
                        
                        [pageScroller addSubview:viewMapButton];
                        // The find succeeded.
                        NSLog(@"Successfully retrieved %d locations.", objects.count);
                        // Do something with the found objects
                        int count = 1;
                        //pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 100);
                        NSMutableArray *collectedObjects = [[NSMutableArray alloc] init];
                        NSMutableArray *collectedDistances =[[NSMutableArray alloc] init];
                        
                        for (PFObject *object in objects) {
                            
                            PFGeoPoint *geoPoint = object[@"StartingPoint"];
                            CLLocation *parkLocation = [[CLLocation alloc]init];
                            [parkLocation initWithLatitude: geoPoint.latitude longitude:geoPoint.longitude];
                            CLLocationDistance distanceInMeters = [currentLocation getDistanceFrom:parkLocation];
                            float distanceinMiles;
                            
                            if([language containsString:@"fr"]) {
                                distanceinMiles = distanceInMeters / 1000; // IT IS ACTUALLY KILOMETERS
                            } else {
                                distanceinMiles = distanceInMeters * 0.000621371;
                            }
                            
                            
                            if([PFUser currentUser][@"isAdmin"]) {
                                if (distanceinMiles < 100) { // distance < 25 miles
                                    [collectedObjects addObject:object];
                                    [collectedDistances addObject:@(distanceinMiles)];
                                }
                            } else {
                                if (distanceinMiles < 25) { // distance < 25 miles
                                    [collectedObjects addObject:object];
                                    [collectedDistances addObject:@(distanceinMiles)];
                                }
                            }
                        }
                        
                        for (int i = 0; i < [collectedDistances count]; i++) {
                            
                            for (int j = i+1; j < [collectedDistances count]; j++) {
                                if([[collectedDistances objectAtIndex:j] floatValue] < [[collectedDistances objectAtIndex:i] floatValue]) {
                                    float tmp = [[collectedDistances objectAtIndex:i] floatValue];
                                    [collectedDistances replaceObjectAtIndex:i withObject:[collectedDistances objectAtIndex:j]];
                                    [collectedDistances replaceObjectAtIndex:j withObject:@(tmp)];
                                    
                                    PFObject *tmp2 = [collectedObjects objectAtIndex:i];
                                    [collectedObjects replaceObjectAtIndex:i withObject:[collectedObjects objectAtIndex:j]];
                                    [collectedObjects replaceObjectAtIndex:j withObject:tmp2];
                                }
                            }
                        }
                        
                        
                        for (int i = 0; i < [collectedObjects count]; i++) {
                            
                            PFObject *object = [collectedObjects objectAtIndex:i];
                            
                            [locationsObj addObject:object];
                            UILabel *nearestPark = [[UILabel alloc]init];
                            UILabel *nearestParkBg = [[UILabel alloc]init];
                            nearestPark.numberOfLines = 1;
                            nearestPark.textColor = [UIColor blackColor];
                            UITextView *nearestParkDistance = [[UITextView alloc]init];
                            nearestParkDistance.editable = NO;
                            nearestParkDistance.textColor = [UIColor blackColor];
                            UIButton *addParkBtn = [[UIButton alloc] init];
                            UIButton *viewParkBtn = [[UIButton alloc] init];
                            
                            if ([[UIScreen mainScreen] bounds].size.height == 480)
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestPark.frame = CGRectMake(5, 750 + count * 50 + y, 120, 30);
                                nearestParkBg.frame = CGRectMake(0, 750 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestParkDistance.frame = CGRectMake(0, 750 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(250, 750 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(285, 750 + count * 50 + y, 30, 30);
                                
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568) // iPhone 5/5S
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestPark.frame = CGRectMake(5, 750 + count * 50 + y, 120, 30);
                                nearestParkBg.frame = CGRectMake(0, 750 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
                                nearestParkDistance.frame = CGRectMake(0, 750 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(250, 750 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(285, 750 + count * 50 + y, 30, 30);
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(5, 800 + count * 50 + y, 130, 30);
                                nearestParkBg.frame = CGRectMake(0, 800 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(0, 800 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(300, 800 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(335, 800 + count * 50 + y, 30, 30);
                                
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:16];
                                nearestPark.frame = CGRectMake(5, 850 + count * 50 + y, 140, 30);
                                nearestParkBg.frame = CGRectMake(0, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:16];
                                nearestParkDistance.frame = CGRectMake(0, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(325, 850 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(360, 850 + count * 50 + y, 30, 30);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 850 + count * 50 + y, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(295, 850 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(330, 850 + count * 50 + y, 30, 30);
                            }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
                            {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 1050 + count * 50 + y, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 1050 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 1050 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(335, 1050 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(370, 1050 + count * 50 + y, 30, 30);
                            } else {
                                nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestPark.frame = CGRectMake(15, 850 + count * 50 + y, 150, 30);
                                nearestParkBg.frame = CGRectMake(0, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
                                nearestParkDistance.frame = CGRectMake(20, 850 + count * 50 + y, self.view.frame.size.width, 30);
                                addParkBtn.frame = CGRectMake(295, 850 + count * 50 + y, 30, 30);
                                viewParkBtn.frame = CGRectMake(330, 850 + count * 50 + y, 30, 30);
                            }
                            nearestPark.textAlignment = NSTextAlignmentLeft;
                            nearestParkDistance.textAlignment = NSTextAlignmentCenter;
                            nearestParkDistance.textContainerInset = UIEdgeInsetsMake(5, 0, 0, 5);
                            if(count % 2 == 0) {
                                nearestParkBg.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                            }
                            nearestParkDistance.backgroundColor = [UIColor clearColor];
                            nearestPark.text = object[@"Location"];
                            if([language containsString:@"fr"]) {
                                nearestParkDistance.text = [NSString stringWithFormat:@"%.2f km", [[collectedDistances objectAtIndex:i] floatValue]];
                            } else {
                                nearestParkDistance.text = [NSString stringWithFormat:@"%.2f miles", [[collectedDistances objectAtIndex:i] floatValue]];
                            }
                            
                            [addParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
                            [addParkBtn setImage:[UIImage imageNamed:@"btn_addhome"] forState:UIControlStateNormal];
                            [addParkBtn addTarget:self action:@selector(tapAddParkBtn:) forControlEvents:UIControlEventTouchUpInside];
                            [viewParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
                            [viewParkBtn setImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
                            [viewParkBtn addTarget:self action:@selector(tapViewParkBtn:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [pageScroller addSubview:nearestParkBg];
                            [pageScroller addSubview:nearestPark];
                            
                            [pageScroller addSubview:nearestParkDistance];
                            [pageScroller addSubview:addParkBtn];
                            [pageScroller addSubview:viewParkBtn];
                            count++;
                            
                            
                            
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + count * 51 + 450);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568){
                                pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + count * 51 + 450);
                            } else {
                                pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + count * 51 + 550);
                            }
                        }
                    } else {
                        // Log details of the failure
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                    }
                    [Hud removeFromSuperview];
                }];
            }
        }
    }
}

-(void)tapYesBtn {
    
    [UIView animateWithDuration:0.4f animations:^{
        [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 175)];
        homeParkView.alpha = 0;
    }];
    
    [PFUser currentUser][@"HomePark"] = requiredID;
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        [self loadParkUpdateAlert];
        
    }];
}

-(void)loadParkUpdateAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Update", nil):NSLocalizedString(@"You've successfully updated your home park!", nil)];
    [alertVC.alertView removeFromSuperview];
}

-(void)tapNoBtn {
    [UIView animateWithDuration:0.4f animations:^{
        [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 175)];
        homeParkView.alpha = 0;
    }];
}

- (IBAction)tapViewParkBtn:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
    [query whereKey:@"objectId" equalTo:tmp];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            PFGeoPoint *geoPoint = object[@"StartingPoint"];
            CLLocation *parkLocation = [[CLLocation alloc]init];
            [parkLocation initWithLatitude: geoPoint.latitude longitude:geoPoint.longitude];
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude)];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:object[@"Location"]];
            [mapItem openInMapsWithLaunchOptions:nil];
        } else {
            
        }
    }];
    
}

- (IBAction)tapViewMapBtn:(UIButton*)sender {
    [self showLoading];
    //NSLog(@"-----------------%d", [locationsObj count]);
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    NSMutableArray *mapItems = [NSMutableArray array];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;   // make it a serial queue
    
    NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
        [MKMapItem openMapsWithItems:mapItems launchOptions:nil];
        [Hud removeFromSuperview];
    }];
    
    for (PFObject *location in locationsObj) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            PFGeoPoint *geoPoint = location[@"StartingPoint"];
            CLLocation *parkLocation = [[CLLocation alloc]init];
            [parkLocation initWithLatitude: geoPoint.latitude longitude:geoPoint.longitude];
            [geocoder reverseGeocodeLocation: parkLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                if (error) {
                    NSLog(@"%@", error);
                } else if ([placemarks count] > 0) {
                    CLPlacemark *geocodedPlacemark = [placemarks objectAtIndex:0];
                    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:geocodedPlacemark.location.coordinate
                                                                   addressDictionary:geocodedPlacemark.addressDictionary];
                    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                    [mapItem setName:location[@"Location"]];
                    
                    [mapItems addObject:mapItem];
                }
                dispatch_semaphore_signal(semaphore);
            }];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }];
        
        [completionOperation addDependency:operation];
        [queue addOperation:operation];
        
    }
    [[NSOperationQueue mainQueue] addOperation:completionOperation];
    
}

-(IBAction)tapAddParkBtn:(UIButton*)sender {
    NSLocale *currentLocale = [NSLocale currentLocale];
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NSLog(@"%@", countryCode);
    if([countryCode containsString:@"AU"]) {
        pageScroller.scrollEnabled = YES;
        isFindingNearestParkOn = false;
        
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = YES;
        }
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             self.navigationController.navigationBar.alpha = 1;
             [showMapAus1 setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             self.navigationController.navigationBar.alpha = 1;
             [showMapAus1 setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
             [showMapAus1 removeFromSuperview];
         }];
    }
    NSString *tmp = sender.titleLabel.text;
    requiredID = tmp;
    NSLog(@"%@", requiredID);
    
    [self loadSelectParkAlert];
    
    
}

-(void)referFriendAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadTextLine:self:NSLocalizedString(@"User Referral", nil):NSLocalizedString(@"If a user invited you to join Proludic enter their username below!", nil)];
    [alertVC.alertView removeFromSuperview];
}

-(void)alertResponse:(NSString*)result:(NSString*)varText {
    NSString *tmp = [NSString stringWithFormat:@"Bool Result %@", result];
    NSLog(@"%@", tmp);
    
    NSLog(@"TODAY %@", varText);
    
    if([result isEqualToString:@"True"]) {
        
        [PFUser currentUser][@"HomePark"] = varText;
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded) {
                [self loadParkUpdateAlert];
            } else {
                NSLog(@"It fails to save");
            }
        }];
    }
}

-(void)readText:(NSString*)result:(NSString*)varText {
    NSString *tmp = [NSString stringWithFormat:@"Bool Result %@", result];
    NSLog(@"%@", tmp);
    
    NSLog(@"TODAY %@", varText);
    
    if([result isEqualToString:@"True"]) {
        
        if([result isEqualToString:@"True"]) {
            
            if ([varText isEqualToString:@""]) {
                
                UIAlertView *alert2 = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error!", nil)
                                                                message:NSLocalizedString(@"You need to add a name to submit a referral!", nil) delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil, nil];
                [alert2 show];
                
            }  else {
                
                PFQuery *userQuery = [PFUser query];
                [userQuery whereKey:@"username" equalTo:varText];
                [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userObject, NSError *error){
                    if(!error) {
                        PFQuery *query2 = [PFQuery queryWithClassName:@"UserReferral"];
                        [query2 whereKey:@"User" equalTo:userObject];
                        [query2 getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                            if(!error) {
                                object[@"User"] = userObject;
                                int tmp = [object[@"NumReferrals"] intValue] + 1;
                                object[@"NumReferrals"] = @(tmp);
                                [object addObject:[[PFUser currentUser] objectId] forKey:@"ReferralTo"];
                                
                                [object saveInBackground];
                            } else {
                                NSLog(@"------------ %@", [error description]);
                                if(error.code == 101) { // No existing object
                                    
                                    PFObject *object = [PFObject objectWithClassName:@"UserReferral"];
                                    object[@"User"] = userObject;
                                    object[@"NumReferrals"] = @(1);
                                    object[@"ReferralTo"] = [NSArray arrayWithObjects:[[PFUser currentUser] objectId],nil];
                                    
                                    [object saveInBackground];
                                    
                                }
                            }
                        }];
                        
                        [PFUser currentUser][@"notReferred"] = @NO;
                        [[PFUser currentUser] saveInBackground];
                    } else {
                        NSLog(@"%@", error.description);
                    }
                }];
            }
            
        }
    }
}

-(void)loadSelectParkAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadingVar:self:NSLocalizedString(@"Select Home Park", nil):NSLocalizedString(@"Are you sure you want to select this as your home park?", nil):requiredID];
    [alertVC.alertView removeFromSuperview];
}

#pragma mark - Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus)
    {
        case ReachableViaWWAN:
        {
            break;
        }
        case ReachableViaWiFi:
        {
            break;
        }
        case NotReachable:
        {
            //            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"We are unable to make a internet connection at this time. Some functionality will be limited until a connection is made." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            //            [alert show];
            
            //Loading Animation UIImageView
            
            //Custom Pop Up
            Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            Hud.mode = MBProgressHUDModeCustomView;
            Hud.labelText = NSLocalizedString(@"No internet connection found", nil);
            Hud.labelFont = [UIFont fontWithName:@"ArialMT" size:14];
            Hud.detailsLabelText = NSLocalizedString(@"Please connect to Wi-Fi or your mobile internet.", nil);
            Hud.detailsLabelFont = [UIFont fontWithName:@"ArialMT" size:14];
            
            //Create the first status image and the indicator view
            UIImage *statusImage = [UIImage imageNamed:@"WIFI"];
            activityImageView = [[UIImageView alloc]
                                 initWithImage:statusImage];
            
            
            //Position the activity image view somewhere in
            //the middle of your current view
            activityImageView.frame = CGRectMake(
                                                 self.view.frame.size.width/2
                                                 -25,
                                                 self.view.frame.size.height/2
                                                 -25,
                                                 60,
                                                 42);
            
            
            //Add your custom activity indicator to your current view
            //    [pageScroller addSubview:activityImageView];
            
            // Add stuff to view here
            Hud.customView = activityImageView;
            
            [Hud hide:YES afterDelay:5];
            
            break;
        }
    }
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    if (reachability == self.hostReachability)
    {
        
        NSLog(@"hostReachability");
    }
    
    if (reachability == self.internetReachability)
    {
        NSLog(@"internetReachability");
    }
    
    if (reachability == self.wifiReachability)
    {
        NSLog(@"wifiReachability");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
}

//- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
//    return UIBarPositionTopAttached;
//}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Prevent crashing undo bug – see note below.
    /*if(range.length + range.location > textField.text.length)
     {
     return NO;
     }
     
     NSUInteger newLength = [textField.text length] + [string length] - range.length;
     return newLength <= 10;*/
    if(textField == weightTextField || textField == heightTextField1)
    {
        NSCharacterSet* numberCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        for (int i = 0; i < [string length]; ++i)
        {
            unichar c = [string characterAtIndex:i];
            if (![numberCharSet characterIsMember:c])
            {
                return NO;
            }
        }
        return YES;
    } else {
        return YES;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 101) {
        if (buttonIndex == 0)
        {
            NSLog(@"cancel");
        }
        else
        {
            Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            Hud.mode = MBProgressHUDModeCustomView;
            Hud.labelText = @"Loading";
            Hud.customView = activityImageView;
            
            [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                if (succeeded && !error) {
                    
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Success!"
                                                                   message:@"Your username has been saved!" delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil, nil];
                    [alert show];
                    [Hud removeFromSuperview];
                    [self tapcloseButton];
                }
            }];
        }
    }
}

-(void)tapcloseButton{
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.navigationBarHidden = NO;
    
    [tmpView removeFromSuperview];
    
    [self loadParseContent];
    
}

#pragma mark - Daily Spin



#pragma mark - Keyboard Handling

//Shows the Keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

//Handles how the keyboard is shown
- (void)keyboardWasShown:(NSNotification *)notification
{
    /*if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     //Get the size of the keyboard.
     CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
     
     
     //Adjust the bottom content inset of the scroll view by the keyboard height.
     CGPoint point = CGPointMake(0.0, userTextField.frame.origin.y - (keyboardSize.height+50));
     CGRect frame = tmpView.frame;
     frame.origin = point;
     tmpView.frame = frame;
     
     
     }*/
    //Get the size of the keyboard.
    //CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //Adjust the bottom content inset of the scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    addInfoView.contentInset = contentInsets;
    addInfoView.scrollIndicatorInsets = contentInsets;
    
    int distanceMovedScroll;
    addInfoView.scrollEnabled = YES;
    if ([[UIScreen mainScreen] bounds].size.height == 480 || [[UIScreen mainScreen] bounds].size.height == 568)
    {
        distanceMovedScroll = keyboardSize.height - 100;
        
    } else {
        distanceMovedScroll = keyboardSize.height - 150;
    }
    //NSLog(@"---------%f------%f-------%f", self.view.frame.size.height,keyboardSize.height,lastTextField.frame.origin.y);
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        addInfoView.contentOffset = CGPointMake(0, distanceMovedScroll);
    } completion:NULL];
    
}

//Handles how to hide the keyboard
- (void) keyboardWillHide:(NSNotification *)notification {
    /*userTextField.text = [userTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
     userTextField.text = [userTextField.text lowercaseString];
     //    userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]] componentsJoinedByString:@""];
     userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
     
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     tmpView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
     
     }*/
    addInfoView.scrollEnabled = NO;
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    addInfoView.contentInset = contentInsets;
    addInfoView.scrollIndicatorInsets = contentInsets;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    
}

// Set activeTextField to the current active textfield

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    userTextField = textField;
    userTextField.text = [userTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    userTextField.text = [userTextField.text lowercaseString];
    userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

// Set activeTextField to nil

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    userTextField = textField;
    userTextField.text = [userTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    userTextField.text = [userTextField.text lowercaseString];
    userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
}


// Dismiss the keyboard

- (IBAction)dismissKeyboard:(id)sender
{
    [userTextField resignFirstResponder];
}

#pragma mark - Parse Methods


#pragma mark - Handling Achievement Pop Ups


#pragma mark - Handling touches

-(IBAction)tapNavButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSLog(@"Button: %ld", (long)[button tag]);
    
    NavBar *navBar = [[NavBar alloc] init];
    NSArray *arrayOfNavBarLinks = [navBar getControllerLinks];
    NSArray *arrayOfActiveViews = [navBar getActiveViewsPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfOffSetContents = [navBar getContentOffset:[[UIScreen mainScreen] bounds].size.height];
    NSInteger selectecItem = [button tag] - 1;
    
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Home"];
    
    if (selectecItem == anIndex) {
        //[sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
        
        UIButton *navBarButton = [sideScroller subviews][selectecItem];
        NSArray *arrayOfNavBarTitles = [navBar getTitles];
        //Add NavBar elements
        
        NSString *title = [[arrayOfNavBarTitles objectAtIndex:selectecItem] stringByAppendingString:@"_Active"];
        
        [navBarButton setBackgroundImage:[UIImage imageNamed:title] forState:UIControlStateNormal];
        
    } else {
        NSLog(@"%f", sideScroller.contentOffset.x);
        int sideScrollerOffSet = sideScroller.contentOffset.x;
        
        [defaults setInteger:sideScrollerOffSet forKey:@"sideScrollerOffSet"];
        
        [Flurry logEvent:@"User Pressed Navigation Bar Button" timed:YES];
        NSLog(@"%@",[arrayOfNavBarLinks objectAtIndex:selectecItem]);
        
    }
    
    SWRevealViewController *pageControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:[arrayOfNavBarLinks objectAtIndex:selectecItem]];
    
    [self.navigationController pushViewController:pageControl animated:NO];
    
}

- (void)setsideScrollerToPlace{
    
    NavBar *navBar = [[NavBar alloc] init];
    NSArray *arrayOfNavBarLinks = [navBar getControllerLinks];
    NSArray *arrayOfActiveViews = [navBar getActiveViewsPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfOffSetContents = [navBar getContentOffset:[[UIScreen mainScreen] bounds].size.height];
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Home"];
    
    [sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
    
    [defaults setInteger:[[arrayOfActiveViews objectAtIndex:anIndex] intValue] forKey:@"sideScrollerOffSet"];
}

-(void)tapChangeImage{
    
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Change profile", nil)
                                 message:NSLocalizedString(@"Upload your Profile Picture", nil)
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* camera = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Take Photo with Camera", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 //Do some thing here
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 NSLog(@"photo");
                                 
                                 [self tapPhotoButton];
                                 
                             }];
    UIAlertAction* gallery = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Upload from My Photos", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  //Do some thing here
                                  [view dismissViewControllerAnimated:YES completion:nil];
                                  
                                  NSLog(@"gallery");
                                  [self tapGalleryButton];
                                  
                              }];
    
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 NSLog(@"No");
                             }];
    
    
    [view addAction:camera];
    [view addAction:gallery];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}






#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"StartGameplay"])
    {
        
    } else if ([[segue identifier] isEqualToString:@"showEndOfGame"]){
        // Get reference to the destination view controller
        
    }
}

#pragma mark - Push Notification Observer

-(void)pushNotificationRefresh{
    if (!userIsOnOverlay) {
        if (refreshView == NO) {
            
            
            refreshView = YES;
            [self loadParseContent];
        }
    }
}

-(void)backgroundRefresh{
    if (viewHasFinishedLoading) {
        
        
        refreshView = YES;
        viewHasFinishedLoading = NO;
        [self loadParseContent];
    }
}

#pragma mark - Camera Handling

-(void)tapPhotoButton
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        libraryPicked = NO;
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        picker.allowsEditing = false;
        [self presentViewController:picker animated:true completion:nil];
    }
}

-(void)tapGalleryButton
{
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        libraryPicked = YES;
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        picker.allowsEditing = true;
        [self presentViewController:picker animated:true completion:nil];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.navigationController.navigationBar.alpha = 0;
    self.navigationController.navigationBarHidden = YES;
    
    selectedProfileImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    UIImageView *selectedPhoto = [[UIImageView alloc]init];
    
    selectedPhoto.image = selectedProfileImage;
    
    [self dismissViewControllerAnimated:true completion:nil];
    
    [popUpView removeFromSuperview];
    
    popUpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    UIImage *tmpImg = [UIImage imageNamed:@"overlay"];
    UIImageView *tmpImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    tmpImgView.image = tmpImg;
    tmpImgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:popUpView];
    [popUpView addSubview:tmpImgView];
    
    userIsOnOverlay = NO;
    
    //Close Button
    
    UIButton *xButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        xButton.frame = CGRectMake(5, 20, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        xButton.frame = CGRectMake(5, 20, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        xButton.frame = CGRectMake(5, 20, 40, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        xButton.frame = CGRectMake(5, 20, 40, 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        xButton.frame = CGRectMake(5, 20, 40, 40);
    } else {
        xButton.frame = CGRectMake(5, 20, 40, 40);
    }
    
    [xButton setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
    [xButton addTarget:self action:@selector(tapcloseProfilePicButton) forControlEvents:UIControlEventTouchUpInside];
    
    [tmpView addSubview:xButton];
    
    //Picture Overlay
    
    UIImageView *settingsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    settingsImageView.image = [UIImage imageNamed:@"alert_bg"];
    settingsImageView.contentMode = UIViewContentModeScaleAspectFit;
    settingsImageView.clipsToBounds = YES;
    settingsImageView.center = self.view.center;
    
    [popUpView addSubview:settingsImageView];
    
    //Title Label
    UILabel *titleLabel = [[UILabel alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:24];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 120, 135, 240, 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:24];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 120, 180, 240, 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 215, 320, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 240, 320, 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 240, 320, 40);
    } else {
        titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 240, 320, 40);
    }
    titleLabel.text = @"Edit Profile";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    [popUpView addSubview:titleLabel];
    
    //Cancel Button
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        cancelButton.frame = CGRectMake(24, 305, 90, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        cancelButton.frame = CGRectMake(24, 350, 90, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        cancelButton.frame = CGRectMake(34, 410, 103, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        cancelButton.frame = CGRectMake(34, 460, 111, 42);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        cancelButton.frame = CGRectMake(34, 460, 111, 42);
    } else {
        cancelButton.frame = CGRectMake(34, 460, 111, 42);
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"btn_cancel_french"] forState:UIControlStateNormal];
    } else {
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"btn_cancel"] forState:UIControlStateNormal];
    }
    [cancelButton addTarget:self action:@selector(tapcloseProfilePicButton) forControlEvents:UIControlEventTouchUpInside];
    
    [popUpView addSubview:cancelButton];
    
    //Retake Picture Button
    
    UIButton *retakePictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        retakePictureButton.frame = CGRectMake(116, 305, 90, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        retakePictureButton.frame = CGRectMake(116, 350, 90, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        retakePictureButton.frame = CGRectMake(138, 410, 103, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        retakePictureButton.frame = CGRectMake(153, 460, 111, 42);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        retakePictureButton.frame = CGRectMake(153, 460, 111, 42);
    } else {
        retakePictureButton.frame = CGRectMake(153, 460, 111, 42);
    }
    if([language containsString:@"fr"]) {
        [retakePictureButton setBackgroundImage:[UIImage imageNamed:@"btn_retake_french"] forState:UIControlStateNormal];
    } else {
        [retakePictureButton setBackgroundImage:[UIImage imageNamed:@"btn_retake"] forState:UIControlStateNormal];
    }
    if (libraryPicked) {
        [retakePictureButton addTarget:self action:@selector(tapGalleryButton) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [retakePictureButton addTarget:self action:@selector(tapPhotoButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    
    [popUpView addSubview:retakePictureButton];
    
    //Confirm Picture Button
    
    UIButton *confirmPictureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        confirmPictureButton.frame = CGRectMake(208, 305, 90, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        confirmPictureButton.frame = CGRectMake(208, 350, 90, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        confirmPictureButton.frame = CGRectMake(242, 410, 103, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        confirmPictureButton.frame = CGRectMake(272, 460, 111, 42);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        confirmPictureButton.frame = CGRectMake(272, 460, 111, 42);
    } else {
        confirmPictureButton.frame = CGRectMake(272, 460, 111, 42);
    }
    if([language containsString:@"fr"]) {
        [confirmPictureButton setBackgroundImage:[UIImage imageNamed:@"btn_confirm_french"] forState:UIControlStateNormal];
    } else {
        [confirmPictureButton setBackgroundImage:[UIImage imageNamed:@"btn_confirm"] forState:UIControlStateNormal];
    }
    [confirmPictureButton addTarget:self action:@selector(saveImageButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [popUpView addSubview:confirmPictureButton];
    
    //Selected photo
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 50, 180,  100, 100);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 50, 223,  100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 60, 263,  120, 120);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 70, 290,  140, 140);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 70, 290,  140, 140);
    } else {
        selectedPhoto.frame = CGRectMake((self.view.frame.size.width /2) - 70, 290,  140, 140);
    }
    
    CALayer *imageLayer = selectedPhoto.layer;
    [imageLayer setCornerRadius:5];
    [imageLayer setBorderWidth:1];
    [imageLayer setMasksToBounds:YES];
    [selectedPhoto.layer setCornerRadius:selectedPhoto.frame.size.width/2];
    selectedPhoto.layer.borderWidth = 3.0f;
    selectedPhoto.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [popUpView addSubview:selectedPhoto];
}

- (IBAction)saveImageButton:(id)sender {
    
    
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = @"Loading";
    Hud.customView = activityImageView;
    
    NSData *imageData = UIImageJPEGRepresentation(selectedProfileImage, 0.0);
    UIImage *compressedJPGImage = [UIImage imageWithData:imageData];
    
    NSData* data = UIImageJPEGRepresentation(compressedJPGImage,0.0);
    imageData = UIImageJPEGRepresentation(compressedJPGImage,0.0);
    
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@.jpg",[[PFUser currentUser] username]] data:data];
    [[PFUser currentUser] setObject:imageFile forKey:@"uploadedProfilePicture"];
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Picture Changed!");
            
            PFFile *imageFile = [PFUser currentUser][@"uploadedProfilePicture"];
            
            [PFUser currentUser][@"profilePicture"] = imageFile.url;
            
            [[PFUser currentUser]saveInBackground];
            
            self.navigationController.navigationBar.alpha = 1;
            
            self.navigationController.navigationBarHidden = NO;
            [popUpView removeFromSuperview];
            
            profilePicture.image = [UIImage imageWithData:data];
            
            userIsOnOverlay = NO;
            
            [Hud removeFromSuperview];
        } else {
            NSLog(@"%@",error.description);
            
            self.navigationController.navigationBar.alpha = 1;
            
            self.navigationController.navigationBarHidden = NO;
            [popUpView removeFromSuperview];
            
            [Hud removeFromSuperview];
        }
    }];
    
}

-(void)tapcloseProfilePicButton{
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.navigationBarHidden = NO;
    userIsOnOverlay = NO;
    
    [popUpView removeFromSuperview];
}
-(void) viewWillAppear:(BOOL)animated {
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
}
-(void) setupAddInfoGrid {
    //BackgroundImage
    UIImageView *background = [[UIImageView alloc] init];
    background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    background.image = [UIImage imageNamed:@"BG"];
    [addInfoView addSubview:background];
    
    //Icon Background
    
    UIImageView *iconBackground = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        iconBackground.frame = CGRectMake(30, 10, self.view.frame.size.width-60, 220);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        iconBackground.frame = CGRectMake(30, 25 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    }
    iconBackground.image = [UIImage imageNamed:@"ProludicLogo.jpg"];
    iconBackground.contentMode = UIViewContentModeScaleAspectFit;
    iconBackground.clipsToBounds = YES;
    [addInfoView addSubview:iconBackground];
    
    UILabel *addProfileLabel = [[UILabel alloc]init];
    addProfileLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:10];
        addProfileLabel.frame = CGRectMake(0, 220, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:10];
        addProfileLabel.frame = CGRectMake(0, 220, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        addProfileLabel.frame = CGRectMake(0, 270, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(0, 270, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(0, 270, self.view.frame.size.width, 20);
    } else {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(0, 270, self.view.frame.size.width, 20);
    }
    addProfileLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Personal Information", nil)];
    
    addProfileLabel.textAlignment = NSTextAlignmentCenter;
    [addInfoView addSubview:addProfileLabel];
    
    UIImageView *profileImage = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 50, 250, 100, 100);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 50, 250, 100, 100);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 60, 310, 120, 120);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 60, 310, 120, 120);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 60, 310, 120, 120);//Position of the butto
    } else {
        profileImage.frame = CGRectMake(self.view.frame.size.width*0.5 - 60, 310, 120, 120);//Position of the butto
    }
    if([PFUser currentUser][@"profilePicture"] == nil) {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[PFUser currentUser][@"facebookID"]]]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                profileImage.image =  [UIImage imageWithData:data];
            });
        });
    } else {
        NSString *imageUrl = [PFUser currentUser][@"profilePicture"];
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                profileImage.image =  [UIImage imageWithData:data];
                
            });
        });
    }
    [addInfoView addSubview:profileImage];
    
    
    heightTextField1 = [ [UITextField alloc ] init];
    UILabel *heightLabel1 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heightTextField1.frame = CGRectMake(40, 370, self.view.frame.size.width/4, 25); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 50, 376, 40, 25);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heightTextField1.frame = CGRectMake(40, 390, self.view.frame.size.width/4, 28); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 50, 396, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heightTextField1.frame = CGRectMake(50, 470, self.view.frame.size.width/4, 33); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 50, 476, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heightTextField1.frame = CGRectMake(70, 470, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 70, 476, 40, 25);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heightTextField1.frame = CGRectMake(70, 470, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 70, 476, 40, 25);
    } else {
        heightTextField1.frame = CGRectMake(70, 470, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*0.25 + 70, 476, 40, 25);
    }
    heightLabel1.text = NSLocalizedString(@"CM", nil);
    [addInfoView addSubview:heightLabel1];
    heightTextField1.textAlignment = NSTextAlignmentLeft;
    heightTextField1.textColor = [UIColor blackColor];
    heightTextField1.backgroundColor = [UIColor whiteColor];
    CALayer *borderName2 = [CALayer layer];
    CGFloat borderWidthName2 = 1;
    borderName2.borderColor = [UIColor darkGrayColor].CGColor;
    borderName2.frame = CGRectMake(0,  heightTextField1.frame.size.height - borderWidthName2,  heightTextField1.frame.size.width,  heightTextField1.frame.size.height);
    borderName2.borderWidth = borderWidthName2;
    [heightTextField1.layer addSublayer:borderName2];
    heightTextField1.clearButtonMode = UITextFieldViewModeWhileEditing;
    heightTextField1.returnKeyType = UIReturnKeyDone;
    
    if ([heightTextField1 respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        heightTextField1.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"HEIGHT", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"Bebas Neue" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    heightTextField1.keyboardType = UIKeyboardAppearanceDark;
    heightTextField1.autocapitalizationType = UITextAutocapitalizationTypeWords;
    heightTextField1.clipsToBounds = YES;
    [heightTextField1 setDelegate:self];
    heightTextField1.font = [UIFont fontWithName:@"Bebas Neue" size:14.0];
    [addInfoView addSubview:heightTextField1];
    
    weightTextField = [ [UITextField alloc ] init];
    UILabel *weightLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 15, 370, self.view.frame.size.width/4, 25);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 25, 376, 40, 25);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 15, 390, self.view.frame.size.width/4, 28);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 25, 396, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 30, 470, self.view.frame.size.width/4, 33); //Position of the Textfield
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 30, 476, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 30, 470, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 30, 476, 40, 25);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 30, 470, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 30, 476, 40, 25);
    } else {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*0.5 + 30, 470, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*0.75 + 30, 476, 40, 25);
    }
    weightLabel.text = NSLocalizedString(@"kg", nil);
    [addInfoView addSubview:weightLabel];
    weightTextField.textAlignment = NSTextAlignmentLeft;
    weightTextField.textColor = [UIColor blackColor];
    weightTextField.backgroundColor = [UIColor whiteColor];
    CALayer *borderuName = [CALayer layer];
    CGFloat borderWidthuName = 1;
    borderuName.borderColor = [UIColor darkGrayColor].CGColor;
    borderuName.frame = CGRectMake(0,  weightTextField.frame.size.height - borderWidthuName,  weightTextField.frame.size.width,  weightTextField.frame.size.height);
    borderuName.borderWidth = borderWidthuName;
    [weightTextField.layer addSublayer:borderuName];
    weightTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    weightTextField.returnKeyType = UIReturnKeyDone;
    
    if ([weightTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        weightTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Weight", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"Bebas Neue" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    weightTextField.keyboardType = UIKeyboardAppearanceDark;
    weightTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    weightTextField.clipsToBounds = YES;
    [weightTextField setDelegate:self];
    weightTextField.font = [UIFont fontWithName:@"Bebas Neue" size:14.0];
    [addInfoView addSubview:weightTextField];
    
    UIButton *submitButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        submitButton1.frame = CGRectMake(40, self.view.frame.size.height-60, self.view.frame.size.width-80, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        submitButton1.frame = CGRectMake(40, self.view.frame.size.height-100, self.view.frame.size.width-80, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        submitButton1.frame = CGRectMake(50, self.view.frame.size.height-80, self.view.frame.size.width-100, 40);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        submitButton1.frame = CGRectMake(70, self.view.frame.size.height-150, self.view.frame.size.width-140, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        submitButton1.frame = CGRectMake(70, self.view.frame.size.height-150, self.view.frame.size.width-140, 40);//Position of the button
    } else {
        submitButton1.frame = CGRectMake(70, self.view.frame.size.height-150, self.view.frame.size.width-140, 40);//Position of the button
    }
    [submitButton1 setBackgroundImage:[UIImage imageNamed:@"Reg_email_btn"] forState:UIControlStateNormal];
    [submitButton1 addTarget:self action:@selector(tapButtonAddInfo) forControlEvents:UIControlEventTouchUpInside];
    //submitButton1.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [addInfoView addSubview:submitButton1];
    
    
    
}
-(void) tapButtonAddInfo{
    NSLog(@"TEST");
    if ([heightTextField1.text isEqualToString:@""] || [weightTextField.text isEqualToString:@""]) {
        
        /*alertVC = [[CustomAlert alloc] init];
         [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"All fields must be completed!", nil)];
         [alertVC.alertView removeFromSuperview];*/
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!" message:@"All fields must be completed!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        NSLog(@"Clicked submit button");
    } else {
        
        [self showLoading];
        static dispatch_once_t onceToken;
        //all yours mate, chang was just adding his code on factory view
        dispatch_once (&onceToken, ^{
            
            //CHECKS CURRENT LOCATION
            if([[[PFUser currentUser] objectForKey:@"HomePark"] isEqualToString:@"NotSelected"]) {
                [self autoFindNearestPark:nil];
            } else {
                [self autoFindNearestPark:nil];
            }
            [Hud removeFromSuperview];
            
        });
        [PFUser currentUser][@"height"] = [NSString stringWithFormat:@"%@ CMs",heightTextField1.text];
        [PFUser currentUser][@"bodyWeight"] = [NSString stringWithFormat:@"%@ kg", weightTextField.text];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            if(success) {
            }
            [Hud removeFromSuperview];
        }];
        pageScroller.scrollEnabled = YES;
        
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = YES;
        }
        
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             self.navigationController.navigationBar.alpha = 1;
             [addInfoView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             self.navigationController.navigationBar.alpha = 1;
             [addInfoView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
             [addInfoView removeFromSuperview];
         }];
    }
}

- (NSMutableArray*) datesOfWeekFromDate:(NSDate *)date {
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comps = [calendar components:NSYearForWeekOfYearCalendarUnit |NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:date];
    int day = [comps weekday];
    for (int i = 2; i <= day; i++) { // 2: Monday
        [comps setWeekday:i];
        NSString *dateString = [formatter stringFromDate:[calendar dateFromComponents:comps]];
        [dates addObject:dateString];
    }
    return dates;
}

#pragma mark Get Users Emails
-(void)getAllEmails{
    //    PFQuery *query = [PFUser query];
    //    [query whereKeyExists:@"email"];
    //    [query orderByAscending:@"email"];
    //    [query setLimit:1000];
    //    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    //        NSLog(@"Number of Users: %lu",(unsigned long)objects.count);
    //
    //        if(error){
    //            NSLog(@"Error!");
    //        }
    //        else {
    //            if (objects.count == 0) {
    //                NSLog(@"No Users found!");
    //
    //            }
    //            else {
    //                NSMutableArray *names = [[NSMutableArray alloc]init];
    //                NSMutableArray *emails = [[NSMutableArray alloc]init];
    //
    //                for (PFUser *theUser in objects) {
    //                    [emails addObject:theUser.email];
    //                    [names addObject:theUser[@"name"]];
    //                }
    //                NSLog(@"%@",names);
    //                NSLog(@"%@",emails);
    //
    //                NSLog(@"Finished");
    //            }
    //        }
    //    }];
}
@end
