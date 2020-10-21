//
//  ExercisesViewController.m
//  Proludic
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ExercisesViewController.h"
#import <HealthKit/HealthKit.h>
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"
#import "BrowseAllDetailController.h"
#import "StopwatchViewController.h"
#import "CustomAlert.h"

@interface ExercisesViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation ExercisesViewController{
    UIView *tmpView;
    UIView *popUpView;
    UIView *noDataView;
    UIView *timerBar;
    UIView *floatView;
    UIScrollView *sideScroller;
    UIScrollView *pageScroller;
    UIScrollView *pageScroller2;
    NSUserDefaults *defaults;
    NSMutableArray *exerciseArray;
    NSMutableArray *workoutStoreArray;
    
    int iteration;
    bool refreshView;
    bool userIsOnOverlay;
    bool libraryPicked;
    bool viewHasFinishedLoading;
    bool isFindingNearestParkOn;
    int distanceMovedScroll;
    
    IBOutlet UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    
    
    //PFObjects for searching
    NSArray *collectedExercises;
    //AnimationImage
    UIImageView *glowImageView;
    
    UIButton *view1;
    UIButton *view2;
    UIButton *view3;
    
    BOOL *isExercisesPage;
    
    //Find Parks
    UIButton *findParksButton;
    CLLocationManager *locationManager;
    NSMutableArray *locationsObj;
    
    //OneTouch
    NSArray *exercises;
    UIView *startWorkout;
    NSString *workoutNameString;
    NSString *easyMedHard;
    NSString *activeDesc;
    NSString *endTime;
    int timeEstimate;
    int oneTouchTotalExercises;
    int oneTouchExerciseCount;
    
    AVAudioPlayer *audioPlayer;
    
    CustomAlert *alertVC;
    
    UIView *homeParkView;
    NSString *currentLocationID;
    
    BOOL *isHomePark;
    
}
@synthesize searchBar;
@synthesize searchBarController;
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    userIsOnOverlay = NO;
    viewHasFinishedLoading = NO;
    // Do any additional setup after loading the view.
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [Flurry logEvent:@"User Opened Dashboard Page" timed:YES];
    
    [[DBManager getSharedInstance]createDB];
    //Sounds
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];
    
    self.navigationController.navigationBarHidden = NO;
    
    UIImageView *navigationImage=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 35)];
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
    isHomePark = YES;
    
    // Build your regular UIBarButtonItem with Custom View
    UIImage *image = [UIImage imageNamed:@"hamburger2"];
    UIButton *leftBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBarButton.frame = CGRectMake(0,10, 22, 15);
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resigningActive) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
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
    
    sideScroller.contentSize = CGSizeMake(self.view.frame.size.width, 50);
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
    [sideScroller setShowsHorizontalScrollIndicator:NO];
    [sideScroller setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:sideScroller];
    
    
    
    NSLog(@"%ld",(long)[defaults integerForKey:@"sideScrollerOffSet"]);
    
    
    //Get the array of Nav bar objects
    
    NSArray *arrayOfNavBarTitles = [navBar getTitles];
    NSArray *arrayOfXPositions = [navBar getXPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfButtonWidths = [navBar getButtonWidth:[[UIScreen mainScreen] bounds].size.height];
    
    //Add NavBar elements
    
    for (int i = 0; i < arrayOfNavBarTitles.count; i++) {
        NSString *title = [arrayOfNavBarTitles objectAtIndex:i];
        if (i == 1) { // Exercises
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
    
    [self loadParseContent];
}

-(void)loadParseContent{
    // Create the UI Scroll View
    
    [pageScroller removeFromSuperview];
    [Hud removeFromSuperview];
    
    pageScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.frame = CGRectMake(0, 92, self.view.frame.size.width, self.view.frame.size.height-46); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 93, self.view.frame.size.width, self.view.frame.size.height-46); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0,94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 194, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        pageScroller.frame = CGRectMake(0, 194, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    } else {
        pageScroller.frame = CGRectMake(0, 194, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    pageScroller.bounces = NO;
    [pageScroller setShowsVerticalScrollIndicator:NO];
    //[pageScroller setPagingEnabled : YES];
    [self.view addSubview:pageScroller];
    
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = NSLocalizedString(@"Loading", nil);
    
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
    [self loadUser];
}

-(void)loadUser{
    UIButton *exercisesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else {
        exercisesBtn.frame = CGRectMake(10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [exercisesBtn setBackgroundImage:[UIImage imageNamed:@"btn_exercises_french"] forState:UIControlStateNormal];
    } else {
        [exercisesBtn setBackgroundImage:[UIImage imageNamed:@"btn_newexercises"] forState:UIControlStateNormal];
    }
    [exercisesBtn addTarget:self action:@selector(exerciseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [pageScroller addSubview:exercisesBtn];
    
    UIButton *workoutsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else {
        workoutsBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, 60, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    }
    if([language containsString:@"fr"]) {
        [workoutsBtn setBackgroundImage:[UIImage imageNamed:@"btn_workouts_french-1"] forState:UIControlStateNormal];
    } else {
        [workoutsBtn setBackgroundImage:[UIImage imageNamed:@"btn_newworkouts"] forState:UIControlStateNormal];
    }
    [workoutsBtn addTarget:self action:@selector(workoutButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [pageScroller addSubview:workoutsBtn];
    
    UIButton *touchWorkoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else {
        touchWorkoutBtn.frame = CGRectMake(10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    }
    if([language containsString:@"fr"]) {
        [touchWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_onetouch_french"] forState:UIControlStateNormal];
    } else {
        [touchWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_newtouch"] forState:UIControlStateNormal];
    }
    [touchWorkoutBtn addTarget:self action:@selector(oneTouchWorkoutClicked) forControlEvents:UIControlEventTouchUpInside];
    [pageScroller addSubview:touchWorkoutBtn];
    
    UIButton *newWorkoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    } else {
        newWorkoutBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 10, (self.view.frame.size.width / 2) + 50, (self.view.frame.size.width / 2) - 20, (self.view.frame.size.width / 2) - 40);
    }
    if([language containsString:@"fr"]) {
        [newWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_create_french"] forState:UIControlStateNormal];
    } else {
        [newWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_newcreate"] forState:UIControlStateNormal];
    }
    [newWorkoutBtn addTarget:self action:@selector(addWorkout) forControlEvents:UIControlEventTouchUpInside];
    [pageScroller addSubview:newWorkoutBtn];
    
    //Stop the animation, sometimes called inside the query background function.
    [Hud removeFromSuperview];
    
}

-(void)addWorkout {
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
    [query whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            
            workoutStoreArray = [[NSMutableArray alloc] init];
            
            exerciseArray = [[NSMutableArray alloc] init];
            [exerciseArray addObject:object[@"ExerciseIds"]];
            NSLog(@"Location Park Query: %@", exerciseArray);
            NSLog(@"Location Park Query2: %@", object[@"ExerciseIds"]);
            
            
            //QUERY FOR GETTING ALL EXERCISES
            PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"Exercises"];
            if([[PFUser currentUser][@"isFrench"] isEqual:@YES]) {
                [browseAllQuery whereKey:@"isFrench" equalTo:@YES];
            }
            [browseAllQuery whereKey:@"objectId" containedIn:object[@"ExerciseIds"]];
            [browseAllQuery orderByAscending:@"ExerciseName"];
            [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    collectedExercises = objects;
                    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                    {
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 90 - 200);    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                    {
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 50);
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                    {
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 200);
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                    {
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 200);
                    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                    {
                        pageScroller.frame = CGRectMake(0, 140, self.view.frame.size.width, self.view.frame.size.height+50);
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 200);
                    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
                        pageScroller.frame = CGRectMake(0, 140, self.view.frame.size.width, self.view.frame.size.height+50);
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 200);
                    } else {
                        pageScroller.frame = CGRectMake(0, 140, self.view.frame.size.width, self.view.frame.size.height+50);
                        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + collectedExercises.count * 85 - 200);
                    }
                    
                    int exerciseCount = 0;
                    
                    UILabel *title = [[UILabel alloc] init];
                    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                    {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:12];
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                    {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:12];
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                    {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    }
                    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                    {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                    {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    } else {
                        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
                        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    }
                    title.textColor = [UIColor blackColor];
                    title.numberOfLines = 1;
                    title.text = NSLocalizedString(@"Create New Workout", nil);
                    title.textAlignment = NSTextAlignmentCenter;
                    [pageScroller addSubview:title];
                    
                    for(PFObject *exercise in objects) {
                        UIView *exerciseView = [[UIView alloc] init];
                        exerciseView.frame = CGRectMake(0, 100 * exerciseCount + 80, self.view.frame.size.width, 80);
                        [exerciseView setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
                        [pageScroller addSubview:exerciseView];
                        
                        //Exercise Bar Label
                        UILabel *title;
                        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                        {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 200, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
                        }
                        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                        {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 200, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
                        }
                        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                        {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, 220, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                        }
                        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                        {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 220, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                        {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 220, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                        } else {
                            title = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 220, 60)];
                            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
                        }
                        title.textColor = [UIColor blackColor];
                        title.numberOfLines = 2;
                        title.textAlignment = NSTextAlignmentLeft;
                        if([exercise objectForKey:@"ExerciseName"] != nil) {
                            title.text = [exercise objectForKey:@"ExerciseName"];
                        } else {
                            title.text = [exercise objectForKey:@"WorkoutName"];
                        }
                        [exerciseView addSubview:title];
                        
                        UIButton *addToWorkout = [[UIButton alloc] init];
                        [addToWorkout setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:150.0f/255.0f blue:100.0f/255.0f alpha:1.0]];
                        addToWorkout.frame = CGRectMake(self.view.frame.size.width - 80, 0, 80, 80);
                        [addToWorkout setTitle:[exercise objectId] forState:UIControlStateNormal];
                        addToWorkout.titleLabel.layer.opacity = 0.0f;
                        [addToWorkout addTarget:self action:@selector(addExerciseToWorkout:) forControlEvents:UIControlEventTouchUpInside];
                        [exerciseView addSubview:addToWorkout];
                        
                        UIImageView *plusIC = [[UIImageView alloc] init];
                        plusIC.image = [UIImage imageNamed:@"ic_plus"];
                        plusIC.frame = CGRectMake(self.view.frame.size.width - 60, 20, 40, 40);
                        [exerciseView addSubview:plusIC];
                        
                        exerciseCount++;
                    }
                    
                    UIButton *addWorkoutBtn = [[UIButton alloc] init];
                    addWorkoutBtn.frame = CGRectMake(0, self.view.frame.size.height - 40, self.view.frame.size.width, 40);
                    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                    if([language containsString:@"fr"]) {
                        [addWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_finish_french"] forState:UIControlStateNormal];
                    } else {
                        [addWorkoutBtn setBackgroundImage:[UIImage imageNamed:@"btn_finish_workout"] forState:UIControlStateNormal];
                    }
                    [addWorkoutBtn addTarget:self action:@selector(finishUserWorkout) forControlEvents:UIControlEventTouchUpInside];
                    [self.view addSubview:addWorkoutBtn];
                    
                } else {
                    [Hud removeFromSuperview];
                }
            }];
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(IBAction)addExerciseToWorkout:(UIButton*)sender {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Update", nil):NSLocalizedString(@"Exercise added to workout!", nil)];
    [alertVC.alertView removeFromSuperview];
    
    NSString *tmp = sender.titleLabel.text;
    [workoutStoreArray addObject:tmp];
    NSLog(@"%@", workoutStoreArray);
    NSLog(@"ADD TO WORKOUT");
}

-(void)finishUserWorkout {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Name the Workout", nil)
                                                                   message:NSLocalizedString(@"Write a suitable name for the new workout!", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Submit Workout", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *postReply = alert.textFields[0].text;
                                                              
                                                              if ([postReply isEqualToString:@""]) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to add a name to the workout!", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              }  else {
                                                                  
                                                                  PFObject *obj = [PFObject objectWithClassName:@"PresetWorkouts"];
                                                                  obj[@"WorkoutName"] = postReply;
                                                                  obj[@"ExerciseIds"] = workoutStoreArray;
                                                                  [obj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                      if(!error) {
                                                                          NSLog(@"Saved to Workouts!");
                                                                          PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
                                                                          [query whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
                                                                          [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                                                              if(!error) {
                                                                                  NSLog(@"THIS IS IMPORTANT: %@", [obj objectId]);
                                                                                  [object addObject:[obj objectId] forKey:@"WorkoutIds"];
                                                                                  [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                                                                      if(succeeded) {
                                                                                          [self resetloadUser];
                                                                                          
                                                                                          alertVC = [[CustomAlert alloc] init];
                                                                                          [alertVC loadSingle:self.view:NSLocalizedString(@"Update", nil):NSLocalizedString(@"You've created a new workout!", nil)];
                                                                                          [alertVC.alertView removeFromSuperview];
                                                                                          
                                                                                      } else {
                                                                                          NSLog(@"FAILED");
                                                                                      }
                                                                                  }];
                                                                              } else {
                                                                                  NSLog(@"Error:%@", error.description);
                                                                              }
                                                                          }];
                                                                      } else {
                                                                          NSLog(@"Error:%@", error.description);
                                                                      }
                                                                  }];
                                                                  
                                                              }
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Name of Workout...", nil);
    }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)resetloadUser {
    for(UIView *subview in [self.view subviews]) {
        [subview removeFromSuperview];
    }
    
    [self viewDidLoad];
}

-(void)oneTouchWorkoutClicked {
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    
    [self showLoading];
    isExercisesPage = FALSE;
    
    PFQuery *parkWorkoutQuery = [PFQuery queryWithClassName:@"Locations"];
    [parkWorkoutQuery whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
    [parkWorkoutQuery getFirstObjectInBackgroundWithBlock:^(PFObject *obj, NSError *error) {
        if(!error) {
            NSLog(@"Location Park Query2: %@", obj[@"WorkoutIds"]);
            //QUERY FOR GETTING ALL EXERCISES
            PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"PresetWorkouts"];
            [browseAllQuery orderByAscending:@"WorkoutName"];
            [browseAllQuery whereKey:@"objectId" containedIn:obj[@"WorkoutIds"]];
            [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
             {
                 if (!error) {
                     collectedExercises = objects;
                     [self setOneTouchWorkoutGrid:objects : [PFUser currentUser][@"FavouriteWorkouts"]: nil];
                 } else {
                     [Hud removeFromSuperview];
                 }
             }];
        } else {
            [Hud removeFromSuperview];
            noDataView = [[UIView alloc] init];
            noDataView.frame = CGRectMake(0, 130, self.view.frame.size.width, self.view.frame.size.height);
            
            [self.view addSubview:noDataView];
            
            UILabel *homeParkLabel = [[UILabel alloc] init];
            homeParkLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 200);
            homeParkLabel.text = NSLocalizedString(@"You need to select a home park below to find workouts!", nil);
            homeParkLabel.textAlignment = NSTextAlignmentCenter;
            homeParkLabel.numberOfLines = 5;
            homeParkLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            
            [noDataView addSubview:homeParkLabel];
            
            if([[PFUser currentUser][@"HomePark"]  isEqual: @"NotSelected"]) {
                //Add Home Park
                UIButton *addHomeParkButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                }
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if([language containsString:@"fr"]) {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choosepark_french"] forState:UIControlStateNormal];
                } else {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choose"] forState:UIControlStateNormal];
                }
                [addHomeParkButton addTarget:self action:@selector(addHomePark:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:addHomeParkButton];
                
            } else {
                // Find nearest Park
                isFindingNearestParkOn = false;
                findParksButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                }
                [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_2"] forState:UIControlStateNormal];
                [findParksButton addTarget:self action:@selector(tapfindNearestParksButton:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:findParksButton];
                
            }
            
            [Hud removeFromSuperview];
            NSLog(@"Location Park Query Failed");
        }
        
    }];
    
}

-(void)setOneTouchWorkoutGrid:(NSArray*) objects :(NSArray*) favouriteID: (NSArray*) mostUsedList {
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 90 - 200);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    } else {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    }
    
    UILabel *title = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:12];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:12];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
    } else {
        title = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width - 20, 60)];
        title.font = [UIFont fontWithName:@"ethnocentric" size:14];
    }
    title.textColor = [UIColor blackColor];
    title.numberOfLines = 1;
    title.text = NSLocalizedString(@"One Touch Workouts", nil);
    title.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:title];
    
    int count = 0;
    for (PFObject *object in objects) {
        UIButton *exerciseBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        } else {
            [exerciseBtn setFrame:CGRectMake(0, 90 + count*90, self.view.frame.size.width, 80)];
        }
        [exerciseBtn setTitle:[object objectId] forState:UIControlStateNormal];
        exerciseBtn.titleLabel.layer.opacity = 0.0f;
        [exerciseBtn addTarget:self action:@selector(clickOneTouchWorkout:) forControlEvents:UIControlEventTouchUpInside];
        [exerciseBtn setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
        [pageScroller addSubview:exerciseBtn];
        
        //Exercise Bar Label
        UILabel *title;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 98 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 98 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(80, 98 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 98 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 98 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 98 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        
        title.textColor = [UIColor blackColor];
        title.numberOfLines = 2;
        title.textAlignment = NSTextAlignmentCenter;
        if([object objectForKey:@"ExerciseName"] != nil) {
            title.text = [object objectForKey:@"ExerciseName"];
        } else {
            title.text = [object objectForKey:@"WorkoutName"];
        }
        [pageScroller addSubview:title];
        
        //Exercise Bar Button Star
        
        UIButton *starBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [starBtn setFrame:CGRectMake(self.view.frame.size.width - 50, 120 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [starBtn setFrame:CGRectMake(self.view.frame.size.width - 50, 120 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [starBtn setFrame:CGRectMake(320, 120 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [starBtn setFrame:CGRectMake(320, 120 + count*90, 20, 20)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [starBtn setFrame:CGRectMake(320, 120 + count*90, 20, 20)];
        } else {
            [starBtn setFrame:CGRectMake(320, 120 + count*90, 20, 20)];
        }
        
        if (isExercisesPage) {
            [starBtn setTitle:[object objectId] forState:UIControlStateNormal];
            if ([favouriteID count] == 0 || ![favouriteID containsObject:[object objectId]]) {
                [starBtn setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(starButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [starBtn setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(starButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            }
        } else {
            [starBtn setTitle:[object objectId] forState:UIControlStateNormal];
            if ([favouriteID count] == 0 || ![favouriteID containsObject:[object objectId]]) {
                [starBtn setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(workoutStarButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [starBtn setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(workoutStarButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        [pageScroller addSubview:starBtn];
        
        if(mostUsedList != nil) {
            UILabel *numRepeat;
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 107, 100 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 107, 95 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 115, 100 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 100 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 100 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            } else {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 100 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            }
            
            numRepeat.textColor = [UIColor blackColor];
            numRepeat.numberOfLines = 2;
            //numRepeat.backgroundColor = [UIColor yellowColor];
            numRepeat.textAlignment = NSTextAlignmentRight;
            numRepeat.text = [NSString stringWithFormat:@"%d",[[mostUsedList objectAtIndex:count] intValue]];
            [pageScroller addSubview:numRepeat];
            
            UIImageView *repImg= [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35, 124 + count*90, 40, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35, 124 + count*90, 40, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30, 124 + count*90, 15, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 124 + count*90, 40, 15)];
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 124 + count*90, 40, 15)];
            } else {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 124 + count*90, 40, 15)];
            }
            repImg.image = [UIImage imageNamed:@"ic_reps"];
            repImg.contentMode = UIViewContentModeScaleAspectFit;
            repImg.clipsToBounds = YES;
            [pageScroller addSubview:repImg];
        }
        
        //Image Thumbnail
        UIImageView *brandedImg = [[UIImageView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
        } else {
            brandedImg.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
        }
        CALayer *imageLayer = brandedImg.layer;
        [imageLayer setCornerRadius:5];
        [imageLayer setBorderWidth:1];
        [brandedImg.layer setCornerRadius:brandedImg.frame.size.width/2];
        [imageLayer setMasksToBounds:YES];
        brandedImg.layer.borderWidth = 2.0f;
        brandedImg.layer.borderColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0].CGColor;
        
        if ([object objectForKey:@"BrandImage"] != nil) {
            NSLog(@"BRANDED WORKERT");
            PFFile *imageFile = [object objectForKey:@"BrandImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    brandedImg.image = [UIImage imageWithData:data];
                    
                    [pageScroller addSubview:brandedImg];
                });
            });
            
            UIButton *hoverBtn = [[UIButton alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            } else {
                hoverBtn.frame = CGRectMake(25, 115 + count*85, 50, 50); //Image scaled
            }
            [hoverBtn setTitle:[object objectId] forState:UIControlStateNormal];
            hoverBtn.titleLabel.layer.opacity = 0.0f;
            [hoverBtn addTarget:self action:@selector(btnBrandedWorkout:) forControlEvents:UIControlEventTouchUpInside];
            [pageScroller addSubview:hoverBtn];
            
        } else if ([object objectForKey:@"WorkoutName"] != nil){
            //Exercise Bar Arrows Image
            UIImageView *arrowImage = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                arrowImage.frame = CGRectMake(25, 115 + count*90, 35, 35);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                arrowImage.frame = CGRectMake(25, 115 + count*90, 35, 35);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                arrowImage.frame = CGRectMake(25, 110 + count*90, 41, 41);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                arrowImage.frame = CGRectMake(30, 110 + count*90, 41, 41);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                arrowImage.frame = CGRectMake(30, 110 + count*90, 41, 41);
            } else {
                arrowImage.frame = CGRectMake(30, 110 + count*90, 41, 41);
            }
            arrowImage.image = [UIImage imageNamed:@"arrows"];
            [pageScroller addSubview:arrowImage];
            
        } else {
            //Exercise Bar Arrows Image
            UIImageView *arrowImage = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            } else {
                arrowImage.frame = CGRectMake(15, 100 + count*90, 60, 60);
            }
            arrowImage.layer.cornerRadius = arrowImage.frame.size.width / 2;
            arrowImage.clipsToBounds = YES;
            arrowImage.contentMode = UIViewContentModeScaleAspectFill;
            arrowImage.clipsToBounds = YES;
            PFFile *imageFile = object[@"ExerciseImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    arrowImage.image =  [UIImage imageWithData:data];
                    
                });
            });
            [pageScroller addSubview:arrowImage];
            
        }
        
        count++;
    }
    [Hud removeFromSuperview];
}

-(IBAction)clickOneTouchWorkout:(UIButton *) sender{
    pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 94);
    
    [self showLoading];
    isExercisesPage = YES;
    PFQuery *exerciseQuery = [PFQuery queryWithClassName:@"PresetWorkouts"];
    [exerciseQuery whereKey:@"objectId" equalTo:sender.titleLabel.text];
    [exerciseQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            
            exercises = object[@"ExerciseIds"];
            workoutNameString = object[@"WorkoutName"];
            
            if(object[@"EasyMedHard"]) {
                easyMedHard = @"1";
                activeDesc = @"1";
            } else {
                easyMedHard = @"0";
                activeDesc = @"0";
            }
            
            PFQuery * ORquery = [PFQuery queryWithClassName:@"Exercises"];
            [ORquery orderByAscending:@"ExerciseName"];
            [ORquery whereKey:@"objectId" containedIn:exercises];
            [ORquery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
                if(!error) {
                    
                    timeEstimate = 0;
                    oneTouchTotalExercises = [results count];
                    
                    if([easyMedHard isEqualToString:@"1"]) {
                        UIAlertController * view=   [UIAlertController
                                                     alertControllerWithTitle:NSLocalizedString(@"Choose Difficulty", nil)
                                                     message:NSLocalizedString(@"Choose the difficulty you'd like the workout to be!", nil)
                                                     preferredStyle:UIAlertControllerStyleActionSheet];
                        
                        UIAlertAction* endurance = [UIAlertAction
                                                    actionWithTitle:NSLocalizedString(@"Easy", nil)
                                                    style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action)
                                                    {
                                                        //Do some thing here
                                                        [view dismissViewControllerAnimated:YES completion:nil];
                                                        
                                                        easyMedHard = @"Endurance";
                                                        
                                                    }];
                        UIAlertAction* fitness = [UIAlertAction
                                                  actionWithTitle:NSLocalizedString(@"Medium", nil)
                                                  style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action)
                                                  {
                                                      //Do some thing here
                                                      [view dismissViewControllerAnimated:YES completion:nil];
                                                      
                                                      easyMedHard = @"Fitness";
                                                      
                                                  }];
                        
                        UIAlertAction* muscle = [UIAlertAction
                                                 actionWithTitle:NSLocalizedString(@"Hard", nil)
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action)
                                                 {
                                                     //Do some thing here
                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                     
                                                     easyMedHard = @"Muscle";
                                                     
                                                 }];
                        
                        
                        
                        UIAlertAction* cancel = [UIAlertAction
                                                 actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action)
                                                 {
                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                     
                                                 }];
                        
                        
                        [view addAction:endurance];
                        [view addAction:fitness];
                        [view addAction:muscle];
                        [view addAction:cancel];
                        [self presentViewController:view animated:YES completion:nil];
                    } else {
                        easyMedHard = @"Endurance";
                    }
                    for(PFObject *result in results) {
                        
                        int exerciseSetTime = ([[result[@"Endurance"] objectAtIndex:3] intValue] * 2) * [[result[@"Endurance"] objectAtIndex:0] intValue];
                        timeEstimate = timeEstimate + exerciseSetTime;
                        
                    }
                    
                    startWorkout = [[UIView alloc] init];
                    startWorkout.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
                    startWorkout.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
                    startWorkout.alpha = 0;
                    [pageScroller addSubview:startWorkout];
                    
                    UILabel *workoutName = [[UILabel alloc] init];
                    workoutName.frame = CGRectMake(30, 35, self.view.frame.size.width - 60, 60);
                    workoutName.font = [UIFont fontWithName:@"ethnocentric" size:16];
                    workoutName.textColor = [UIColor whiteColor];
                    workoutName.textAlignment = NSTextAlignmentCenter;
                    workoutName.numberOfLines = 2;
                    workoutName.text = workoutNameString;
                    [startWorkout addSubview:workoutName];
                    
                    UIButton *xBtn = [[UIButton alloc] init];
                    xBtn.frame = CGRectMake(30, 30, 25, 25);
                    [xBtn setBackgroundImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
                    [xBtn addTarget:self action:@selector(tapXBtn) forControlEvents:UIControlEventTouchUpInside];
                    [startWorkout addSubview:xBtn];
                    
                    UITextView *workoutInfo = [[UITextView alloc] init];
                    workoutInfo.frame = CGRectMake(30, 120, self.view.frame.size.width - 60, 120);
                    workoutInfo.backgroundColor = [UIColor clearColor];
                    workoutInfo.font = [UIFont fontWithName:@"Open Sans" size:14];
                    workoutInfo.textColor = [UIColor whiteColor];
                    workoutInfo.textAlignment = NSTextAlignmentCenter;
                    workoutInfo.text = NSLocalizedString(@"You are about to begin a 'one-touch workout'. Please make sure you are familiar with the exercises in this workout before you begin.", nil);
                    workoutInfo.userInteractionEnabled = NO;
                    workoutInfo.editable = NO;
                    [startWorkout addSubview:workoutInfo];
                    
                    UILabel *workoutTime = [[UILabel alloc] init];
                    workoutTime.frame = CGRectMake(30, 300, self.view.frame.size.width - 60, 60);
                    workoutTime.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    workoutTime.textColor = [UIColor whiteColor];
                    workoutTime.textAlignment = NSTextAlignmentCenter;
                    workoutTime.numberOfLines = 2;
                    NSString *minExerciseTime = [NSString stringWithFormat:NSLocalizedString(@"Workout Time Estimate:\n%d minutes", nil), (timeEstimate / 1000) / 60];
                    workoutTime.text = minExerciseTime;
                    [startWorkout addSubview:workoutTime];
                    
                    oneTouchExerciseCount = 0;
                    
                    UIButton *startBtn = [[UIButton alloc] init];
                    startBtn.frame = CGRectMake(80, 400, self.view.frame.size.width - 160, 35);
                    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                    if([language containsString:@"fr"]) {
                        [startBtn setBackgroundImage:[UIImage imageNamed:@"btn_demarrer"] forState:UIControlStateNormal];
                    } else {
                        [startBtn setBackgroundImage:[UIImage imageNamed:@"btn_startworkout"] forState:UIControlStateNormal];
                    }
                    [startBtn addTarget:self action:@selector(startOneTouch) forControlEvents:UIControlEventTouchUpInside];
                    [startWorkout addSubview:startBtn];
                    
                    [UIView animateWithDuration:0.4f animations:^{
                        startWorkout.alpha = 1;
                        startWorkout.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                    } completion:^(BOOL finished) {
                        
                    }];
                } else {
                    
                }
                [Hud removeFromSuperview];
                
            }];
        } else {
            NSLog(@"The getFirstObject request failed.");
            [Hud removeFromSuperview];
        }
    }];
}

-(void)tapXBtn {
    [UIView animateWithDuration:0.4f animations:^{
        startWorkout.alpha = 0;
        startWorkout.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    }];
}

-(void)startOneTouch {
    [UIView animateWithDuration:0.4f animations:^{
        startWorkout.alpha = 0;
        startWorkout.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    } completion:^(BOOL finished) {
        for (UIView *view in [pageScroller subviews])
        {
            [view removeFromSuperview];
        }
        
        [self showLoading];
        
        if(oneTouchExerciseCount < oneTouchTotalExercises) {
            PFQuery *query = [PFQuery queryWithClassName:@"Exercises"];
            [query whereKey:@"objectId" equalTo:[exercises objectAtIndex:oneTouchExerciseCount]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if(!error) {
                    
                    UIView *workoutView = [[UIView alloc] init];
                    workoutView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                    [pageScroller addSubview:workoutView];
                    
                    UILabel *workoutName = [[UILabel alloc] init];
                    workoutName.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 60);
                    workoutName.numberOfLines = 2;
                    workoutName.textAlignment = NSTextAlignmentCenter;
                    workoutName.text = workoutNameString;
                    workoutName.font = [UIFont fontWithName:@"ethnocentric" size:18];
                    [workoutView addSubview:workoutName];
                    
                    UIImageView *exerciseImage = [[UIImageView alloc] init];
                    exerciseImage.frame = CGRectMake(0, 75, self.view.frame.size.width, 170);
                    exerciseImage.contentMode = UIViewContentModeScaleAspectFit;
                    exerciseImage.clipsToBounds = YES;
                    PFFile *imageFile = object[@"ExerciseImage"];
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        
                        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                        if ( data == nil )
                            return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[activityView1 stopAnimating];
                            //[activityView1 removeFromSuperview];
                            exerciseImage.image =  [UIImage imageWithData:data];
                            
                        });
                    });
                    [workoutView addSubview:exerciseImage];
                    
                    if([activeDesc isEqualToString:@"1"]) {
                        UITextView *exerciseDesc = [[UITextView alloc] init];
                        exerciseDesc.frame = CGRectMake(25, 250, self.view.frame.size.width - 50, 60);
                        exerciseDesc.editable = NO;
                        exerciseDesc.font = [UIFont fontWithName:@"Open Sans" size:12];
                        exerciseDesc.textAlignment = NSTextAlignmentCenter;
                        exerciseDesc.text = object[@"Description"];
                        [workoutView addSubview:exerciseDesc];
                    }
                    
                    UILabel *exerciseName = [[UILabel alloc] init];
                    exerciseName.frame = CGRectMake(50, 310, self.view.frame.size.width - 100, 30);
                    exerciseName.font = [UIFont fontWithName:@"ethnocentric" size:14];
                    exerciseName.textAlignment = NSTextAlignmentCenter;
                    exerciseName.text = object[@"ExerciseName"];
                    [workoutView addSubview:exerciseName];
                    
                    UILabel *exerciseCount = [[UILabel alloc] init];
                    exerciseCount.frame = CGRectMake(50, 340, self.view.frame.size.width - 100, 30);
                    exerciseCount.font = [UIFont fontWithName:@"ethnocentric" size:12];
                    exerciseCount.textAlignment = NSTextAlignmentCenter;
                    exerciseCount.text = [NSString stringWithFormat:NSLocalizedString(@"Exercise: %d/%d", nil), oneTouchExerciseCount+1, oneTouchTotalExercises];
                    [workoutView addSubview:exerciseCount];
                    
                    UILabel *statusLabel = [[UILabel alloc] init];
                    statusLabel.frame = CGRectMake(30, self.view.frame.size.height - 170, self.view.frame.size.width - 60, 30);
                    statusLabel.textAlignment = NSTextAlignmentCenter;
                    statusLabel.text = NSLocalizedString(@"Status - Change Equipment", nil);
                    statusLabel.font = [UIFont fontWithName:@"ethnocentric" size:12];
                    [workoutView addSubview:statusLabel];
                    
                    UIButton *pauseBtn = [[UIButton alloc] init];
                    [pauseBtn setBackgroundImage:[UIImage imageNamed:@"btn_pause_workout"] forState:UIControlStateNormal];
                    pauseBtn.frame = CGRectMake((self.view.frame.size.width / 2) - 75, self.view.frame.size.height - 270, 50, 50);
                    [pauseBtn addTarget:self action:@selector(tappedPause) forControlEvents:UIControlEventTouchUpInside];
                    [workoutView addSubview:pauseBtn];
                    
                    UIButton *unpauseBtn = [[UIButton alloc] init];
                    [unpauseBtn setBackgroundImage:[UIImage imageNamed:@"btn_skip_workout"] forState:UIControlStateNormal];
                    unpauseBtn.frame = CGRectMake((self.view.frame.size.width / 2) + 25, self.view.frame.size.height - 270, 50, 50);
                    [unpauseBtn addTarget:self action:@selector(tappedUnPause) forControlEvents:UIControlEventTouchUpInside];
                    [workoutView addSubview:unpauseBtn];
                    
                    timerBar = [[UIView alloc] init];
                    timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                    timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
                    [workoutView addSubview:timerBar];
                    
                    float exerciseTime = ([[object[easyMedHard] objectAtIndex:3] intValue] / 1000);
                    float restTime = ([[object[easyMedHard] objectAtIndex:4] intValue] / 1000);
                    
                    NSLog(@"%f", exerciseTime);
                    
                    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"beep-09"
                                                                              ofType:@"mp3"];
                    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
                    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
                    audioPlayer.numberOfLoops = 0;
                    AVAudioSession *audiosession = [AVAudioSession sharedInstance];
                    [audiosession setCategory:AVAudioSessionCategoryAmbient error:nil];
                    
                    if([[object[easyMedHard] objectAtIndex:0] isEqualToString:@"1"]) {
                        NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++1");
                        [UIView animateWithDuration:25.0f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                            
                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                            [workoutView addSubview:unpauseBtn];
                            [workoutView addSubview:pauseBtn];
                            
                        } completion:^(BOOL finished) {
                            
                            [audioPlayer play];
                            
                            [UIView animateWithDuration:0.4f animations:^{
                                
                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                [unpauseBtn removeFromSuperview];
                                [pauseBtn removeFromSuperview];
                                
                            } completion:^(BOOL finished) {
                                
                                [audioPlayer play];
                                
                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                    
                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                    
                                } completion:^(BOOL finished) {
                                    
                                    [audioPlayer play];
                                    
                                    [UIView animateWithDuration:0.4f animations:^{
                                        
                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                        
                                    } completion:^(BOOL finished) {
                                        
                                        [audioPlayer play];
                                        
                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                            
                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                            
                                        } completion:^(BOOL finished) {
                                            
                                            [audioPlayer play];
                                            
                                            [UIView animateWithDuration:0.4f animations:^{
                                                
                                                statusLabel.text = NSLocalizedString(@"Status - Change Equipment", nil);
                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
                                                [workoutView addSubview:unpauseBtn];
                                                [workoutView addSubview:pauseBtn];
                                                
                                            } completion:^(BOOL finished) {
                                                oneTouchExerciseCount++;
                                                [self startOneTouch];
                                            }];
                                        }];
                                    }];
                                }];
                            }];
                        }];
                        
                    } else if([[object[easyMedHard] objectAtIndex:0] isEqualToString:@"2"]) {
                        NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++2");
                        
                        [UIView animateWithDuration:25.0f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                            
                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                            [workoutView addSubview:unpauseBtn];
                            [workoutView addSubview:pauseBtn];
                            
                        } completion:^(BOOL finished) {
                            
                            [audioPlayer play];
                            
                            [UIView animateWithDuration:0.4f animations:^{
                                
                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                [unpauseBtn removeFromSuperview];
                                [pauseBtn removeFromSuperview];
                                
                            } completion:^(BOOL finished) {
                                
                                [audioPlayer play];
                                
                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                    
                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                    
                                } completion:^(BOOL finished) {
                                    
                                    [audioPlayer play];
                                    
                                    [UIView animateWithDuration:0.4f animations:^{
                                        
                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                        
                                    } completion:^(BOOL finished) {
                                        
                                        [audioPlayer play];
                                        
                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                            
                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                            
                                        } completion:^(BOOL finished) {
                                            
                                            [audioPlayer play];
                                            
                                            [UIView animateWithDuration:0.4f animations:^{
                                                
                                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                                
                                            } completion:^(BOOL finished) {
                                                
                                                [audioPlayer play];
                                                
                                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                    
                                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                    
                                                } completion:^(BOOL finished) {
                                                    
                                                    [audioPlayer play];
                                                    
                                                    [UIView animateWithDuration:0.4f animations:^{
                                                        
                                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                                        
                                                    } completion:^(BOOL finished) {
                                                        
                                                        [audioPlayer play];
                                                        
                                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                            
                                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                            
                                                        } completion:^(BOOL finished) {
                                                            
                                                            [audioPlayer play];
                                                            
                                                            [UIView animateWithDuration:0.4f animations:^{
                                                                
                                                                statusLabel.text = NSLocalizedString(@"Status - Change Equipment", nil);
                                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
                                                                [workoutView addSubview:unpauseBtn];
                                                                [workoutView addSubview:pauseBtn];
                                                                
                                                            } completion:^(BOOL finished) {
                                                                oneTouchExerciseCount++;
                                                                [self startOneTouch];
                                                            }];
                                                        }];
                                                    }];
                                                }];
                                            }];
                                        }];
                                    }];
                                }];
                            }];
                        }];
                        
                    } else if([[object[easyMedHard] objectAtIndex:0] isEqualToString:@"3"]) {
                        NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++3");
                        
                        [UIView animateWithDuration:25.0f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                            
                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                            [workoutView addSubview:unpauseBtn];
                            [workoutView addSubview:pauseBtn];
                            
                        } completion:^(BOOL finished) {
                            
                            [audioPlayer play];
                            
                            [UIView animateWithDuration:0.4f animations:^{
                                
                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                [unpauseBtn removeFromSuperview];
                                [pauseBtn removeFromSuperview];
                                
                            } completion:^(BOOL finished) {
                                
                                [audioPlayer play];
                                
                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                    
                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                    
                                } completion:^(BOOL finished) {
                                    
                                    [audioPlayer play];
                                    
                                    [UIView animateWithDuration:0.4f animations:^{
                                        
                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                        
                                    } completion:^(BOOL finished) {
                                        
                                        [audioPlayer play];
                                        
                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                            
                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                            
                                        } completion:^(BOOL finished) {
                                            
                                            [audioPlayer play];
                                            
                                            [UIView animateWithDuration:0.4f animations:^{
                                                
                                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                                
                                            } completion:^(BOOL finished) {
                                                
                                                [audioPlayer play];
                                                
                                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                    
                                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                    
                                                } completion:^(BOOL finished) {
                                                    
                                                    [audioPlayer play];
                                                    
                                                    [UIView animateWithDuration:0.4f animations:^{
                                                        
                                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                                        
                                                    } completion:^(BOOL finished) {
                                                        
                                                        [audioPlayer play];
                                                        
                                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                            
                                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                            
                                                        } completion:^(BOOL finished) {
                                                            
                                                            [audioPlayer play];
                                                            
                                                            [UIView animateWithDuration:0.4f animations:^{
                                                                
                                                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                                                
                                                            } completion:^(BOOL finished) {
                                                                
                                                                [audioPlayer play];
                                                                
                                                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                                    
                                                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                    
                                                                } completion:^(BOOL finished) {
                                                                    
                                                                    [audioPlayer play];
                                                                    
                                                                    [UIView animateWithDuration:0.4f animations:^{
                                                                        
                                                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                                                        
                                                                    } completion:^(BOOL finished) {
                                                                        
                                                                        [audioPlayer play];
                                                                        
                                                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                                                            
                                                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                            
                                                                        } completion:^(BOOL finished) {
                                                                            
                                                                            [audioPlayer play];
                                                                            
                                                                            [UIView animateWithDuration:0.4f animations:^{
                                                                                
                                                                                statusLabel.text = NSLocalizedString(@"Status - Change Equipment", nil);
                                                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                                                timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
                                                                                [workoutView addSubview:unpauseBtn];
                                                                                [workoutView addSubview:pauseBtn];
                                                                                
                                                                            } completion:^(BOOL finished) {
                                                                                oneTouchExerciseCount++;
                                                                                [self startOneTouch];
                                                                            }];
                                                                        }];
                                                                    }];
                                                                }];
                                                            }];
                                                        }];
                                                    }];
                                                }];
                                            }];
                                        }];
                                    }];
                                }];
                            }];
                        }];
                    }else{
                        NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++error");
                        [UIView animateWithDuration:25.0f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                            
                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                            [workoutView addSubview:unpauseBtn];
                            [workoutView addSubview:pauseBtn];
                            
                        } completion:^(BOOL finished) {
                            
                            [audioPlayer play];
                            
                            [UIView animateWithDuration:0.4f animations:^{
                                
                                statusLabel.text = NSLocalizedString(@"Status - Working Out", nil);
                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                timerBar.backgroundColor = [UIColor colorWithRed:0.35 green:0.70 blue:0.13 alpha:1.0];
                                [unpauseBtn removeFromSuperview];
                                [pauseBtn removeFromSuperview];
                                
                            } completion:^(BOOL finished) {
                                
                                [audioPlayer play];
                                
                                [UIView animateWithDuration:exerciseTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                    
                                    timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                    
                                } completion:^(BOOL finished) {
                                    
                                    [audioPlayer play];
                                    
                                    [UIView animateWithDuration:0.4f animations:^{
                                        
                                        statusLabel.text = NSLocalizedString(@"Status - Resting", nil);
                                        timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                        timerBar.backgroundColor = [UIColor colorWithRed:0.13 green:0.75 blue:0.73 alpha:1.0];
                                        
                                    } completion:^(BOOL finished) {
                                        
                                        [audioPlayer play];
                                        
                                        [UIView animateWithDuration:restTime delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                                            
                                            timerBar.frame = CGRectMake(-self.view.frame.size.width, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                            
                                        } completion:^(BOOL finished) {
                                            
                                            [audioPlayer play];
                                            
                                            [UIView animateWithDuration:0.4f animations:^{
                                                
                                                statusLabel.text = NSLocalizedString(@"Status - Change Equipment", nil);
                                                timerBar.frame = CGRectMake(0, self.view.frame.size.height - 135, self.view.frame.size.width, 45);
                                                timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
                                                [workoutView addSubview:unpauseBtn];
                                                [workoutView addSubview:pauseBtn];
                                                
                                            } completion:^(BOOL finished) {
                                                oneTouchExerciseCount++;
                                                [self startOneTouch];
                                            }];
                                        }];
                                    }];
                                }];
                            }];
                        }];
                    }
                    
                } else {
                    NSLog(@"%@", error.description);
                }
            }];
        } else {
            
            //Exercise Completed
            UIView *finalView = [[UIView alloc] init];
            finalView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [pageScroller addSubview:finalView];
            
            UILabel *completeLabel = [[UILabel alloc] init];
            completeLabel.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 60);
            completeLabel.numberOfLines = 2;
            completeLabel.textAlignment = NSTextAlignmentCenter;
            completeLabel.text = NSLocalizedString(@"Workout Complete", nil);
            completeLabel.font = [UIFont fontWithName:@"ethnocentric" size:18];
            [finalView addSubview:completeLabel];
            
            endTime = [NSString stringWithFormat:NSLocalizedString(@"%d minutes", nil), (timeEstimate / 1000) / 60];
            
            UITextView *exerciseCount = [[UITextView alloc] init];
            exerciseCount.frame = CGRectMake(20, 80, self.view.frame.size.width - 40, 100);
            exerciseCount.font = [UIFont fontWithName:@"Open Sans" size:14];
            exerciseCount.textAlignment = NSTextAlignmentCenter;
            exerciseCount.editable = NO;
            exerciseCount.text = [NSString stringWithFormat:NSLocalizedString(@"Congratulations on finishing the %@. You have completed the workout in %@.", nil), workoutNameString, endTime];
            [finalView addSubview:exerciseCount];
            
            UIImageView *heartIc = [[UIImageView alloc]init];
            heartIc.frame = CGRectMake((self.view.frame.size.width / 2) - 20, 200, 40, 40);
            heartIc.image = [UIImage imageNamed:@"Heart"];
            heartIc.contentMode = UIViewContentModeScaleAspectFit;
            heartIc.clipsToBounds = YES;
            [finalView addSubview:heartIc];
            
            UILabel *heartCount = [[UILabel alloc] init];
            heartCount.frame = CGRectMake(60, 250, self.view.frame.size.width - 120, 40);
            heartCount.textAlignment = NSTextAlignmentCenter;
            heartCount.text = [NSString stringWithFormat:@"%d", oneTouchTotalExercises * 300];
            heartCount.font = [UIFont fontWithName:@"ethnocentric" size:18];
            [finalView addSubview:heartCount];
            
            UILabel *exercisesCompleted = [[UILabel alloc] init];
            exercisesCompleted.frame = CGRectMake(60, 320, self.view.frame.size.width - 120, 40);
            exercisesCompleted.textAlignment = NSTextAlignmentCenter;
            exercisesCompleted.text = [NSString stringWithFormat:NSLocalizedString(@"Exercises Completed: %d", nil), oneTouchTotalExercises];
            exercisesCompleted.font = [UIFont fontWithName:@"Open Sans" size:12];
            [finalView addSubview:exercisesCompleted];
            
            UIButton *completeBtn = [[UIButton alloc] init];
            completeBtn.frame = CGRectMake(80, self.view.frame.size.height - 200, self.view.frame.size.width - 160, 35);
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            if([language containsString:@"fr"]) {
                [completeBtn setBackgroundImage:[UIImage imageNamed:@"btn_endworkout_french"] forState:UIControlStateNormal];
            } else {
                [completeBtn setBackgroundImage:[UIImage imageNamed:@"btn_endworkout"] forState:UIControlStateNormal];
            }
            [completeBtn addTarget:self action:@selector(tapCompleteWorkout) forControlEvents:UIControlEventTouchUpInside];
            [finalView addSubview:completeBtn];
            
            
        }
        
        [Hud removeFromSuperview];
    }];
}
-(void)resigningActive {
    NSLog(@"App Out");
    [self tappedPause];
}

-(void)becomeActive {
    NSLog(@"App In");
    //[self tappedUnPause];
}

Boolean puse = true;
-(void)tappedPause {
    if(puse){
        CFTimeInterval pausedTime = [timerBar.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        timerBar.backgroundColor = [UIColor grayColor];
        timerBar.layer.speed = 0.0f;
        timerBar.layer.timeOffset = pausedTime;
        puse = false;
    }else{
        CFTimeInterval pausedTime = [timerBar.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        timerBar.layer.timeOffset = pausedTime;
        timerBar.layer.speed = 0.01f;
        timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
        puse = true;
    }
}

-(void)tappedUnPause {
    CFTimeInterval playTime = [timerBar.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    timerBar.backgroundColor = [UIColor colorWithRed:0.92 green:0.52 blue:0.13 alpha:1.0];
    timerBar.layer.speed = 1.0f;
    timerBar.layer.timeOffset = playTime;
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

-(void)tapCompleteWorkout {
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + (oneTouchTotalExercises * 300));
    [[PFUser currentUser] saveInBackground];
    
    PFQuery * trackedEventsQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
    [trackedEventsQuery whereKey:@"User" equalTo:[PFUser currentUser]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [formatter stringFromDate:currentDate];
    [trackedEventsQuery whereKey:@"Date" equalTo:dateString];
    [trackedEventsQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!error) {
             if(object != nil) {
                 int tmp = [object[@"Exercises"] intValue] + oneTouchTotalExercises;
                 object[@"Exercises"] = @(tmp);
                 tmp = [object[@"Hearts"] intValue] + (oneTouchTotalExercises * 300);
                 object[@"Hearts"] = @(tmp);
                 object[@"Park"] = [PFUser currentUser][@"HomePark"];
                 [object saveInBackground];
                 
                 for(PFObject *exercise in exercises) {
                     NSLog(@"%@", exercise);
                     NSString *objectIdToAdd = exercise;
                     [object addObject:objectIdToAdd forKey:@"ExercisesUsed"];
                     [object saveInBackground];
                 }
                 
             }
         } else {
             
             if(error.code == 101) {// Object not found
                 PFObject *trackedEvents = [PFObject objectWithClassName:@"TrackedEvents"];
                 [trackedEvents setObject:[PFUser currentUser] forKey:@"User"];
                 trackedEvents[@"Hearts"] = @(oneTouchTotalExercises * 300);
                 trackedEvents[@"Date"] = dateString;
                 trackedEvents[@"Exercises"] = @(1);
                 trackedEvents[@"Park"] = [PFUser currentUser][@"HomePark"];
                 NSDate *date = [NSDate date];
                 NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                 [formatter setDateFormat:@"H"];
                 NSString *timeString = [formatter stringFromDate:date];
                 object[@"Time"] = timeString;
                 [trackedEvents saveInBackground];
                 
                 for(PFObject *exercise in exercises) {
                     NSLog(@"%@", exercise);
                     NSString *objectIdToAdd = exercise;
                     [object addObject:objectIdToAdd forKey:@"ExercisesUsed"];
                     [object saveInBackground];
                 }
                 
             }
         }
     }];
    
    [self loadUser];
}

-(IBAction)exerciseButtonClicked:(id)sender
{
    isExercisesPage = TRUE;
    //SWRevealViewController *exerciseClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"BrowseAllTableClicked"];
    
    //[self.navigationController pushViewController:exerciseClickControl animated:YES];
    // With some valid UIView *view:
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    
    isExercisesPage = TRUE;
    //RECTANGLES
    CGRect frame1;
    CGRect frame2;
    CGRect frame3;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        frame1 = CGRectMake( 0, 93, 107.0, 40.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 107.0, 40.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 107.0, 40.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        frame1 = CGRectMake( 0, 93, 107.0, 40.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 107.0, 40.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 107.0, 40.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        frame1 = CGRectMake( 0, 94, 125.0, 50.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 94, 125.0, 50.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 94, 125.0, 50.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        frame1 = CGRectMake( 0, 94, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 94, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 94, 140, 60);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    } else {
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    }
    
    view1 = [[UIButton alloc] initWithFrame:frame1];
    view2 = [[UIButton alloc] initWithFrame:frame2];
    view3 = [[UIButton alloc] initWithFrame:frame3];
    
    [view1 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view2 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view3 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    
    [view1 setTitle:NSLocalizedString(@"Browse All", nil) forState:UIControlStateNormal];
    [view2 setTitle:NSLocalizedString(@"Most Used", nil) forState:UIControlStateNormal];
    [view3 setTitle:NSLocalizedString(@"My Exercises", nil) forState:UIControlStateNormal];
    
    [view1 addTarget:self action:@selector(tapExerciseBar:) forControlEvents:UIControlEventTouchUpInside];
    [view2 addTarget:self action:@selector(tapMostUsedBar:) forControlEvents:UIControlEventTouchUpInside];
    [view3 addTarget:self action:@selector(tapMyExercisesBar:) forControlEvents:UIControlEventTouchUpInside];
    
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    }
    
    [self.view addSubview:view1];
    [self.view addSubview:view2];
    [self.view addSubview:view3];
    
    //Search Bar
    //Navigational Bar
    UIView *gapImage = [[UIView alloc] init];
    gapImage.backgroundColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        gapImage.frame = CGRectMake(0, 130, self.view.frame.size.width, 70); //Image scaled
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        gapImage.frame = CGRectMake(0, 130, self.view.frame.size.width, 70); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        gapImage.frame = CGRectMake(0, 145, self.view.frame.size.width, 70); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        gapImage.frame = CGRectMake(0, 153, self.view.frame.size.width, 70); //Image scaled
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    } else {
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    }
    
    [self.view addSubview:gapImage];
    
    searchBar = [[UISearchBar alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        searchBar.frame = CGRectMake(22, 145, self.view.frame.size.width - 45, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        searchBar.frame = CGRectMake(22, 145, self.view.frame.size.width - 45, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        searchBar.frame = CGRectMake(19, 155, self.view.frame.size.width - 40, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        searchBar.frame = CGRectMake(19, 165, self.view.frame.size.width - 40, 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    } else {
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    }
    searchBar.barTintColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    searchBar.layer.borderWidth = 1;
    searchBar.layer.borderColor = [[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0] CGColor];
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    
    // To change background color
    searchField.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
    //[self tapExerciseBar:self];
    [self findNearestParksButton];
    
    
}

-(IBAction)workoutButtonClicked:(id)sender
{
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    isExercisesPage = FALSE;
    //RECTANGLES
    CGRect frame1;
    CGRect frame2;
    CGRect frame3;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        frame1 = CGRectMake( 0, 93, 107.0, 40.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 107.0, 40.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 107.0, 40.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        frame1 = CGRectMake( 0, 93, 107.0, 40.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 107.0, 40.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 107.0, 40.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        frame1 = CGRectMake( 0, 94, 125.0, 50.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 94, 125.0, 50.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 94, 125.0, 50.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        frame1 = CGRectMake( 0, 94, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 94, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 94, 140, 60);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    } else {
        frame1 = CGRectMake( 0, 138, 140, 60);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 138, 140, 60);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 138, 140, 60);
    }
    
    
    view1 = [[UIButton alloc] initWithFrame:frame1];
    view2 = [[UIButton alloc] initWithFrame:frame2];
    view3 = [[UIButton alloc] initWithFrame:frame3];
    
    [view1 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view2 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view3 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    
    [view1 setTitle:NSLocalizedString(@"Browse All", nil) forState:UIControlStateNormal];
    [view2 setTitle:NSLocalizedString(@"Most Used", nil) forState:UIControlStateNormal];
    [view3 setTitle:NSLocalizedString(@"My Routines", nil) forState:UIControlStateNormal];
    
    [view1 addTarget:self action:@selector(tapWorkoutBar:) forControlEvents:UIControlEventTouchUpInside];
    [view2 addTarget:self action:@selector(tapMostUsedWorkoutBar:) forControlEvents:UIControlEventTouchUpInside];
    [view3 addTarget:self action:@selector(tapMyRoutinesBar:) forControlEvents:UIControlEventTouchUpInside];
    
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:14]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    }
    
    [self.view addSubview:view1];
    [self.view addSubview:view2];
    [self.view addSubview:view3];
    
    //Search Bar
    //Navigational Bar
    UIView *gapImage = [[UIView alloc] init];
    gapImage.backgroundColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        gapImage.frame = CGRectMake(0, 130, self.view.frame.size.width, 70); //Image scaled
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        gapImage.frame = CGRectMake(0, 130, self.view.frame.size.width, 70); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        gapImage.frame = CGRectMake(0, 145, self.view.frame.size.width, 70); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        gapImage.frame = CGRectMake(0, 153, self.view.frame.size.width, 70); //Image scaled
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    } else {
        gapImage.frame = CGRectMake(0, 198, self.view.frame.size.width, 70); //Image scaled
    }
    
    [self.view addSubview:gapImage];
    
    searchBar = [[UISearchBar alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        searchBar.frame = CGRectMake(22, 145, self.view.frame.size.width - 45, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        searchBar.frame = CGRectMake(22, 145, self.view.frame.size.width - 45, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        searchBar.frame = CGRectMake(19, 155, self.view.frame.size.width - 40, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        searchBar.frame = CGRectMake(19, 165, self.view.frame.size.width - 40, 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    }else if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone XR/Max size
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    } else {
        searchBar.frame = CGRectMake(19, 210, self.view.frame.size.width - 40, 40);
    }
    searchBar.barTintColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    searchBar.layer.borderWidth = 1;
    searchBar.layer.borderColor = [[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0] CGColor];
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    
    // To change background color
    searchField.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    searchBar.delegate = self;
    [self.view addSubview:searchBar];
    [self tapWorkoutBar: self];
    
}
-(void)showLoading
{
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = NSLocalizedString(@"Loading", nil);
    //Start the animation
    [activityImageView startAnimating];
    
    
    //Add your custom activity indicator to your current view
    [pageScroller addSubview:activityImageView];
    Hud.customView = activityImageView;
}
-(IBAction)tapExerciseBar:(id)sender
{
    if(isHomePark) {
        [noDataView removeFromSuperview];
        
        isExercisesPage = TRUE;
        [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [self showLoading];
        
        
        PFQuery *parkExercisesQuery = [PFQuery queryWithClassName:@"Locations"];
        [parkExercisesQuery whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
        [parkExercisesQuery getFirstObjectInBackgroundWithBlock:^(PFObject *obj, NSError *error) {
            if(!error) {
                exerciseArray = [[NSMutableArray alloc] init];
                [exerciseArray addObject:obj[@"ExerciseIds"]];
                NSLog(@"Location Park Query: %@", exerciseArray);
                NSLog(@"Location Park Query2: %@", obj[@"ExerciseIds"]);
                
                
                //QUERY FOR GETTING ALL EXERCISES
                PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"Exercises"];
                if([[PFUser currentUser][@"isFrench"] isEqual:@YES]) {
                    [browseAllQuery whereKey:@"isFrench" equalTo:@YES];
                }
                [browseAllQuery whereKey:@"objectId" containedIn:obj[@"ExerciseIds"]];
                [browseAllQuery orderByAscending:@"ExerciseName"];
                [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        collectedExercises = objects;
                        [self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteExercises"]: nil:-1];
                    } else {
                        [Hud removeFromSuperview];
                    }
                }];
            } else {
                [Hud removeFromSuperview];
                noDataView = [[UIView alloc] init];
                noDataView.frame = CGRectMake(0, 130, self.view.frame.size.width, self.view.frame.size.height);
                
                [self.view addSubview:noDataView];
                
                UILabel *friendsLabel = [[UILabel alloc] init];
                friendsLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 200);
                friendsLabel.text = NSLocalizedString(@"You need to select a home park below to find exercises!", nil);
                friendsLabel.textAlignment = NSTextAlignmentCenter;
                friendsLabel.numberOfLines = 5;
                friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
                
                [noDataView addSubview:friendsLabel];
                
                if([[PFUser currentUser][@"HomePark"]  isEqual: @"NotSelected"]) {
                    //Add Home Park
                    UIButton *addHomeParkButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                    {
                        addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                        
                    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                    {
                        addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                    {
                        addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width - 150, 40);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                    {
                        addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                    {
                        addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                    } else {
                        addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                    }
                    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                    if([language containsString:@"fr"]) {
                        [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choosepark_french"] forState:UIControlStateNormal];
                    } else {
                        [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choose"] forState:UIControlStateNormal];
                    }
                    [addHomeParkButton addTarget:self action:@selector(addHomePark:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [noDataView addSubview:addHomeParkButton];
                    
                } else {
                    // Find nearest Park
                    isFindingNearestParkOn = false;
                    findParksButton = [UIButton buttonWithType:UIButtonTypeCustom];
                    //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                    {
                        findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                        
                    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                    {
                        findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                    {
                        findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width - 150, 40);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                    {
                        findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                    {
                        findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                    } else {
                        findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                    }
                    [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_2"] forState:UIControlStateNormal];
                    [findParksButton addTarget:self action:@selector(tapfindNearestParksButton:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [noDataView addSubview:findParksButton];
                    
                }
                
                [Hud removeFromSuperview];
                NSLog(@"Location Park Query Failed");
            }
        }];
    } else {
        [self tapExerciseBarNotAtYourHomePark];
    }
}

-(void)tapExerciseBarNotAtYourHomePark
{
    [noDataView removeFromSuperview];
    
    isExercisesPage = TRUE;
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [self showLoading];
    
    
    PFQuery *parkExercisesQuery = [PFQuery queryWithClassName:@"Locations"];
    [parkExercisesQuery whereKey:@"objectId" equalTo:currentLocationID];
    [parkExercisesQuery getFirstObjectInBackgroundWithBlock:^(PFObject *obj, NSError *error) {
        if(!error) {
            exerciseArray = [[NSMutableArray alloc] init];
            [exerciseArray addObject:obj[@"ExerciseIds"]];
            NSMutableArray *exerciseArrayTmp = [NSMutableArray arrayWithArray:obj[@"ExerciseIds"]];
            int count = [exerciseArrayTmp count];
            NSLog(@"---------------------------, %d", count);
            NSLog(@"Location Park Query: %@", exerciseArray);
            NSLog(@"Location Park Query2: %@", obj[@"ExerciseIds"]);
            
            PFQuery *parkExercisesQuery2 = [PFQuery queryWithClassName:@"Locations"];
            [parkExercisesQuery2 whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
            [parkExercisesQuery2 getFirstObjectInBackgroundWithBlock:^(PFObject *obj, NSError *error2) {
                if(!error2) {
                    NSMutableArray *exerciseArrayCurrent = [[NSMutableArray alloc] init];
                    [exerciseArrayCurrent addObject:obj[@"ExerciseIds"]];
                    for (NSString *tmp in obj[@"ExerciseIds"]) {
                        if(![exerciseArrayTmp containsObject:tmp]) {
                            [exerciseArrayTmp addObject:tmp];
                        }
                    }
                    //QUERY FOR GETTING ALL EXERCISES
                    PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"Exercises"];
                    if([[PFUser currentUser][@"isFrench"] isEqual:@YES]) {
                        [browseAllQuery whereKey:@"isFrench" equalTo:@YES];
                    }
                    [browseAllQuery whereKey:@"objectId" containedIn:exerciseArrayTmp];
                    [browseAllQuery orderByAscending:@"ExerciseName"];
                    [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            collectedExercises = objects;
                            [self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteExercises"]: nil : count];
                        } else {
                            [Hud removeFromSuperview];
                        }
                    }];
                } else {
                    [Hud removeFromSuperview];
                }
            }];
        } else {
            [Hud removeFromSuperview];
            noDataView = [[UIView alloc] init];
            noDataView.frame = CGRectMake(0, 130, self.view.frame.size.width, self.view.frame.size.height);
            
            [self.view addSubview:noDataView];
            
            UILabel *friendsLabel = [[UILabel alloc] init];
            friendsLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 200);
            friendsLabel.text = NSLocalizedString(@"You need to select a home park below to find exercises!", nil);
            friendsLabel.textAlignment = NSTextAlignmentCenter;
            friendsLabel.numberOfLines = 5;
            friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            
            [noDataView addSubview:friendsLabel];
            
            if([[PFUser currentUser][@"HomePark"]  isEqual: @"NotSelected"]) {
                //Add Home Park
                UIButton *addHomeParkButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                }
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if([language containsString:@"fr"]) {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choosepark_french"] forState:UIControlStateNormal];
                } else {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choose"] forState:UIControlStateNormal];
                }
                [addHomeParkButton addTarget:self action:@selector(addHomePark:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:addHomeParkButton];
                
            } else {
                // Find nearest Park
                isFindingNearestParkOn = false;
                findParksButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                }
                [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_2"] forState:UIControlStateNormal];
                [findParksButton addTarget:self action:@selector(tapfindNearestParksButton:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:findParksButton];
                
            }
            
            [Hud removeFromSuperview];
            NSLog(@"Location Park Query Failed");
        }
    }];
}

-(IBAction)addHomePark:(id)sender {
    
    [self tapfindNearestParksButton:nil];
}

-(void)findNearestParksButton
{
    isFindingNearestParkOn = true;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [locationManager requestWhenInUseAuthorization];
    
    [locationManager startUpdatingLocation];
}
-(IBAction)tapfindNearestParksButton:(id)sender
{
    if(!isFindingNearestParkOn) {
        isFindingNearestParkOn = true;
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
            [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];}
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
    /*NSLog(@"didUpdateToLocation: %@", newLocation);
     CLLocation *currentLocation = newLocation;
     
     if (currentLocation != nil) {
     [self showLoading];
     [locationManager stopUpdatingLocation];
     locationManager.delegate = nil;
     NSLog(@"Longitude: %@",[NSString stringWithFormat:@"%.8f",currentLocation.coordinate.longitude]);
     NSLog(@"Latitude: %@",[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude]);
     
     pageScroller2 = [[UIScrollView alloc] init];
     
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     pageScroller2.frame = CGRectMake(0, 92, self.view.frame.size.width, self.view.frame.size.height-46); //Position of the scroller
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
     {
     pageScroller2.frame = CGRectMake(0, 393, self.view.frame.size.width, self.view.frame.size.height-46); //Position of the scroller
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
     
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     pageScroller2.frame = CGRectMake(0, 320, self.view.frame.size.width, 250); //Position of the scroller
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     pageScroller2.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     pageScroller2.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
     }
     [noDataView addSubview:pageScroller2];
     
     PFQuery *query = [PFQuery queryWithClassName:@"Locations"];
     [query setLimit:999];
     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
     if (!error) {
     UIButton *viewMapButton = [UIButton buttonWithType:UIButtonTypeCustom];
     //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
     locationsObj = [[NSMutableArray alloc] init];
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 0, 30, 30);//Position of the button
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
     {
     viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 0, 30, 30);//Position of the button
     } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
     {
     viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 0, 40, 40);//Position of the button
     } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 0, 40, 40);//Position of the button
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     viewMapButton.frame = CGRectMake(self.view.frame.size.width-50, 0, 40, 40);//Position of the button
     }
     [viewMapButton setBackgroundImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
     [viewMapButton addTarget:self action:@selector(tapViewMapBtn:) forControlEvents:UIControlEventTouchUpInside];
     
     [pageScroller2 addSubview:viewMapButton];
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
     float distanceinMiles = distanceInMeters * 0.000621371;
     
     if (distanceinMiles < 25) { // distance < 25 miles
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
     nearestPark.frame = CGRectMake(5, 0 + count * 50, 120, 30);
     nearestParkBg.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
     nearestParkDistance.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     addParkBtn.frame = CGRectMake(250, 0 + count * 50, 30, 30);
     viewParkBtn.frame = CGRectMake(285, 0 + count * 50, 30, 30);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 568) // iPhone 5/5S
     {
     nearestPark.font = [UIFont fontWithName:@"Open Sans" size:12];
     nearestPark.frame = CGRectMake(5, 0 + count * 50, 120, 30);
     nearestParkBg.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:12];
     nearestParkDistance.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     addParkBtn.frame = CGRectMake(250, 0 + count * 50, 30, 30);
     viewParkBtn.frame = CGRectMake(285, 0 + count * 50, 30, 30);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
     {
     nearestPark.font = [UIFont fontWithName:@"Open Sans" size:14];
     nearestPark.frame = CGRectMake(5,  0 + count * 50, 130, 30);
     nearestParkBg.frame = CGRectMake(0,  0 + count * 50, self.view.frame.size.width, 30);
     nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:14];
     nearestParkDistance.frame = CGRectMake(0,  0 + count * 50, self.view.frame.size.width, 30);
     addParkBtn.frame = CGRectMake(300,  0 + count * 50, 30, 30);
     viewParkBtn.frame = CGRectMake(335,  0 + count * 50, 30, 30);
     
     }
     else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
     {
     nearestPark.font = [UIFont fontWithName:@"Open Sans" size:16];
     nearestPark.frame = CGRectMake(5, 0 + count * 50, 140, 30);
     nearestParkBg.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:16];
     nearestParkDistance.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     addParkBtn.frame = CGRectMake(325, 0 + count * 50, 30, 30);
     viewParkBtn.frame = CGRectMake(360, 0 + count * 50, 30, 30);
     } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
     {
     nearestPark.font = [UIFont fontWithName:@"Open Sans" size:16];
     nearestPark.frame = CGRectMake(5, 0 + count * 50, 140, 30);
     nearestParkBg.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     nearestParkDistance.font = [UIFont fontWithName:@"Open Sans" size:16];
     nearestParkDistance.frame = CGRectMake(0, 0 + count * 50, self.view.frame.size.width, 30);
     addParkBtn.frame = CGRectMake(325, 0 + count * 50, 30, 30);
     viewParkBtn.frame = CGRectMake(360, 0 + count * 50, 30, 30);
     }
     nearestPark.textAlignment = NSTextAlignmentLeft;
     nearestParkDistance.textAlignment = NSTextAlignmentCenter;
     nearestParkDistance.textContainerInset = UIEdgeInsetsMake(5, 0, 0, 5);
     if(count % 2 == 0) {
     nearestParkBg.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
     }
     nearestParkDistance.backgroundColor = [UIColor clearColor];
     nearestPark.text = object[@"Location"];
     nearestParkDistance.text = [NSString stringWithFormat:@"%.2f miles", [[collectedDistances objectAtIndex:i] floatValue]];
     
     [addParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
     [addParkBtn setImage:[UIImage imageNamed:@"btn_addhome"] forState:UIControlStateNormal];
     [addParkBtn addTarget:self action:@selector(tapAddParkBtn:) forControlEvents:UIControlEventTouchUpInside];
     [viewParkBtn setTitle:[object objectId] forState:UIControlStateNormal];
     [viewParkBtn setImage:[UIImage imageNamed:@"btn_map"] forState:UIControlStateNormal];
     [viewParkBtn addTarget:self action:@selector(tapViewParkBtn:) forControlEvents:UIControlEventTouchUpInside];
     
     [pageScroller2 addSubview:nearestParkBg];
     [pageScroller2 addSubview:nearestPark];
     
     [pageScroller2 addSubview:nearestParkDistance];
     [pageScroller2 addSubview:addParkBtn];
     [pageScroller2 addSubview:viewParkBtn];
     count++;
     
     
     
     if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
     {
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller2.frame.size.height + count * 60 + 100);
     
     } else if ([[UIScreen mainScreen] bounds].size.height == 568){
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller2.frame.size.height + count * 55 + 100);
     } else {
     pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller2.frame.size.height + count * 51 - 100);
     }
     
     [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
     pageScroller2.contentOffset = CGPointMake(0, distanceMovedScroll);
     } completion:NULL];
     
     
     
     }
     } else {
     // Log details of the failure
     NSLog(@"Error: %@ %@", error, [error userInfo]);
     }
     [Hud removeFromSuperview];
     }];    }
     
     
     */
    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if (currentLocation != nil) {
        [self showLoading];
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        NSLog(@"Longitude: %@",[NSString stringWithFormat:@"%.8f",currentLocation.coordinate.longitude]);
        NSLog(@"Latitude: %@",[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude]);
        NSLog(@"AUTO FIND ACTIVATED");
        
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
                        NSLog(@"THIS IS YOUR CURRENT HOME PARK DO NOTHING");
                        [Hud removeFromSuperview];
                        [self tapExerciseBar:self];
                        break;
                    } else {
                        NSString *parkName = object[@"Location"];
                        currentLocationID = [object objectId];
                        
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
                        updateText.text = [NSString stringWithFormat:@"Are you at %@?", parkName];
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
    }
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
    NSString *tmp = sender.titleLabel.text;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Home Park", nil)
                                                                   message:NSLocalizedString(@"Are you sure you want to select this as your home park?", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Choose Park", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              PFQuery *homeParkQuery = [PFUser query];
                                                              [homeParkQuery getFirstObjectInBackgroundWithBlock:^(PFObject * object, NSError *error) {
                                                                  if (!error) {
                                                                      NSLog(@"TODAY %@", tmp);
                                                                      [PFUser currentUser][@"HomePark"] = tmp;
                                                                      
                                                                      [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                          
                                                                          alertVC = [[CustomAlert alloc] init];
                                                                          [alertVC loadSingle:self.view:NSLocalizedString(@"Updated", nil):NSLocalizedString(@"You've successfully updated your home park!", nil)];
                                                                          [alertVC.alertView removeFromSuperview];
                                                                          
                                                                      }];
                                                                      
                                                                  } else {
                                                                      
                                                                      NSLog(@"Failed to get home park query");
                                                                  }
                                                              }];
                                                              
                                                              
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}


-(void)setExercisesAndWorkoutGrid:(NSArray*) objects :(NSArray*) favouriteID: (NSArray*) mostUsedList : (int) greyoutCount{
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 90 - 200);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    } else {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + objects.count * 85 - 200);
    }
    
    int count = 0;
    for (PFObject *object in objects) {
        UIButton *exerciseBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        } else {
            [exerciseBtn setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        [exerciseBtn setTitle:[object objectId] forState:UIControlStateNormal];
        exerciseBtn.titleLabel.layer.opacity = 0.0f;
        if(greyoutCount < 0 || (greyoutCount >= 0 && count < greyoutCount)) {
            [exerciseBtn setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
            if(isExercisesPage) {
                [exerciseBtn addTarget:self action:@selector(clickParticularExercise:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [exerciseBtn addTarget:self action:@selector(clickParticularWorkout:) forControlEvents:UIControlEventTouchUpInside];
            }
        } else {
            [exerciseBtn setBackgroundColor:[UIColor grayColor]];
        }
        [pageScroller addSubview:exerciseBtn];
        
        //Exercise Bar Label
        UILabel *title;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 130 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 130 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(80, 127 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 130 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 130 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 130 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        
        title.textColor = [UIColor blackColor];
        title.numberOfLines = 2;
        title.textAlignment = NSTextAlignmentCenter;
        if([object objectForKey:@"ExerciseName"] != nil) {
            title.text = [object objectForKey:@"ExerciseName"];
        } else {
            title.text = [object objectForKey:@"WorkoutName"];
        }
        [pageScroller addSubview:title];
        
        //Exercise Bar Button Star
        
        UIButton *starBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [starBtn setFrame:CGRectMake(self.view.frame.size.width - 50, 150 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [starBtn setFrame:CGRectMake(self.view.frame.size.width - 50, 150 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [starBtn setFrame:CGRectMake(320, 150 + count*90, 20, 20)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [starBtn setFrame:CGRectMake(320, 150 + count*90, 20, 20)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [starBtn setFrame:CGRectMake(320, 150 + count*90, 20, 20)];
        } else {
            [starBtn setFrame:CGRectMake(320, 150 + count*90, 20, 20)];
        }
        
        if (isExercisesPage) {
            [starBtn setTitle:[object objectId] forState:UIControlStateNormal];
            if ([favouriteID count] == 0 || ![favouriteID containsObject:[object objectId]]) {
                [starBtn setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(starButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [starBtn setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(starButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            }
        } else {
            [starBtn setTitle:[object objectId] forState:UIControlStateNormal];
            if ([favouriteID count] == 0 || ![favouriteID containsObject:[object objectId]]) {
                [starBtn setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(workoutStarButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                [starBtn setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
                [starBtn addTarget:self action:@selector(workoutStarButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        [pageScroller addSubview:starBtn];
        
        if(mostUsedList != nil) {
            UILabel *numRepeat;
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 107, 130 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 107, 125 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 115, 130 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:12];
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 130 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 130 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            } else {
                numRepeat = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 140, 130 + count*90, 100, 15)];
                numRepeat.font = [UIFont fontWithName:@"ethnocentric" size:14];
            }
            
            numRepeat.textColor = [UIColor blackColor];
            numRepeat.numberOfLines = 2;
            //numRepeat.backgroundColor = [UIColor yellowColor];
            numRepeat.textAlignment = NSTextAlignmentRight;
            numRepeat.text = [NSString stringWithFormat:@"%d",[[mostUsedList objectAtIndex:count] intValue]];
            [pageScroller addSubview:numRepeat];
            
            UIImageView *repImg= [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35, 154 + count*90, 40, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35, 154 + count*90, 40, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30, 154 + count*90, 15, 15)];
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 154 + count*90, 40, 15)];
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 154 + count*90, 40, 15)];
            } else {
                repImg = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70, 154 + count*90, 40, 15)];
            }
            repImg.image = [UIImage imageNamed:@"ic_reps"];
            repImg.contentMode = UIViewContentModeScaleAspectFit;
            repImg.clipsToBounds = YES;
            [pageScroller addSubview:repImg];
        }
        
        //Image Thumbnail
        UIImageView *brandedImg = [[UIImageView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
        } else {
            brandedImg.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
        }
        CALayer *imageLayer = brandedImg.layer;
        [imageLayer setCornerRadius:5];
        [imageLayer setBorderWidth:1];
        [brandedImg.layer setCornerRadius:brandedImg.frame.size.width/2];
        [imageLayer setMasksToBounds:YES];
        brandedImg.layer.borderWidth = 2.0f;
        brandedImg.layer.borderColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0].CGColor;
        
        if ([object objectForKey:@"BrandImage"] != nil) {
            NSLog(@"BRANDED WORKERT");
            PFFile *imageFile = [object objectForKey:@"BrandImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    brandedImg.image = [UIImage imageWithData:data];
                    
                    [pageScroller addSubview:brandedImg];
                });
            });
            
            UIButton *hoverBtn = [[UIButton alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            } else {
                hoverBtn.frame = CGRectMake(25, 145 + count*85, 50, 50); //Image scaled
            }
            [hoverBtn setTitle:[object objectId] forState:UIControlStateNormal];
            hoverBtn.titleLabel.layer.opacity = 0.0f;
            [hoverBtn addTarget:self action:@selector(btnBrandedWorkout:) forControlEvents:UIControlEventTouchUpInside];
            [pageScroller addSubview:hoverBtn];
            
        } else if ([object objectForKey:@"WorkoutName"] != nil){
            //Exercise Bar Arrows Image
            UIImageView *arrowImage = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                arrowImage.frame = CGRectMake(25, 145 + count*90, 35, 35);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                arrowImage.frame = CGRectMake(25, 145 + count*90, 35, 35);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                arrowImage.frame = CGRectMake(25, 140 + count*90, 41, 41);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                arrowImage.frame = CGRectMake(30, 140 + count*90, 41, 41);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                arrowImage.frame = CGRectMake(30, 140 + count*90, 41, 41);
            } else {
                arrowImage.frame = CGRectMake(30, 140 + count*90, 41, 41);
            }
            arrowImage.image = [UIImage imageNamed:@"arrows"];
            [pageScroller addSubview:arrowImage];
            
        } else {
            //Exercise Bar Arrows Image
            UIImageView *arrowImage = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            } else {
                arrowImage.frame = CGRectMake(15, 130 + count*90, 60, 60);
            }
            arrowImage.layer.cornerRadius = arrowImage.frame.size.width / 2;
            arrowImage.clipsToBounds = YES;
            arrowImage.contentMode = UIViewContentModeScaleAspectFill;
            arrowImage.clipsToBounds = YES;
            PFFile *imageFile = object[@"ExerciseImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    arrowImage.image =  [UIImage imageWithData:data];
                    
                });
            });
            [pageScroller addSubview:arrowImage];
            
        }
        
        count++;
    }
    [Hud removeFromSuperview];
}
-(IBAction)starButtonToggledUp:(UIButton *)sender
{
    [self showLoading];
    NSString *tmp = sender.titleLabel.text;
    [[PFUser currentUser] addObject:tmp forKey:@"FavouriteExercises"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [sender setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
            [sender removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [sender addTarget:self action:@selector(starButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            
            
        } else {
            // There was a problem, check error.description
        }
        [Hud removeFromSuperview];
    }];
    
}
-(IBAction)starButtonToggledDown:(UIButton *)sender
{
    [self showLoading];
    NSString *tmp = sender.titleLabel.text;
    [[PFUser currentUser] removeObject:tmp forKey:@"FavouriteExercises"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [sender setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
            [sender removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [sender addTarget:self action:@selector(starButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            // There was a problem, check error.description
        }
        [Hud removeFromSuperview];
    }];
}
-(IBAction)btnBrandedWorkout:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    
    PFQuery *query = [PFQuery queryWithClassName:@"PresetWorkouts"];
    [query whereKey:@"objectId" equalTo:tmp];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            floatView = [[UIView alloc] init];
            floatView.frame = CGRectMake(30, 175 + self.view.frame.size.height, self.view.frame.size.width - 60, self.view.frame.size.height - 350);
            floatView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:0.9];
            [self.view addSubview:floatView];
            
            UILabel *brandName = [[UILabel alloc] init];
            brandName.frame = CGRectMake(20, 0, floatView.frame.size.width - 40, 50);
            brandName.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
            brandName.numberOfLines = 1;
            brandName.textColor = [UIColor blackColor];
            brandName.textAlignment = NSTextAlignmentCenter;
            brandName.text = object[@"BrandName"];
            [floatView addSubview:brandName];
            
            UILabel *brandDesc = [[UILabel alloc] init];
            brandDesc.frame = CGRectMake(20, 220, floatView.frame.size.width - 40, 60);
            brandDesc.font = [UIFont fontWithName:@"OpenSans" size:10];
            brandDesc.numberOfLines = 4;
            brandDesc.textColor = [UIColor blackColor];
            brandDesc.textAlignment = NSTextAlignmentCenter;
            brandDesc.text = object[@"WorkoutDescription"];
            [floatView addSubview:brandDesc];
            
            //Image Thumbnail
            UIImageView *brandedImg = [[UIImageView alloc] init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
            } else {
                brandedImg.frame = CGRectMake(25, 50, floatView.frame.size.width - 60, 150); //Image scaled
            }
            PFFile *imageFile = [object objectForKey:@"BrandImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    brandedImg.image = [UIImage imageWithData:data];
                    
                    [floatView addSubview:brandedImg];
                });
            });
            
            UIButton *quitFloat = [UIButton buttonWithType:UIButtonTypeCustom];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
            {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
            {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
            } else {
                quitFloat.frame = CGRectMake(10, 10, 20, 20);//Position of the button
            }
            [quitFloat setBackgroundImage:[UIImage imageNamed:@"ic_x"] forState:UIControlStateNormal];
            [quitFloat addTarget:self action:@selector(quitFloat) forControlEvents:UIControlEventTouchUpInside];
            
            [floatView addSubview:quitFloat];
            
            CGRect newFrame = floatView.frame;
            newFrame.origin.y -= self.view.frame.size.height;
            
            [UIView animateWithDuration:0.9
                             animations:^{
                                 floatView.frame = newFrame;
                             }];
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(void) quitFloat {
    CGRect newFrame = floatView.frame;
    newFrame.origin.y += self.view.frame.size.height;
    
    [UIView animateWithDuration:0.9
                     animations:^{
                         floatView.frame = newFrame;
                     }];
}

-(IBAction)tapMostUsedBar:(id)sender
{
    [noDataView removeFromSuperview];
    
    isExercisesPage = TRUE;
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [self showLoading];
    // @"exerciseObjId",  @"exerciseNumRepeat"
    NSArray *data = [[DBManager getSharedInstance]showTable];
    NSMutableArray *repeatArray = [[NSMutableArray alloc]init];
    NSMutableArray *objectIds = [[NSMutableArray alloc]init];
    if(data!= nil) {
        //NSMutableArray *subQueries = [[NSMutableArray alloc] init];
        for(int i = 0; i < [data count]; i++) {
            NSDictionary *tmp = [data objectAtIndex:i];
            [repeatArray addObject:[NSNumber numberWithInt:[tmp[@"exerciseNumRepeat"] intValue]]];
            [objectIds addObject: tmp[@"exerciseObjId"]];
            
            //NSPredicate *predicate= [NSPredicate predicateWithFormat:@"objectId = %@", tmp[@"exerciseObjId"]];
            //[subQueries addObject:predicate];
        }
        //NSPredicate *predicateTotal = [NSCompoundPredicate orPredicateWithSubpredicates:subQueries];
        PFQuery * ORquery = [PFQuery queryWithClassName:@"Exercises"];
        [ORquery whereKey:@"objectId" containedIn:objectIds];
        //[ORquery orderByAscending:@"ExerciseName"];
        [ORquery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
            if(!error) {
                NSMutableArray *arrangedList = [[NSMutableArray alloc]init];
                for(int j = 0; j < [objectIds count]; j++) {
                    for(int k = 0; k < [results count]; k++) {
                        if([[objectIds objectAtIndex:j] isEqualToString:[[results objectAtIndex:k] objectId]]) {
                            [arrangedList addObject:[results objectAtIndex:k]];
                        }
                    }
                }
                [self setExercisesAndWorkoutGrid:arrangedList : [PFUser currentUser][@"FavouriteExercises"]: repeatArray : -1];
            } else {
            }
            [Hud removeFromSuperview];
            
        }];
    } else {
        [Hud removeFromSuperview];
    }
    
}
-(IBAction)tapMyExercisesBar:(id)sender
{
    isExercisesPage = TRUE;
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [self showLoading];
    
    if(!([[PFUser currentUser][@"FavouriteExercises"] count] == 0)) {
        //QUERY FOR GETTING MY EXERCISES
        PFQuery * browseMyQuery = [PFQuery queryWithClassName:@"Exercises"];
        [browseMyQuery orderByAscending:@"ExerciseName"];
        [browseMyQuery whereKey:@"objectId" containedIn:[PFUser currentUser][@"FavouriteExercises"]];
        [browseMyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error) {
                 collectedExercises = objects;
                 [self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteExercises"]: nil : -1];
                 
             } else {
                 [Hud removeFromSuperview];
             }
         }];
    } else {
        
        noDataView = [[UIView alloc] init];
        noDataView.frame = CGRectMake(0, 194, self.view.frame.size.width, 200);
        
        [self.view addSubview:noDataView];
        
        UILabel *friendsLabel = [[UILabel alloc] init];
        friendsLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 90);
        friendsLabel.text = NSLocalizedString(@"You have not favourited any exercises yet!", nil);
        friendsLabel.textAlignment = NSTextAlignmentCenter;
        friendsLabel.numberOfLines = 3;
        friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        
        [noDataView addSubview:friendsLabel];
        
        collectedExercises = [[NSArray alloc] init];
        for(UIView *subview in [pageScroller subviews]) {
            [subview removeFromSuperview];
        }
        [Hud removeFromSuperview];
    }
}

-(IBAction)workoutStarButtonToggledUp:(UIButton *)sender
{
    [self showLoading];
    NSString *tmp = sender.titleLabel.text;
    [[PFUser currentUser] addObject:tmp forKey:@"FavouriteWorkouts"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [sender setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
            [sender removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [sender addTarget:self action:@selector(workoutStarButtonToggledDown:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            // There was a problem, check error.description
        }
        [Hud removeFromSuperview];
    }];
    
}
-(IBAction)workoutStarButtonToggledDown:(UIButton *)sender
{
    [self showLoading];
    NSString *tmp = sender.titleLabel.text;
    [[PFUser currentUser] removeObject:tmp forKey:@"FavouriteWorkouts"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [sender setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
            [sender removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [sender addTarget:self action:@selector(workoutStarButtonToggledUp:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            // There was a problem, check error.description
        }
        [Hud removeFromSuperview];
    }];
}

-(IBAction)tapWorkoutBar:(id)sender
{
    [noDataView removeFromSuperview];
    
    [self showLoading];
    isExercisesPage = FALSE;
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    PFQuery *parkWorkoutQuery = [PFQuery queryWithClassName:@"Locations"];
    [parkWorkoutQuery whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
    [parkWorkoutQuery getFirstObjectInBackgroundWithBlock:^(PFObject *obj, NSError *error) {
        if(!error) {
            NSLog(@"Location Park Query2: %@", obj[@"WorkoutIds"]);
            //QUERY FOR GETTING ALL EXERCISES
            PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"PresetWorkouts"];
            [browseAllQuery orderByAscending:@"WorkoutName"];
            [browseAllQuery whereKey:@"objectId" containedIn:obj[@"WorkoutIds"]];
            [browseAllQuery whereKey:@"EasyMedHard" notEqualTo:@YES];
            [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
             {
                 if (!error) {
                     collectedExercises = objects;
                     [self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteWorkouts"]: nil: -1];
                 } else {
                     [Hud removeFromSuperview];
                 }
             }];
        } else {
            [Hud removeFromSuperview];
            noDataView = [[UIView alloc] init];
            noDataView.frame = CGRectMake(0, 130, self.view.frame.size.width, self.view.frame.size.height);
            
            [self.view addSubview:noDataView];
            
            UILabel *friendsLabel = [[UILabel alloc] init];
            friendsLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 200);
            friendsLabel.text = NSLocalizedString(@"You need to select a home park below to find workouts!", nil);
            friendsLabel.textAlignment = NSTextAlignmentCenter;
            friendsLabel.numberOfLines = 5;
            friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            
            [noDataView addSubview:friendsLabel];
            
            if([[PFUser currentUser][@"HomePark"]  isEqual: @"NotSelected"]) {
                //Add Home Park
                UIButton *addHomeParkButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    addHomeParkButton.frame = CGRectMake(75, 250, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                } else {
                    addHomeParkButton.frame = CGRectMake(90, 250, self.view.frame.size.width-180, 40);//Position of the button
                }
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if([language containsString:@"fr"]) {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choosepark_french"] forState:UIControlStateNormal];
                } else {
                    [addHomeParkButton setBackgroundImage:[UIImage imageNamed:@"btn_choose"] forState:UIControlStateNormal];
                }
                [addHomeParkButton addTarget:self action:@selector(addHomePark:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:addHomeParkButton];
                
            } else {
                // Find nearest Park
                isFindingNearestParkOn = false;
                findParksButton = [UIButton buttonWithType:UIButtonTypeCustom];
                //[findParksButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 100.0, 100.0)];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width-150, 30);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    findParksButton.frame = CGRectMake(75, 150, self.view.frame.size.width - 150, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                } else {
                    findParksButton.frame = CGRectMake(90, 150, self.view.frame.size.width - 180, 40);//Position of the button
                }
                [findParksButton setBackgroundImage:[UIImage imageNamed:@"btn_nearestpark_2"] forState:UIControlStateNormal];
                [findParksButton addTarget:self action:@selector(tapfindNearestParksButton:) forControlEvents:UIControlEventTouchUpInside];
                
                [noDataView addSubview:findParksButton];
                
            }
            
            [Hud removeFromSuperview];
            NSLog(@"Location Park Query Failed");
        }
        
    }];
}

-(IBAction)tapMostUsedWorkoutBar:(id)sender
{
    [noDataView removeFromSuperview];
    
    isExercisesPage = FALSE;
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [self showLoading];
    // @"exerciseObjId",  @"exerciseNumRepeat"
    NSArray *data = [[DBManager getSharedInstance]showTable];
    NSMutableArray *repeatArray = [[NSMutableArray alloc]init];
    NSMutableArray *objectIds = [[NSMutableArray alloc]init];
    if(data!= nil) {
        for(int i = 0; i < [data count]; i++) {
            NSDictionary *tmp = [data objectAtIndex:i];
            [repeatArray addObject:[NSNumber numberWithInt:[tmp[@"exerciseNumRepeat"] intValue]]];
            [objectIds addObject: tmp[@"exerciseObjId"]];
        }
        __block int isRunning = 0;
        NSMutableArray *arrangedList = [[NSMutableArray alloc]init];
        for (int i = 0; i < [objectIds count]; i++) {
            NSString *objId = [objectIds objectAtIndex:i];
            PFQuery * ORquery = [PFQuery queryWithClassName:@"PresetWorkouts"];
            [ORquery whereKey:@"ExerciseIds" containsString:objId];
            //[ORquery orderByAscending:@"ExerciseName"];
            [ORquery getFirstObjectInBackgroundWithBlock:^(PFObject *tmp, NSError *error) {
                if(!error) {
                    isRunning++;
                    [arrangedList addObject:tmp];
                } else {
                    isRunning++;
                }
                if(isRunning == [objectIds count]) {
                    [self setExercisesAndWorkoutGrid:arrangedList : [PFUser currentUser][@"FavouriteExercises"]: nil: -1];
                    [Hud removeFromSuperview];
                }
                
            }];
        }
        [Hud removeFromSuperview];
    } else {
        [Hud removeFromSuperview];
    }
}
-(IBAction)tapMyRoutinesBar:(id)sender
{
    isExercisesPage = FALSE;
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [self showLoading];
    
    if(!([[PFUser currentUser][@"FavouriteWorkouts"] count] == 0)) {
        //QUERY FOR GETTING MY EXERCISES
        PFQuery * browseMyQuery = [PFQuery queryWithClassName:@"PresetWorkouts"];
        [browseMyQuery orderByAscending:@"WorkoutName"];
        [browseMyQuery whereKey:@"objectId" containedIn:[PFUser currentUser][@"FavouriteWorkouts"]];
        [browseMyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error) {
                 collectedExercises = objects;
                 [self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteWorkouts"]: nil :-1];
                 
                 
             } else {
                 [Hud removeFromSuperview];
             }
         }];
    } else {
        collectedExercises = [[NSArray alloc] init];
        for(UIView *subview in [pageScroller subviews]) {
            [subview removeFromSuperview];
        }
        noDataView = [[UIView alloc] init];
        noDataView.frame = CGRectMake(0, 194, self.view.frame.size.width, 200);
        
        [self.view addSubview:noDataView];
        
        UILabel *friendsLabel = [[UILabel alloc] init];
        friendsLabel.frame = CGRectMake(30, 100, self.view.frame.size.width - 60, 90);
        friendsLabel.text = NSLocalizedString(@"You have not favourited any workouts yet!", nil);
        friendsLabel.textAlignment = NSTextAlignmentCenter;
        friendsLabel.numberOfLines = 3;
        friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        
        [noDataView addSubview:friendsLabel];
        [Hud removeFromSuperview];
    }
}
//CLICK EVENTS
- (void)enterParticularExercise:(NSString*) typeOfExercise: (NSString*) objectId{
    [self showLoading];
    __block BrowseAllDetailController *browseDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"ExerciseDetailClicked"];
    __block StopwatchViewController *stopwatch = [self.storyboard instantiateViewControllerWithIdentifier:@"StopwatchViewController"];
    //QUERY FOR GETTING MY EXERCISES
    PFQuery *exercise = [PFQuery queryWithClassName:@"Exercises"];
    [exercise whereKey:@"objectId" equalTo:objectId];
    [exercise getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
            [Hud removeFromSuperview];
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object.");
            browseDetail.exerciseObject = object;
            //EXERCISE INFORMATION LABELS
            browseDetail.setSetsLabelString = [object[typeOfExercise] objectAtIndex:0];
            browseDetail.setRepsLabelString = [object[typeOfExercise]  objectAtIndex:1];
            browseDetail.weightLabelString = [object[typeOfExercise]  objectAtIndex:2];
            
            int timeInMinute = [[object[typeOfExercise]  objectAtIndex:3] intValue]/(1000*60);
            int timeInSecond = [[object[typeOfExercise]  objectAtIndex:3] intValue]/1000 - timeInMinute*60;
            browseDetail.setTimeLabelString = [NSString stringWithFormat:@"%02d:%02d",timeInMinute, timeInSecond];
            timeInMinute = [[object[typeOfExercise]  objectAtIndex:4] intValue]/(1000*60);
            timeInSecond = [[object[typeOfExercise]  objectAtIndex:4] intValue]/1000 - timeInMinute*60;
            browseDetail.restTimeLabelString = [NSString stringWithFormat:@"%02d:%02d",timeInMinute, timeInSecond];
            
            
            browseDetail.setAltLabelString = [object[typeOfExercise]  objectAtIndex:6];
            browseDetail.exerciseLabelString = object[@"ExerciseName"];
            browseDetail.descLabelString = object[@"Description"];
            browseDetail.URLString = object[@"VideoURL"];
            browseDetail.typeOfExercise = typeOfExercise;
            
            //SCHOOL OF CALISTHENICS
            browseDetail.socLesson = object[@"socLesson"];
            browseDetail.socChallenge = object[@"socChallenge"];
            browseDetail.socExercise = object[@"socExercise"];
            
            //QUERY FOR GETTING THUMBNAIL IMAGE
            PFQuery *imageQuery = [PFQuery queryWithClassName:@"Exercises"];
            [imageQuery orderByAscending:@"ExerciseName"];
            [imageQuery findObjectsInBackgroundWithBlock:^(NSArray *imageObjects, NSError *error) {
                if (!error) {
                    PFFile *imageFile = object[@"ExerciseImage"];
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        
                        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                        if ( data == nil )
                            return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[activityView1 stopAnimating];
                            //[activityView1 removeFromSuperview];
                            browseDetail.imageView.image =  [UIImage imageWithData:data];
                            
                        });
                    });
                    PFFile *imageFile2 = object[@"MuscleGroupImage"];
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        
                        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile2.url]]];
                        if ( data == nil )
                            return;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //[activityView1 stopAnimating];
                            //[activityView1 removeFromSuperview];
                            stopwatch.imageView.image =  [UIImage imageWithData:data];
                            
                        });
                    });
                }
            }];
            [self.navigationController pushViewController:browseDetail animated:YES];
            
            [Hud removeFromSuperview];
        }
    }];
    
}
-(IBAction)clickParticularExercise:(UIButton *) sender{
    /*
     */
    
    [self showLoading];
    PFQuery *exerciseQuery = [PFQuery queryWithClassName:@"Exercises"];
    [exerciseQuery whereKey:@"objectId" equalTo:sender.titleLabel.text];
    [exerciseQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if([object[@"Multiuse"] boolValue]) {
                
                NSArray *multiuseExercises = object[@"MultiuseArray"];
                
                PFQuery *exerciseQuery2 = [PFQuery queryWithClassName:@"Exercises"];
                [exerciseQuery2 whereKey:@"objectId" containedIn:multiuseExercises];
                [exerciseQuery2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        //[self setExercisesAndWorkoutGrid:objects : [PFUser currentUser][@"FavouriteExercises"]: nil];
                        UIAlertController * view=   [UIAlertController
                                                     alertControllerWithTitle:NSLocalizedString(@"Exercise", nil)
                                                     message:NSLocalizedString([object[@"ExerciseName"] uppercaseString], nil)
                                                     preferredStyle:UIAlertControllerStyleActionSheet];
                        for (PFObject *obj in objects) {
                            
                            
                            UIAlertAction* tmp = [UIAlertAction
                                                  actionWithTitle:NSLocalizedString(obj[@"ExerciseName"], nil)
                                                  style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action)
                                                  {
                                                      //Do some thing here
                                                      [view dismissViewControllerAnimated:YES completion:nil];
                                                      
                                                      
                                                      [self enterParticularExercise: @"Endurance": [obj objectId]];
                                                      
                                                  }];
                            [view addAction:tmp];
                        }
                        UIAlertAction* cancel = [UIAlertAction
                                                 actionWithTitle:@"Cancel"
                                                 style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action)
                                                 {
                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                     
                                                 }];
                        [view addAction:cancel];
                        [self presentViewController:view animated:YES completion:nil];
                        [Hud removeFromSuperview];
                    } else {
                        NSLog(@"The request failed.");
                        [Hud removeFromSuperview];
                    }
                }];
            } else if([object[@"socWorkout"] boolValue]) {
                
                PFQuery * ORquery = [PFQuery queryWithClassName:@"Exercises"];
                [ORquery orderByAscending:@"ExerciseName"];
                [ORquery whereKey:@"objectId" containedIn:object[@"socArray"]];
                [ORquery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
                    if(!error) {
                        [self setExercisesAndWorkoutGrid:results : [PFUser currentUser][@"FavouriteExercises"]: nil: -1];
                    } else {
                        
                    }
                    [Hud removeFromSuperview];
                    
                }];
                
            } else {
                UIAlertController * view=   [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"Style", nil)
                                             message:NSLocalizedString(@"Choose your style", nil)
                                             preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction* endurance = [UIAlertAction
                                            actionWithTitle:NSLocalizedString(@"Endurance", nil)
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action)
                                            {
                                                //Do some thing here
                                                [view dismissViewControllerAnimated:YES completion:nil];
                                                
                                                
                                                [self enterParticularExercise: @"Endurance": sender.titleLabel.text];
                                                
                                            }];
                UIAlertAction* fitness = [UIAlertAction
                                          actionWithTitle:NSLocalizedString(@"Fitness", nil)
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * action)
                                          {
                                              //Do some thing here
                                              [view dismissViewControllerAnimated:YES completion:nil];
                                              
                                              
                                              [self enterParticularExercise:@"Fitness": sender.titleLabel.text];
                                              
                                          }];
                
                UIAlertAction* muscle = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Muscle", nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             //Do some thing here
                                             [view dismissViewControllerAnimated:YES completion:nil];
                                             
                                             
                                             [self enterParticularExercise:@"Muscle": sender.titleLabel.text];
                                             
                                         }];
                
                
                
                UIAlertAction* cancel = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             [view dismissViewControllerAnimated:YES completion:nil];
                                             
                                         }];
                
                
                [view addAction:endurance];
                [view addAction:fitness];
                [view addAction:muscle];
                [view addAction:cancel];
                [self presentViewController:view animated:YES completion:nil];
                
                [Hud removeFromSuperview];
                
            }
        } else {
            
        }}];
    
}

-(IBAction)clickParticularWorkout:(UIButton *) sender{
    [self showLoading];
    isExercisesPage = YES;
    PFQuery *exerciseQuery = [PFQuery queryWithClassName:@"PresetWorkouts"];
    [exerciseQuery whereKey:@"objectId" equalTo:sender.titleLabel.text];
    [exerciseQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            
            exercises = object[@"ExerciseIds"];
            /* NSMutableArray *subQueries = [[NSMutableArray alloc] init];
             for (int i = 0; i < [exercises count]; i++) {
             NSPredicate *predicate= [NSPredicate predicateWithFormat:@"objectId = %@", exercises[i]];
             [subQueries addObject:predicate];
             }
             NSPredicate *predicateTotal = [NSCompoundPredicate orPredicateWithSubpredicates:subQueries];
             PFQuery * ORquery = [PFQuery queryWithClassName:@"Exercises" predicate:predicateTotal];
             [ORquery orderByAscending:@"ExerciseName"];
             [ORquery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
             if(!error) {
             [self setExercisesAndWorkoutGrid:results : [PFUser currentUser][@"FavouriteExercises"]: nil];
             } else {
             
             }
             [Hud removeFromSuperview];
             
             }]; */
            PFQuery * ORquery = [PFQuery queryWithClassName:@"Exercises"];
            [ORquery orderByAscending:@"ExerciseName"];
            [ORquery whereKey:@"objectId" containedIn:exercises];
            [ORquery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
                if(!error) {
                    [self setExercisesAndWorkoutGrid:results : [PFUser currentUser][@"FavouriteExercises"]: nil: -1];
                } else {
                    
                }
                [Hud removeFromSuperview];
                
            }];
        } else {
            NSLog(@"The getFirstObject request failed.");
            [Hud removeFromSuperview];
        }
    }];
}
-(void) viewWillAppear:(BOOL)animated {
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
}
/*-(void)viewDidAppear:(BOOL)animated{
 [super viewWillAppear:YES];
 self.automaticallyAdjustsScrollViewInsets = NO;
 
 //self.navigationController.navigationBar.hidden = NO;
 }*/
- (void)viewDidUnload {
    [self setSearchBar:nil];
    [self setSearchBarController:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
            static dispatch_once_t onceToken;
            
            dispatch_once (&onceToken, ^{
                
                alertVC = [[CustomAlert alloc] init];
                [alertVC loadSingle:self.view:NSLocalizedString(@"Data Warning", nil):NSLocalizedString(@"You're currently not connected to Wi-Fi watching exercise videos may consume a lot of your data. You can restrict this in your phone's settings.", nil)];
                [alertVC.alertView removeFromSuperview];
                
            });
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
    if(range.length + range.location > textField.text.length)
    {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return newLength <= 10;
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


//Handles how to hide the keyboard
- (void) keyboardWillHide:(NSNotification *)notification {
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    pageScroller.contentInset = contentInsets;
    pageScroller.scrollIndicatorInsets = contentInsets;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //    background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height);
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

-(void)resetData
{
    if(isExercisesPage) {
        [self setExercisesAndWorkoutGrid:collectedExercises : [PFUser currentUser][@"FavouriteExercises"]:nil:-1];
    } else {
        [self setExercisesAndWorkoutGrid:collectedExercises : [PFUser currentUser][@"FavouriteWorkouts"]: nil:-1];
    }
}
- (void)searchTableList
{
    NSMutableArray *tmp = [NSMutableArray array];;
    NSString *searchString = searchBar.text;
    NSLog(@"Search Text %@",searchBar.text);
    if(isExercisesPage) {
        for (PFObject *object in collectedExercises) {
            if([object[@"ExerciseName"] containsString:searchString]) {
                [tmp addObject:object];
            }
        }
        [self setExercisesAndWorkoutGrid:tmp : [PFUser currentUser][@"FavouriteExercises"]:nil:-1];
    } else {
        for (PFObject *object in collectedExercises) {
            if([object[@"WorkoutName"] containsString:searchString]) {
                [tmp addObject:object];
            }
        }
        [self setExercisesAndWorkoutGrid:tmp : [PFUser currentUser][@"FavouriteWorkouts"]:nil:-1];
    }
    
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBarControl {
    isSearching = YES;
    [searchBarControl setShowsCancelButton:YES animated:YES];
}


- (void)searchBar:(UISearchBar *)searchBarObject textDidChange:(NSString *)searchText {
    NSLog(@"Text change - %d",isSearching);
    
    //Remove all objects first.
    [filteredContentList removeAllObjects];
    
    if([searchText length] != 0) {
        isSearching = YES;
        [self searchTableList];
    }
    else {
        isSearching = NO;
        [self resetData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBarObject {
    NSLog(@"Cancel clicked");
    [searchBarObject resignFirstResponder];
    [searchBarObject setShowsCancelButton:NO animated:YES];
    [self resetData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBarObject {
    NSLog(@"Search Clicked");
    [self searchTableList];
    [searchBarObject resignFirstResponder];
}

//Handles how the keyboard is shown
- (void)keyboardWasShown:(NSNotification *)notification
{
    
    //Get the size of the keyboard.
    //CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //Adjust the bottom content inset of the scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    pageScroller.contentInset = contentInsets;
    pageScroller.scrollIndicatorInsets = contentInsets;
    
    
    //Scrolls the target text field into view.
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(aRect, searchBar.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, searchBar.frame.origin.y - (keyboardSize.height-15));
        //        background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/1.14, self.view.frame.size.width, self.view.frame.size.height);
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [pageScroller setContentOffset:scrollPoint animated:YES];
        
    }
    
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
    
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Exercises"];
    
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
-(IBAction)tapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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



-(void)tapYesBtn {
    [UIView animateWithDuration:0.4f animations:^{
        [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 175)];
        homeParkView.alpha = 0;
    }];
    isHomePark = NO;
    [self tapExerciseBarNotAtYourHomePark];
}

-(void)tapNoBtn {
    [UIView animateWithDuration:0.4f animations:^{
        [homeParkView setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, 175)];
        homeParkView.alpha = 0;
    }];
    isHomePark = YES;
    
    [self tapExerciseBar:self];
}
@end
