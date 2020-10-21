//
//  FAQViewController.m
//  Proludic
//
//  Created by Geoff Baker on 31/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "FAQViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"
#import "TermsViewController.h"

@interface FAQViewController ()
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation FAQViewController {
    UIView *tmpView;
    UIView *popUpView;
    UIView *topView;
    UIImageView *profilePicture;
    UIScrollView *sideScroller;
    UIScrollView *pageScroller;
    NSUserDefaults *defaults;
    UIButton *editDescButton;
    UIButton *saveButton;
    UIButton *addFriendButton;
    UIButton *viewAchievementsButton;
    CLLocationManager *locationManager;
    int iteration;
    bool refreshView;
    bool userIsOnOverlay;
    bool libraryPicked;
    bool viewHasFinishedLoading;
    bool isFindingNearestParkOn;
    int distanceMovedScroll;
    int achievementCount;
    
    NSArray *collectedFriends;
    NSArray *achievementPhotos;
    
    IBOutlet UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    
}
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    userIsOnOverlay = NO;
    viewHasFinishedLoading = NO;
    // Do any additional setup after loading the view.
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [Flurry logEvent:@"User Opened FAQ Page" timed:YES];
    
    //Sounds
    
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];
    
    self.navigationController.navigationBarHidden = NO;
    
    UIImageView *navigationImage=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 40)];
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
        workaroundImageView.frame = CGRectMake(0, 0, 42, 42);
    } else {
        workaroundImageView.frame = CGRectMake(0, 0, 42, 42);
    }
    
    [workaroundImageView addSubview:navigationImage];
    self.navigationItem.titleView=workaroundImageView;
    self.navigationItem.titleView.center = self.view.center;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
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
    
    //Change the host name here to change the server you want to monitor.
    NSString *remoteHostName = @"www.apple.com";
    
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
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
    
    sideScroller.contentSize = CGSizeMake(sideScrollerSize, 50);
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
    [sideScroller setShowsHorizontalScrollIndicator:NO];
    [sideScroller setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:sideScroller];
    
    pageScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.frame = CGRectMake(0, 92, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -142);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 93, self.view.frame.size.width, 500); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -143);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -144);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -144);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 134, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -144);
    }else if([[UIScreen mainScreen] bounds].size.height == 812){ //iPhone XR/Max size
        pageScroller.frame = CGRectMake(0, 134, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -144);
    } else {
        pageScroller.frame = CGRectMake(0, 134, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height -144);
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    pageScroller.bounces = NO;
    [pageScroller setShowsVerticalScrollIndicator:NO];
    //[pageScroller setPagingEnabled : YES];
    [self.view addSubview:pageScroller];
    
    
    NSLog(@"%ld",(long)[defaults integerForKey:@"sideScrollerOffSet"]);
    //[self performSelector:@selector(setsideScrollerToPlace) withObject:nil afterDelay:0.01];
    
    
    //Get the array of Nav bar objects
    
    NSArray *arrayOfNavBarTitles = [navBar getTitles];
    NSArray *arrayOfXPositions = [navBar getXPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfButtonWidths = [navBar getButtonWidth:[[UIScreen mainScreen] bounds].size.height];
    
    //Add NavBar elements
    
    for (int i = 0; i < arrayOfNavBarTitles.count; i++) {
        NSString *title = [arrayOfNavBarTitles objectAtIndex:i];
        
        UIButton *navBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        navBarButton.frame = CGRectMake([[arrayOfXPositions objectAtIndex:i] integerValue], 10, [[arrayOfButtonWidths objectAtIndex:i] intValue], sideScroller.frame.size.height - 20);
        navBarButton.tag = i + 1;
        [navBarButton addTarget:self action:@selector(tapNavButton:) forControlEvents:UIControlEventTouchUpInside];
        [navBarButton setBackgroundImage:[UIImage imageNamed:title] forState:UIControlStateNormal];
        navBarButton.titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:25];
        [navBarButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sideScroller addSubview:navBarButton];
    }
    
    UILabel *faqLabel = [[UILabel alloc]init];
    faqLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        faqLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        faqLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        faqLabel.frame = CGRectMake(0, 25, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 30, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 30, self.view.frame.size.width, 20);
    } else {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 30, self.view.frame.size.width, 20);
    }
    faqLabel.text = [NSString stringWithFormat:@"FAQs"];
    
    faqLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:faqLabel];
    
    UITextView *mainText = [[UITextView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    } else {
        mainText.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        mainText.frame = CGRectMake(20, 60, self.view.frame.size.width - 40, self.view.frame.size.height - 170);
    }
    mainText.editable = NO;
    mainText.text = NSLocalizedString(@"THIS IS THE FAQ STRING", nil);
    [pageScroller addSubview:mainText];
    
    UIButton *termsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    } else {
        termsBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, self.view.frame.size.height - 45, 180, 33);
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [termsBtn setImage:[UIImage imageNamed:@"btn_tandc_french"] forState:UIControlStateNormal];
    } else {
        [termsBtn setImage:[UIImage imageNamed:@"btn_terms"] forState:UIControlStateNormal];
    }
    [termsBtn addTarget:self action:@selector(clickedTermsBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:termsBtn];
    
}

- (IBAction)clickedTermsBtn:(id)sender {
    TermsViewController *termsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Terms"];
    [self.navigationController pushViewController:termsViewController animated:YES];
}


-(void)loadParseContent{
    // Create the UI Scroll View
    
    [topView removeFromSuperview];
    [Hud removeFromSuperview];
    
    topView = [[UIView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 380); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 380); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 400); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 420); //Position of the scroller
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 420); //Position of the scroller
    } else {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 420); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    
    //[topView setPagingEnabled : YES];
    [pageScroller addSubview:topView];
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
    [topView addSubview:activityImageView];
    
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
                                        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error!", nil)
                                                                                       message:error.description delegate:nil
                                                                             cancelButtonTitle:NSLocalizedString(@"OK", nil)
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
                                    [PFCloud callFunctionInBackground:@"deleteDuplicateInstallations" withParameters:@{@"objectId": [PFUser currentUser].objectId} block:^(id  object, NSError * error) {
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
                                                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error!", nil)
                                                                                                   message:error.description delegate:nil
                                                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                                         otherButtonTitles:nil, nil];
                                                    [alert show];
                                                    
                                                    [self loadParseContent];
                                                }
                                            }];
                                        } else {
                                            NSLog(@"%@",error.description);
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

-(void)showLoginView{
    
    SWRevealViewController *LoginControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"InitialLogin"];
    
    [self.navigationController pushViewController:LoginControl animated:NO];
}

-(void)checkForLoginDate{
    
    BOOL sameDay = [[NSCalendar currentCalendar] isDateInToday:[[PFUser currentUser] objectForKey:@"lastLoginDate"]];
    
    if (sameDay) {
        
        //User has already logged in today
        
        
    } else {
        
    }
    [self loadUser];
}

-(void)loadUser {
    
}
//-(void)viewDidAppear:(BOOL)animated{
//    [super viewWillAppear:YES];
//
//    self.navigationController.navigationBar.hidden = NO;
//}

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
            Hud.labelFont = [UIFont fontWithName:@"ArialMT" size:12];
            Hud.detailsLabelText = NSLocalizedString(@"Please connect to Wi-Fi or your mobile internet.", nil);
            Hud.detailsLabelFont = [UIFont fontWithName:@"ArialMT" size:12];
            
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
            //    [topView addSubview:activityImageView];
            
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
                    
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Success!", nil)
                                                                   message:NSLocalizedString(@"Your username has been saved", nil) delegate:nil
                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
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

// Dismiss the keyboard
-(void)dismissKeyboard
{
    NSLog(@"Error Catcher");
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
    
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Profile"];
    
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
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Profile"];
    
    [sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
    
    [defaults setInteger:[[arrayOfActiveViews objectAtIndex:anIndex] intValue] forKey:@"sideScrollerOffSet"];
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

-(void) viewWillAppear:(BOOL)animated {
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
}

@end
