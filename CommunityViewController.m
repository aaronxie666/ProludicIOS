//
//  CommunityViewController.m
//  Proludic
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CommunityViewController.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"
#import "CustomAlert.h"

@interface CommunityViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;

@end

@implementation CommunityViewController {
    UIView *tmpView;
    UIView *popUpView;
    UIView *postView;
    UIView *postView1;
    UIScrollView *sideScroller;
    UIScrollView *pageScroller;
    UIScrollView *pageScroller1;
    UIScrollView *pageScroller2;
    UIScrollView *pageScroller3;
    UIScrollView *pageScroller4;
    NSUserDefaults *defaults;
    NSUInteger postIndex;
    NSString *clickedObjectId;
    NSString *clickedPostId;
    NSString *clickedPostId2;
    NSMutableArray *postIdArray;
    NSString *originalPoster;
    NSString *posterObjectId;
    UIButton *newReplyButton;
    
    int iteration;
    int postCount;
    bool refreshView;
    bool userIsOnOverlay;
    bool libraryPicked;
    bool viewHasFinishedLoading;
    
    UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    
    
    
    //PFObjects
    PFObject *selectedMatchObject;
    PFObject *selectedOpponent;
    PFObject *achievementsObject;
    PFObject *threadObj;
    PFObject *postObj;
    
    //AnimationImage
    UIImageView *glowImageView;
    
    UIButton *view1;
    UIButton *view2;
    UIButton *view3;
    
    CustomAlert *alertVC;
    int numberOfAlertVC;
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    userIsOnOverlay = NO;
    viewHasFinishedLoading = NO;
    // Do any additional setup after loading the view.
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [Flurry logEvent:@"User Opened Dashboard Page" timed:YES];
    
    //Sounds
    
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
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
    
    NavBar *navBar = [[NavBar alloc] init];
    
    int sideScrollerSize = [navBar getSize];
    
    sideScroller.contentSize = CGSizeMake(sideScrollerSize, 50);
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
        if (i == 3) { // Exercises
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
    
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.view.userInteractionEnabled=YES;
    
    //RECTANGLES
    CGRect frame1;
    CGRect frame2;
    CGRect frame3;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        frame1 = CGRectMake( 0, 93, 110.0, 45.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 110.0, 45.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 110.0, 45.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        frame1 = CGRectMake( 0, 93, 110.0, 45.0);
        frame2 = CGRectMake( self.view.frame.size.width / 3, 93, 110.0, 45.0);
        frame3 = CGRectMake( self.view.frame.size.width / 3 * 2, 93, 110.0, 45.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        frame1 = CGRectMake( 0, 94, 125.0, 50.0);
        frame2 = CGRectMake( 125, 94, 125.0, 50.0);
        frame3 = CGRectMake( 250, 94, 125.0, 50.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        frame1 = CGRectMake( 0, 94, 145.0, 60.0);
        frame2 = CGRectMake( 135, 94, 145.0, 60.0);
        frame3 = CGRectMake( 270, 94, 145.0, 60.0);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        frame1 = CGRectMake( 0, 138, 125.0, 50.0);
        frame2 = CGRectMake( 125, 138, 125.0, 50.0);
        frame3 = CGRectMake( 250, 138, 125.0, 50.0);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max
        frame1 = CGRectMake( 0, 138, 145.0, 50.0);
        frame2 = CGRectMake( 140, 138, 145.0, 50.0);
        frame3 = CGRectMake( 280, 138, 145.0, 50.0);
    } else {
        frame1 = CGRectMake( 0, 138, 125.0, 50.0);
        frame2 = CGRectMake( 125, 138, 125.0, 50.0);
        frame3 = CGRectMake( 250, 138, 125.0, 50.0);
    }
    
    
    view1 = [[UIButton alloc] initWithFrame:frame1];
    view2 = [[UIButton alloc] initWithFrame:frame2];
    view3 = [[UIButton alloc] initWithFrame:frame3];
    
    [view1 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view2 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view3 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    
    [view1 setTitle:NSLocalizedString(@"Local", nil) forState:UIControlStateNormal];
    [view2 setTitle:NSLocalizedString(@"National", nil) forState:UIControlStateNormal];
    [view3 setTitle:NSLocalizedString(@"Forum", nil) forState:UIControlStateNormal];
    
    [view1 addTarget:self action:@selector(tapLocalBar:) forControlEvents:UIControlEventTouchUpInside];
    [view2 addTarget:self action:@selector(tapNationalBar:) forControlEvents:UIControlEventTouchUpInside];
    [view3 addTarget:self action:@selector(tapForumBar:) forControlEvents:UIControlEventTouchUpInside];
    
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    
    [self.view addSubview:view1];
    [self.view addSubview:view2];
    [self.view addSubview:view3];
    
    
    [self loadParseContent];
    [Hud removeFromSuperview];
    
    //LOOP TO LOAD CONTENT ON LOAD ONCE
    int x = 0;
    if (x == 0) {
        [self tapLocalBar:self];
        x++;
    }
    
    
}


-(IBAction)tapLocalBar:(id)sender
{
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [pageScroller removeFromSuperview];
    [pageScroller1 removeFromSuperview];
    [pageScroller2 removeFromSuperview];
    [pageScroller3 removeFromSuperview];
    [pageScroller4 removeFromSuperview];
    
    [self addLocalViews];
    
}

-(IBAction)tapNationalBar:(id)sender
{
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [pageScroller removeFromSuperview];
    [pageScroller1 removeFromSuperview];
    [pageScroller2 removeFromSuperview];
    [pageScroller3 removeFromSuperview];
    [pageScroller4 removeFromSuperview];
    [self addNationalViews];
    
}
-(IBAction)tapForumBar:(id)sender
{
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    
    [pageScroller removeFromSuperview];
    [pageScroller1 removeFromSuperview];
    [pageScroller2 removeFromSuperview];
    [pageScroller3 removeFromSuperview];
    [pageScroller4 removeFromSuperview];
    [self addForumViews];
    
}

-(void)addLocalViews {
    pageScroller2 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller2.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 120);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller2.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 70);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller2.frame = CGRectMake(0, 160, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller2.frame = CGRectMake(0, 170, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller2.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        pageScroller2.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    } else {
        pageScroller2.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 100);
    }
    
    pageScroller2.bounces = NO;
    [pageScroller2 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller2];
    
    //Hearts Identifier Bar
    UILabel *rankKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    
    UILabel *nameKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    
    UILabel *heartsKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    } else {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    }
    
    rankKey.textColor = [UIColor whiteColor];
    nameKey.textColor = [UIColor whiteColor];
    heartsKey.textColor = [UIColor whiteColor];
    
    rankKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    nameKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    heartsKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    
    nameKey.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0];
    heartsKey.backgroundColor = [UIColor clearColor];
    rankKey.backgroundColor = [UIColor clearColor];
    
    rankKey.textAlignment = NSTextAlignmentLeft;
    nameKey.textAlignment = NSTextAlignmentLeft;
    heartsKey.textAlignment = NSTextAlignmentRight;
    
    rankKey.text = NSLocalizedString(@"     Rank", nil);
    nameKey.text = NSLocalizedString(@"                            Name", nil);
    heartsKey.text = NSLocalizedString(@"Hearts", nil);
    
    [pageScroller2 addSubview:nameKey];
    [pageScroller2 addSubview:heartsKey];
    [pageScroller2 addSubview:rankKey];
    
    //Hearts Leaderboard
    
    [self showLoading];
    PFQuery *queryTopRank = [PFUser query];
    [queryTopRank orderByDescending:@"Hearts"];
    queryTopRank.limit = 5;
    [queryTopRank whereKey:@"HomePark" equalTo:[PFUser currentUser][@"HomePark"]];
    [queryTopRank findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"%d Top rank request success.", objects.count);
            
            int count = 1;
            
            for (PFObject *object in objects) {
                
                UILabel *rank = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                rank.textColor = [UIColor blackColor];
                rank.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                UILabel *leaderboardName = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                leaderboardName.textColor = [UIColor blackColor];
                leaderboardName.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                UILabel *leaderboardHearts = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 20, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 20, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 35, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 50, 30);
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 50, 30);
                } else {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 50, 30);
                }
                leaderboardHearts.textColor = [UIColor blackColor];
                leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                rank.textAlignment = NSTextAlignmentLeft;
                leaderboardName.textAlignment = NSTextAlignmentLeft;
                leaderboardHearts.textAlignment = NSTextAlignmentRight;
                
                // Heart Image
                UIImageView *heartImage2 = [[UIImageView alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    heartImage2.frame = CGRectMake(235, 49 + count * 30, 10, 10);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    heartImage2.frame = CGRectMake(235, 49 + count * 30, 10, 10);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    heartImage2.frame = CGRectMake(275, 49 + count * 30, 13, 13);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    heartImage2.frame = CGRectMake(300, 49 + count * 30, 15, 15);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    heartImage2.frame = CGRectMake(260, 49 + count * 30, 15, 15);
                } else {
                    heartImage2.frame = CGRectMake(260, 49 + count * 30, 15, 15);
                }
                heartImage2.image = [UIImage imageNamed:@"Heart"];
                heartImage2.contentMode = UIViewContentModeScaleAspectFit;
                heartImage2.clipsToBounds = YES;
                
                if(count % 2 == 0) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                }
                
                if([object[@"username"]  isEqual: [PFUser currentUser][@"username"]]) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.95 green:0.84 blue:0.52 alpha:1.0];
                }
                
                [rank setText:[NSString stringWithFormat:@"       #%d", count]];
                leaderboardHearts.backgroundColor = [UIColor clearColor];
                [leaderboardName setText:[NSString stringWithFormat:@"                            %@", object[@"name"]]];
                leaderboardHearts.text = [NSString stringWithFormat:@"%@", object [@"Hearts"]];
                [pageScroller2 addSubview:leaderboardName];
                [pageScroller2 addSubview:leaderboardHearts];
                count++;
                [pageScroller2 addSubview:rank];
                [pageScroller2 addSubview:heartImage2];
                [Hud removeFromSuperview];
            }
            
        }
    }];
    
    // Achievements Leaderboard Label
    UILabel *achievementLeaderboardLabel = [[UILabel alloc]init];
    achievementLeaderboardLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        achievementLeaderboardLabel.frame = CGRectMake(0, 240, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        achievementLeaderboardLabel.frame = CGRectMake(0, 240, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 250, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    } else {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    }
    achievementLeaderboardLabel.text = [NSString stringWithFormat:NSLocalizedString(@"achievement leaderboard", nil)];
    
    achievementLeaderboardLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller2 addSubview:achievementLeaderboardLabel];
    
    UILabel *heartsLeaderboardLabel = [[UILabel alloc]init];
    heartsLeaderboardLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLeaderboardLabel.frame = CGRectMake(0, 3, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLeaderboardLabel.frame = CGRectMake(0, 3, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 5, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    } else {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    }
    heartsLeaderboardLabel.text = [NSString stringWithFormat:NSLocalizedString(@"hearts leaderboard", nil)];
    
    heartsLeaderboardLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller2 addSubview:heartsLeaderboardLabel];
    
    //Achievement Identifier Bar
    UILabel *rankKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        rankKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        rankKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    
    UILabel *nameKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        nameKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        nameKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    
    UILabel *heartsKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartsKey2.frame = CGRectMake(0, 275, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartsKey2.frame = CGRectMake(0, 275, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    } else {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    }
    
    
    rankKey2.textColor = [UIColor whiteColor];
    nameKey2.textColor = [UIColor whiteColor];
    heartsKey2.textColor = [UIColor whiteColor];
    
    rankKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    nameKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    heartsKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    
    nameKey2.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0];
    heartsKey2.backgroundColor = [UIColor clearColor];
    rankKey2.backgroundColor = [UIColor clearColor];
    
    rankKey2.textAlignment = NSTextAlignmentLeft;
    nameKey2.textAlignment = NSTextAlignmentLeft;
    heartsKey2.textAlignment = NSTextAlignmentRight;
    
    rankKey2.text = NSLocalizedString(@"     Rank", nil);
    nameKey2.text = NSLocalizedString(@"                            Name", nil);
    heartsKey2.text = NSLocalizedString(@"Achievements", nil);
    
    [pageScroller2 addSubview:nameKey2];
    [pageScroller2 addSubview:heartsKey2];
    [pageScroller2 addSubview:rankKey2];
    
    //Achievement Leaderboard
    
    PFQuery *queryTopAchievements = [PFUser query];
    [queryTopAchievements orderByDescending:@"TotalAchievements"];
    [queryTopAchievements whereKey:@"HomePark" equalTo:[PFUser currentUser][@"HomePark"]];
    queryTopAchievements.limit = 5;
    [queryTopAchievements findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
        if (!error) {
            NSString *rankString = @"1";
            
            int count = 1;
            
            for (PFObject *object in objects2) {
                
                UILabel *rank = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    rank.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                rank.textColor = [UIColor blackColor];
                
                UILabel *leaderboardName = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardName.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                leaderboardName.textColor = [UIColor blackColor];
                
                UILabel *leaderboardHearts = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 20, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width - 20, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 35, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                } else {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                }
                leaderboardHearts.textColor = [UIColor blackColor];
                
                rank.font = [UIFont fontWithName:@"Open Sans" size:14];
                leaderboardName.font = [UIFont fontWithName:@"Open Sans" size:14];
                leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                rank.textAlignment = NSTextAlignmentLeft;
                leaderboardName.textAlignment = NSTextAlignmentLeft;
                leaderboardHearts.textAlignment = NSTextAlignmentRight;
                
                // Heart Image
                UIImageView *heartImage2 = [[UIImageView alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    heartImage2.frame = CGRectMake(235, 298 + count * 30, 10, 10);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    heartImage2.frame = CGRectMake(235, 280 + count * 30, 10, 10);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    heartImage2.frame = CGRectMake(275, 298 + count * 30, 13, 13);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    heartImage2.frame = CGRectMake(300, 298 + count * 30, 15, 15);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    heartImage2.frame = CGRectMake(260, 298 + count * 30, 15, 15);
                } else {
                    heartImage2.frame = CGRectMake(260, 298 + count * 30, 15, 15);
                }
                heartImage2.image = [UIImage imageNamed:@"ic_challenge"];
                heartImage2.contentMode = UIViewContentModeScaleAspectFit;
                heartImage2.clipsToBounds = YES;
                
                if(count % 2 == 0) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                }
                
                if([object[@"username"]  isEqual: [PFUser currentUser][@"username"]]) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.95 green:0.84 blue:0.52 alpha:1.0];
                }
                
                [rank setText:[NSString stringWithFormat:@"       #%d", count]];
                leaderboardHearts.backgroundColor = [UIColor clearColor];
                [leaderboardName setText:[NSString stringWithFormat:@"                            %@", object[@"name"]]];
                leaderboardHearts.text = [NSString stringWithFormat:@"%@", object [@"TotalAchievements"]];
                
                [pageScroller2 addSubview:leaderboardName];
                [pageScroller2 addSubview:leaderboardHearts];
                count++;
                [pageScroller2 addSubview:rank];
                [pageScroller2 addSubview:heartImage2];
                
            }
            
        }
    }];
}

-(void)addNationalViews {
    pageScroller1 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller1.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height+2300);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller1.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height+50);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 135);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller1.frame = CGRectMake(0, 160, self.view.frame.size.width, self.view.frame.size.height+2500); //Position of the scroller
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller1.frame = CGRectMake(0, 170, self.view.frame.size.width, self.view.frame.size.height+2700);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller1.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height+2700);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){
        pageScroller1.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height+2700);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    } else {
        pageScroller1.frame = CGRectMake(0, 190, self.view.frame.size.width, self.view.frame.size.height+2700);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
    }
    
    pageScroller1.bounces = NO;
    [pageScroller1 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller1];
    
    //Hearts Identifier Bar
    UILabel *rankKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else {
        rankKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    
    UILabel *nameKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    } else {
        nameKey.frame = CGRectMake(0, 40, self.view.frame.size.width, 30);
    }
    
    UILabel *heartsKey = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 40, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    } else {
        heartsKey.frame = CGRectMake(0, 40, self.view.frame.size.width - 60, 30);
    }
    
    rankKey.textColor = [UIColor whiteColor];
    nameKey.textColor = [UIColor whiteColor];
    heartsKey.textColor = [UIColor whiteColor];
    
    rankKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    nameKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    heartsKey.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    
    nameKey.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0];
    heartsKey.backgroundColor = [UIColor clearColor];
    rankKey.backgroundColor = [UIColor clearColor];
    
    rankKey.textAlignment = NSTextAlignmentLeft;
    nameKey.textAlignment = NSTextAlignmentLeft;
    heartsKey.textAlignment = NSTextAlignmentRight;
    
    rankKey.text = NSLocalizedString(@"     Rank", nil);
    nameKey.text = NSLocalizedString(@"                            Name", nil);
    heartsKey.text = NSLocalizedString(@"Hearts", nil);
    
    [pageScroller1 addSubview:nameKey];
    [pageScroller1 addSubview:heartsKey];
    [pageScroller1 addSubview:rankKey];
    
    //Hearts Leaderboard
    [self showLoading];
    PFQuery *queryTopRank = [PFUser query];
    [queryTopRank orderByDescending:@"Hearts"];
    [queryTopRank setLimit:5];
    if([[PFUser currentUser][@"isFrench"] isEqual:@YES]) {
        [queryTopRank whereKey:@"isFrench" equalTo:@YES];
    }
    [queryTopRank findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"%d Top rank request success.", objects.count);
            NSArray *countArray = @[@1, @2, @3, @4, @5];
            NSString *rankString = [NSString stringWithFormat:@"%@", countArray];
            
            int count = 1;
            
            for (PFObject *object in objects) {
                
                UILabel *rank = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else {
                    rank.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                rank.textColor = [UIColor blackColor];
                
                UILabel *leaderboardName = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                } else {
                    leaderboardName.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width, 30);
                }
                leaderboardName.textColor = [UIColor blackColor];
                
                UILabel *leaderboardHearts = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 20, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:12];
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 20, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:12];
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 35, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 50, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 30, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                } else {
                    leaderboardHearts.frame = CGRectMake(0, 40 + count * 30, self.view.frame.size.width - 30, 30);
                    leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                }
                leaderboardHearts.textColor = [UIColor blackColor];
                
                rank.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                leaderboardName.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                rank.textAlignment = NSTextAlignmentLeft;
                leaderboardName.textAlignment = NSTextAlignmentLeft;
                leaderboardHearts.textAlignment = NSTextAlignmentRight;
                
                // Heart Image
                UIImageView *heartImage2 = [[UIImageView alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    heartImage2.frame = CGRectMake(235, 49 + count * 30, 10, 10);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    heartImage2.frame = CGRectMake(235, 49 + count * 30, 10, 10);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    heartImage2.frame = CGRectMake(275, 49 + count * 30, 13, 13);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    heartImage2.frame = CGRectMake(300, 49 + count * 30, 15, 15);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    heartImage2.frame = CGRectMake(260, 49 + count * 30, 15, 15);
                } else {
                    heartImage2.frame = CGRectMake(260, 49 + count * 30, 15, 15);
                }
                heartImage2.image = [UIImage imageNamed:@"Heart"];
                heartImage2.contentMode = UIViewContentModeScaleAspectFit;
                heartImage2.clipsToBounds = YES;
                
                
                
                if(count % 2 == 0) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                }
                
                if([object[@"username"]  isEqual: [PFUser currentUser][@"username"]]) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.95 green:0.84 blue:0.52 alpha:1.0];
                }
                
                [rank setText:[NSString stringWithFormat:@"       #%d", count]];
                leaderboardHearts.backgroundColor = [UIColor clearColor];
                [leaderboardName setText:[NSString stringWithFormat:@"                            %@", object[@"name"]]];
                leaderboardHearts.text = [NSString stringWithFormat:@"                                                                                  %@", object [@"Hearts"]];
                
                [pageScroller1 addSubview:leaderboardName];
                [pageScroller1 addSubview:leaderboardHearts];
                count++;
                [pageScroller1 addSubview:rank];
                [pageScroller1 addSubview:heartImage2];
                [Hud removeFromSuperview];
            }
            
        }
    }];
    
    
    // Achievements Leaderboard Label
    UILabel *achievementLeaderboardLabel = [[UILabel alloc]init];
    achievementLeaderboardLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        achievementLeaderboardLabel.frame = CGRectMake(0, 240, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        achievementLeaderboardLabel.frame = CGRectMake(0, 240, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 250, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    } else {
        achievementLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        achievementLeaderboardLabel.frame = CGRectMake(0, 260, self.view.frame.size.width, 20);
    }
    achievementLeaderboardLabel.text = [NSString stringWithFormat:NSLocalizedString(@"achievement leaderboard", nil)];
    
    achievementLeaderboardLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller1 addSubview:achievementLeaderboardLabel];
    
    UILabel *heartsLeaderboardLabel = [[UILabel alloc]init];
    heartsLeaderboardLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLeaderboardLabel.frame = CGRectMake(0, 3, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLeaderboardLabel.frame = CGRectMake(0, 3, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 5, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    } else {
        heartsLeaderboardLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLeaderboardLabel.frame = CGRectMake(0, 10, self.view.frame.size.width, 20);
    }
    heartsLeaderboardLabel.text = [NSString stringWithFormat:NSLocalizedString(@"hearts leaderboard", nil)];
    
    heartsLeaderboardLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller1 addSubview:heartsLeaderboardLabel];
    
    //Achievement Identifier Bar
    UILabel *rankKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        rankKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        rankKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else {
        rankKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    
    UILabel *nameKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        nameKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        nameKey2.frame = CGRectMake(0, 275, self.view.frame.size.width, 30);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    } else {
        nameKey2.frame = CGRectMake(0, 290, self.view.frame.size.width, 30);
    }
    
    UILabel *heartsKey2 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartsKey2.frame = CGRectMake(0, 275, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartsKey2.frame = CGRectMake(0, 275, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 20, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    } else {
        heartsKey2.frame = CGRectMake(0, 290, self.view.frame.size.width - 40, 30);
    }
    
    
    rankKey2.textColor = [UIColor whiteColor];
    nameKey2.textColor = [UIColor whiteColor];
    heartsKey2.textColor = [UIColor whiteColor];
    
    rankKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    nameKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    heartsKey2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
    
    nameKey2.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0];
    heartsKey2.backgroundColor = [UIColor clearColor];
    rankKey2.backgroundColor = [UIColor clearColor];
    
    rankKey2.textAlignment = NSTextAlignmentLeft;
    nameKey2.textAlignment = NSTextAlignmentLeft;
    heartsKey2.textAlignment = NSTextAlignmentRight;
    
    rankKey2.text = NSLocalizedString(@"     Rank", nil);
    nameKey2.text = NSLocalizedString(@"                            Name", nil);
    heartsKey2.text = NSLocalizedString(@"Achievements", nil);
    
    [pageScroller1 addSubview:nameKey2];
    [pageScroller1 addSubview:heartsKey2];
    [pageScroller1 addSubview:rankKey2];
    
    //Achievement Leaderboard
    
    PFQuery *queryTopAchievements = [PFQuery queryWithClassName:@"Locations"];
    [queryTopAchievements orderByDescending:@"TotalAchievements"];
    queryTopAchievements.limit = 5;
    if([[PFUser currentUser][@"isFrench"] isEqual:@YES]) {
        [queryTopAchievements whereKey:@"isFrench" equalTo:@YES];
    }
    [queryTopAchievements findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
        if (!error) {
            NSString *rankString = @"1";
            
            int count = 1;
            
            for (PFObject *object in objects2) {
                
                UILabel *rank = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    rank.frame = CGRectMake(0, 270 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    rank.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else {
                    rank.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                rank.textColor = [UIColor blackColor];
                
                UILabel *leaderboardName = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardName.frame = CGRectMake(0, 270 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardName.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                } else {
                    leaderboardName.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width, 30);
                }
                leaderboardName.textColor = [UIColor blackColor];
                
                UILabel *leaderboardHearts = [[UILabel alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    leaderboardHearts.frame = CGRectMake(0, 270 + count * 30, self.view.frame.size.width - 20, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 273 + count * 30, self.view.frame.size.width - 20, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 35, 30);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                } else {
                    leaderboardHearts.frame = CGRectMake(0, 290 + count * 30, self.view.frame.size.width - 50, 30);
                }
                leaderboardHearts.textColor = [UIColor blackColor];
                
                rank.font = [UIFont fontWithName:@"Open Sans" size:14];
                leaderboardName.font = [UIFont fontWithName:@"Open Sans" size:14];
                leaderboardHearts.font = [UIFont fontWithName:@"Open Sans" size:14];
                
                rank.textAlignment = NSTextAlignmentLeft;
                leaderboardName.textAlignment = NSTextAlignmentLeft;
                leaderboardHearts.textAlignment = NSTextAlignmentRight;
                
                // Heart Image
                UIImageView *heartImage2 = [[UIImageView alloc]init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    heartImage2.frame = CGRectMake(235, 282 + count * 30, 10, 10);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    heartImage2.frame = CGRectMake(235, 285 + count * 30, 10, 10);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    heartImage2.frame = CGRectMake(275, 298 + count * 30, 13, 13);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    heartImage2.frame = CGRectMake(300, 298 + count * 30, 15, 15);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    heartImage2.frame = CGRectMake(260, 298 + count * 30, 15, 15);
                } else {
                    heartImage2.frame = CGRectMake(260, 298 + count * 30, 15, 15);
                }
                heartImage2.image = [UIImage imageNamed:@"ic_challenge"];
                heartImage2.contentMode = UIViewContentModeScaleAspectFit;
                heartImage2.clipsToBounds = YES;
                
                if(count % 2 == 0) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
                }
                
                if([object.objectId  isEqual: [PFUser currentUser][@"HomePark"]]) {
                    leaderboardName.backgroundColor = [UIColor colorWithRed:0.95 green:0.84 blue:0.52 alpha:1.0];
                }
                
                [rank setText:[NSString stringWithFormat:@"       #%d", count]];
                leaderboardHearts.backgroundColor = [UIColor clearColor];
                [leaderboardName setText:[NSString stringWithFormat:@"                            %@", object[@"Location"]]];
                leaderboardHearts.text = [NSString stringWithFormat:@"%@", object [@"TotalAchievements"]];
                [pageScroller1 addSubview:leaderboardName];
                [pageScroller1 addSubview:leaderboardHearts];
                count++;
                [pageScroller1 addSubview:rank];
                [pageScroller1 addSubview:heartImage2];
            }
            
        }
    }];
    
}

-(void)addForumViews {
    
    pageScroller3 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller3.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller3.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller3.frame = CGRectMake(0, 144, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller3.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller3.frame = CGRectMake(0, 188, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        pageScroller3.frame = CGRectMake(0, 188, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else {
        pageScroller3.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller3.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }
    
    [pageScroller3 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller3];
    
    postView1 = [[UIView alloc] init];
    postView1.frame = CGRectMake(0, -1, self.view.frame.size.width, 100);
    postView1.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
    
    [pageScroller3 addSubview:postView1];
    
    UILabel *forumLocation = [[UILabel alloc] init];
    forumLocation.frame = CGRectMake(0, 30, self.view.frame.size.width, 50);
    forumLocation.font = [UIFont fontWithName:@"Ethnocentric" size:16];
    forumLocation.textAlignment = NSTextAlignmentCenter;
    
    [postView1 addSubview:forumLocation];
    
    if([[[PFUser currentUser] objectForKey:@"HomePark"] isEqualToString:@"NotSelected"]) {
        forumLocation.text = [NSString stringWithFormat:@"%@",NSLocalizedString(@"Park Not Selected", nil)];
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
                forumLocation.text = [NSString stringWithFormat:@"%@",object[@"Location"]];
            }
        }];
    }
    
    UILabel *forumNotice = [[UILabel alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);
    } else {
        forumNotice.frame = CGRectMake(0, 5, self.view.frame.size.width, 50);
    }
    forumNotice.text = NSLocalizedString(@"Welcome to the Proludic Forum", nil);
    forumNotice.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
    forumNotice.textAlignment = NSTextAlignmentCenter;
    
    [postView1 addSubview:forumNotice];
    
    // Create New Thread Button
    UIButton *newThreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        newThreadButton.frame = CGRectMake(40, 83, 230, 33);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        newThreadButton.frame = CGRectMake(45, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        newThreadButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        newThreadButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        newThreadButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        newThreadButton.frame = CGRectMake(93, 83, 230, 33);//Position of the button
    } else {
        newThreadButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [newThreadButton setBackgroundImage:[UIImage imageNamed:@"btn_newthread_french"] forState:UIControlStateNormal];
    } else {
        [newThreadButton setBackgroundImage:[UIImage imageNamed:@"btn_newthread2"] forState:UIControlStateNormal];
    }
    [newThreadButton addTarget:self action:@selector(tapNewThread:) forControlEvents:UIControlEventTouchUpInside];
    
    [postView1 addSubview:newThreadButton];
    
    //Load Posts Query & Loop
    PFQuery *threadQuery = [PFQuery queryWithClassName:@"Posts"];
    PFObject *tmpObj = [PFObject objectWithoutDataWithClassName:@"Locations" objectId:[PFUser currentUser][@"HomePark"]];
    [threadQuery whereKey:@"Community" equalTo:tmpObj];
    [threadQuery orderByDescending:@"createdAt"];
    [threadQuery findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        
        if (!error) {
            
            postCount = 0;
            
            postIdArray = [NSMutableArray arrayWithArray:posts];
            
            for (PFObject *object in posts) {
                [self showLoading];
                
                NSString *postReplyCount = [NSString stringWithFormat:NSLocalizedString(@"Replies: %lu", nil), [object[@"Replies"] count]];
                
                postView = [[UIView alloc] init];
                postView.frame = CGRectMake(0, 80 * postCount + 130, self.view.frame.size.width, 70);
                postView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
                
                [pageScroller3 addSubview:postView];
                
                UILabel *postTitleLabel = [[UILabel alloc] init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                } else {
                    postTitleLabel.frame = CGRectMake(60, -10, self.view.frame.size.width - 140, 50);
                }
                postTitleLabel.text = object[@"PostTitle"];
                postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
                postTitleLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView addSubview:postTitleLabel];
                
                UILabel *postContentLabel = [[UILabel alloc] init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                } else {
                    postContentLabel.frame = CGRectMake(60, 25, self.view.frame.size.width - 140, 50);
                }
                postContentLabel.text = object[@"PostContent"];
                postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                postContentLabel.textAlignment = NSTextAlignmentLeft;
                postContentLabel.numberOfLines = 2;
                
                [postView addSubview:postContentLabel];
                
                UILabel *postUserLabel = [[UILabel alloc] init];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                } else {
                    postUserLabel.frame = CGRectMake(60, 5, self.view.frame.size.width - 140, 50);
                }
                postUserLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postUserLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView addSubview:postUserLabel];
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"objectId" equalTo:[object[@"OriginalPoster"] objectId]];
                [query orderByDescending:@"createdAt"];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!object) {
                        [Hud removeFromSuperview];
                    } else {
                        // The find succeeded.
                        NSString *postUserString = [NSString stringWithFormat:NSLocalizedString(@"by: %@", nil), object[@"username"]];
                        NSString *combined = [NSString stringWithFormat:@"%@ | %@", postUserString, postReplyCount];
                        postUserLabel.text = combined;
                    }
                }];
                
                if([[PFUser currentUser].objectId isEqualToString: [object[@"OriginalPoster"] objectId]]) {
                    UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
                    tapGesture.minimumPressDuration = 0.5f;
                    tapGesture.allowableMovement = 100.0f;
                    [postView addGestureRecognizer:tapGesture];
                } else {
                    
                }
                
                newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    newReplyButton.frame = CGRectMake(240, 15, 40, 40);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    newReplyButton.frame = CGRectMake(260, 15, 40, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    newReplyButton.frame = CGRectMake(305, 15, 40, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    newReplyButton.frame = CGRectMake(345, 15, 40, 40);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    newReplyButton.frame = CGRectMake(315, 15, 40, 40);//Position of the button
                } else {
                    newReplyButton.frame = CGRectMake(315, 15, 40, 40);//Position of the button
                }
                [newReplyButton setTitle:[object objectId] forState:UIControlStateNormal];
                newReplyButton.titleLabel.layer.opacity = 0.0f;
                [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply_float"] forState:UIControlStateNormal];
                [newReplyButton addTarget:self action:@selector(tapOpenThread:) forControlEvents:UIControlEventTouchUpInside];
                
                [postView addSubview:newReplyButton];
                
                UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                } else {
                    reportButton.frame = CGRectMake(20, 25, 20, 20);//Position of the button
                }
                [reportButton setTitle:[object objectId] forState:UIControlStateNormal];
                reportButton.titleLabel.layer.opacity = 0.0f;
                [reportButton setBackgroundImage:[UIImage imageNamed:@"ic_report"] forState:UIControlStateNormal];
                [reportButton addTarget:self action:@selector(tapReportThread:) forControlEvents:UIControlEventTouchUpInside];
                
                [postView addSubview:reportButton];
                
                postCount = postCount + 1;
                
                [Hud removeFromSuperview];
            }
        } else {
            NSLog(@"Posts not found");
        }
        
    }];
    
}


- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    NSLog(@"%@", sender.view);
    UIView *tmp = (UIView*) sender.view;
    UIButton *button;
    for (UIView *subview in tmp.subviews)
    {
        if([subview isKindOfClass:[UIButton class]]) {
            button =  (UIButton*)subview;
            break;
        }
    }
    if (sender.state == UIGestureRecognizerStateRecognized) {
        numberOfAlertVC = 1;
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadDeletePost:self:NSLocalizedString(@"Delete Thread", nil):NSLocalizedString(@"Are you sure you want to permanantly delete the current thread?", nil):button.titleLabel.text:1];
        [alertVC.alertView removeFromSuperview];
        
    }
}

-(void) tappedDeleteThread: (NSString*) objectThreadId {
    [self showLoading];
    PFQuery *query = [PFQuery queryWithClassName:@"Posts"];
    [query whereKey:@"objectId" equalTo:objectThreadId];
    [query whereKey:@"OriginalPoster" equalTo:[PFUser currentUser]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *thread, NSError *error) {
        if (!error) {
            //Get all replies to that thread
            NSMutableArray *allReplies = thread[@"Replies"];
            if([allReplies count] > 0) {
                PFQuery *query2 = [PFQuery queryWithClassName:@"PostReplies"];
                [query2 whereKey:@"objectId" containedIn:allReplies];
                [query2 whereKey:@"Post" equalTo:thread];
                [query2 findObjectsInBackgroundWithBlock:^(NSArray *replies, NSError *error2) {
                    if (!error2) {
                        //Get all replies to that thread
                        for(PFObject *reply in replies) {
                            NSMutableArray *allRepliesReplies = reply[@"Replies"];
                            if([allRepliesReplies count] > 0) {
                                
                                PFQuery *query3 = [PFQuery queryWithClassName:@"PostReplyReplies"];
                                [query3 whereKey:@"objectId" containedIn:allRepliesReplies];
                                [query3 whereKey:@"PostReplies" equalTo:reply];
                                [query3 findObjectsInBackgroundWithBlock:^(NSArray *repliesreplies, NSError *error3) {
                                    if (!error3) {
                                        
                                        for (PFObject *replyInReplies in repliesreplies) {
                                            // Delete all replies in each reply in the thread
                                            [replyInReplies deleteInBackground];
                                        }
                                    } else {
                                        
                                    }
                                    [Hud removeFromSuperview];
                                }];
                            } else {
                                [Hud removeFromSuperview];
                            }
                            // Delete all replies in the thread
                            [reply deleteInBackground];
                        }
                    } else {
                        [Hud removeFromSuperview];
                    }
                    
                }];
            } else {
                [Hud removeFromSuperview];
            }
            // Delete the thread
            [thread deleteInBackground];
            
            [self deleteThreadAlert];
            [Hud removeFromSuperview];
            
        } else {
            [Hud removeFromSuperview];
        }
        
    }];
}

-(void)deleteThreadAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Thread Deleted", nil):NSLocalizedString(@"You've successfully deleted the thread and all relating posts!", nil)];
    [alertVC.alertView removeFromSuperview];
}

-(IBAction)tapReportThread:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedPostId = tmp;
    NSLog(@"-x-x-x-x-x- %@", tmp);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Report Thread", nil)
                                                                   message:NSLocalizedString(@"You are about to report this current thread. Please state the reason for this report.", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Report", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *postTitle = alert.textFields[0].text;
                                                              
                                                              if ([postTitle isEqualToString:@""]) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in the reason of the report!", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              } else {
                                                                  
                                                                  PFQuery *loadPostQuery = [PFQuery queryWithClassName:@"Posts"];
                                                                  [loadPostQuery whereKey:@"objectId" equalTo:clickedPostId];
                                                                  [loadPostQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                                                      
                                                                      if(!error) {
                                                                          
                                                                          NSLog(@"-x- %@", object);
                                                                          
                                                                          PFObject *post = [PFObject objectWithClassName:@"ReportedPosts"];
                                                                          post[@"Reason"] = postTitle;
                                                                          post[@"ReportedUser"] = [PFUser currentUser];
                                                                          post[@"Content"] = object[@"PostContent"];
                                                                          post[@"Moderated"] = @(NO);
                                                                          post[@"ReportedPost"] = object;
                                                                          
                                                                          [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                              if (succeeded) {
                                                                                  PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                                                                                  [query whereKey:@"User" equalTo:[PFUser currentUser]];
                                                                                  [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                                                                                      if (!error) {
                                                                                          
                                                                                          if ([userAchie[@"KeepingThePeace"]  isEqual: @NO]) {
                                                                                              userAchie[@"KeepingThePeace"] = @YES;
                                                                                              userAchie[@"User"] = [PFUser currentUser];
                                                                                              [userAchie saveInBackground];
                                                                                              
                                                                                              [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                                                                                              [Flurry logEvent:@"User Unlocked Keeping The Peace Achievement" timed:YES];
                                                                                              
                                                                                              alertVC = [[CustomAlert alloc] init];
                                                                                              [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Keeping the Peace' achievement! Well Done!", nil)];
                                                                                              [alertVC.alertView removeFromSuperview];
                                                                                              
                                                                                          }
                                                                                      } else {
                                                                                          //
                                                                                      }
                                                                                  }];
                                                                              } else {
                                                                                  // There was a problem, check error.description
                                                                              }
                                                                          }];
                                                                          
                                                                      } else {
                                                                          
                                                                          NSLog(@"It didn't work");
                                                                          
                                                                      }
                                                                      
                                                                  }];
                                                              }
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Reason...", nil);
    }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(IBAction)tapNewThread:(id)sender {
    NSLog(@"Button Tapped");
    
    [self customThreadAlert];
    
}

-(IBAction)tapOpenThread:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedObjectId = tmp;
    
    [pageScroller3 removeFromSuperview];
    [postView removeFromSuperview];
    NSLog(@"OPENED: ------------------ %@", tmp);
    [self addReplyViews];
    
}

-(void)addReplyViews {
    
    pageScroller4 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller4.frame = CGRectMake(0, 145, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller4.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 70);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller4.frame = CGRectMake(0, 144, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 115 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }
    
    pageScroller4.bounces = NO;
    [pageScroller4 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller4];
    
    //Load Posts Query & Loop
    
    PFQuery *query = [PFQuery queryWithClassName:@"Posts"];
    [query whereKey:@"objectId" equalTo:clickedObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            threadObj = object;
        } else {
            
        }
    }];
    
    PFQuery *originalPostQuery = [PFQuery queryWithClassName:@"Posts"];
    [originalPostQuery whereKey:@"objectId" equalTo:clickedObjectId];
    [originalPostQuery findObjectsInBackgroundWithBlock:^(NSArray *replies, NSError *error) {
        
        NSMutableArray *replyArray = [[NSMutableArray alloc] init];
        
        if (!error) {
            for (PFObject *object in replies) {
                [self showLoading];
                
                NSLog(@"ReplyTest2: %@", replies);
                
                postView1 = [[UIView alloc] init];
                postView1.frame = CGRectMake(0, -1, self.view.frame.size.width, 100);
                postView1.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
                
                [pageScroller4 addSubview:postView1];
                
                // Create New Reply
                newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    newReplyButton.frame = CGRectMake(40, 83, 230, 33);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    newReplyButton.frame = CGRectMake(45, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    newReplyButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                } else {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                }
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if([language containsString:@"fr"]) {
                    [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply_french"] forState:UIControlStateNormal];
                } else {
                    [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply2"] forState:UIControlStateNormal];
                }
                [newReplyButton addTarget:self action:@selector(tapNewReply:) forControlEvents:UIControlEventTouchUpInside];
                
                [postView1 addSubview:newReplyButton];
                
                UILabel *postTitleLabel = [[UILabel alloc] init];
                postTitleLabel.frame = CGRectMake(30, -5, self.view.frame.size.width - 60, 50);
                postTitleLabel.text = object[@"PostTitle"];
                postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
                postTitleLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postTitleLabel];
                
                UILabel *postContentLabel = [[UILabel alloc] init];
                postContentLabel.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 80);
                postContentLabel.text = object[@"PostContent"];
                postContentLabel.numberOfLines = 4;
                postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                postContentLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postContentLabel];
                
                UILabel *postOriginalPoster = [[UILabel alloc] init];
                postOriginalPoster.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 20);
                postOriginalPoster.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postOriginalPoster.textAlignment = NSTextAlignmentRight;
                
                [postView1 addSubview:postOriginalPoster];
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"objectId" equalTo:[object[@"OriginalPoster"] objectId]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!object) {
                        NSLog(@"This doesn't work?4");
                        [Hud removeFromSuperview];
                    } else {
                        // The find succeeded.
                        NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                        postOriginalPoster.text = postUserString;
                        NSLog(@"---------%@", object[@"username"]);
                    }
                }];
                
                replyArray = object[@"Replies"];
                NSLog(@"Reply Array: ------ %@", replyArray);
                //NSArray *tmp = [NSArray arrayWithObjects:@"NfjEO8yXWa27", @"FKLFv11dg527", nil];
                PFQuery *reply2Query = [PFQuery queryWithClassName:@"PostReplies"];
                [reply2Query whereKey:@"objectId" containedIn:replyArray];
                [reply2Query orderByDescending:@"createdAt"];
                [reply2Query findObjectsInBackgroundWithBlock:^(NSArray *replies2, NSError *error) {
                    if (!error) {
                        
                        NSLog(@"------------%lu", (unsigned long)[replies2 count]);
                        NSLog(@"Test: -------%@", replies2);
                        
                        int replyCount = 0;
                        
                        for (PFObject *object in replies2) {
                            
                            NSString *objectReplyCount = [NSString stringWithFormat:@"Replies: %lu", [object[@"Replies"] count]];
                            
                            postView = [[UIView alloc] init];
                            postView.frame = CGRectMake(70, 80 * replyCount + 130, self.view.frame.size.width, 70);
                            postView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
                            
                            [pageScroller4 addSubview:postView];
                            
                            UILabel *postTitleLabel = [[UILabel alloc] init];
                            postTitleLabel.frame = CGRectMake(30, -5, 200, 50);
                            postTitleLabel.text = object[@"ReplyContent"];
                            postTitleLabel.numberOfLines = 3;
                            postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                            postTitleLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postTitleLabel];
                            
                            UILabel *postContentLabel = [[UILabel alloc] init];
                            postContentLabel.frame = CGRectMake(30, 30, self.view.frame.size.width, 50);                            postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                            postContentLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postContentLabel];
                            
                            PFQuery *query = [PFUser query];
                            [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                            [query orderByDescending:@"createdAt"];
                            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                if (!object) {
                                    NSLog(@"This doesn't work?5");
                                    [Hud removeFromSuperview];
                                } else {
                                    // The find succeeded.
                                    NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                                    NSString *combine = [NSString stringWithFormat:@"%@ | %@", postUserString, objectReplyCount];
                                    postContentLabel.text = combine;
                                    NSLog(@"---------%@", object[@"username"]);
                                }
                            }];
                            
                            if([[PFUser currentUser].objectId isEqualToString: [object[@"ReplyingUser"] objectId]]) {
                                UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePostTapGesture:)];
                                tapGesture.minimumPressDuration = 0.5f;
                                tapGesture.allowableMovement = 100.0f;
                                [postView addGestureRecognizer:tapGesture];
                            }
                            
                            UIView *replySquare = [[UIView alloc] init];
                            replySquare.frame = CGRectMake(0, 80 * replyCount + 130, 70, 70);
                            replySquare.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            
                            [pageScroller4 addSubview:replySquare];
                            
                            newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            }
                            [newReplyButton setTitle:[object objectId] forState:UIControlStateNormal];
                            newReplyButton.titleLabel.layer.opacity = 0.0f;
                            newReplyButton.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            [newReplyButton setBackgroundImage:[UIImage imageNamed:@"ic_reply"] forState:UIControlStateNormal];
                            [newReplyButton addTarget:self action:@selector(tapOpenFurtherReplies:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [pageScroller4 addSubview:newReplyButton];
                            
                            UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                reportButton.frame = CGRectMake(250, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            }
                            [reportButton setTitle:[object objectId] forState:UIControlStateNormal];
                            reportButton.titleLabel.layer.opacity = 0.0f;
                            [reportButton setBackgroundImage:[UIImage imageNamed:@"ic_report"] forState:UIControlStateNormal];
                            [reportButton addTarget:self action:@selector(tapReportReply:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [postView addSubview:reportButton];
                            
                            replyCount++;
                            NSLog(@"ReplyCount: -------- %d", replyCount);
                        }
                    } else {
                        NSLog(@"This didnt work");
                    }
                    [Hud removeFromSuperview];
                }];
            }
        } else {
            NSLog(@"Posts not found");
        }
        
    }];
    
    
}

- (void)handlePostTapGesture:(UITapGestureRecognizer *)sender {
    NSLog(@"%@", sender.view);
    UIView *tmp = (UIView*) sender.view;
    UIButton *button;
    for (UIView *subview in tmp.subviews)
    {
        if([subview isKindOfClass:[UIButton class]]) {
            button =  (UIButton*)subview;
            break;
        }
    }
    if (sender.state == UIGestureRecognizerStateRecognized) {
        numberOfAlertVC = 2;
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadDeletePost:self:NSLocalizedString(@"Delete Post", nil):NSLocalizedString(@"Are you sure you want to permanantly delete the current post?", nil):button.titleLabel.text:3];
        [alertVC.alertView removeFromSuperview];
        
    }
}

-(void) tappedDeletePost: (NSString*) objectPostId {
    [self showLoading];
    PFQuery *postQuery = [PFQuery queryWithClassName:@"PostReplies"];
    [postQuery whereKey:@"objectId" equalTo:objectPostId];
    [postQuery whereKey:@"ReplyingUser" equalTo:[PFUser currentUser]];
    [postQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            //            NSMutableArray *allReplyReplies = object[@"Replies"];
            //
            //            PFQuery *threadQuery = [PFQuery queryWithClassName:@"Posts"];
            //            [threadQuery whereKey:@"objectId" equalTo:[object[@"Post"] objectId]];
            //            [threadQuery getFirstObjectInBackgroundWithBlock:^(PFObject *thread, NSError *threadError) {
            //                if (!error) {
            //                    NSLog(@"IMPORTANT-IMPORTANT: %@", thread[@"Replies"]);
            //                    NSInteger count = [thread[@"Replies"] count];
            //                    [thread[@"Replies"] removeLastObject];
            
            //                    for (NSInteger index = 0; index < count; index++) {
            //                        if([thread[@"Replies"] containsObject:objectPostId]) {
            //                            [thread[@"Replies"] removeObjectAtIndex:index];
            //                            [thread[@"Replies"] removeObjectForKey:<#(nonnull id)#> :index];
            //                            NSLog(@"Work!!!!!!!!!");
            //                            break;
            //                        }else{
            //                            NSLog(@"-=-=-=--=-=-=-=-=-=-=-=-=-=-=-%@", thread);
            //                        }
            //
            //
            //                    }
            
            //                } else {
            //                    NSLog(@"90909090909090909090909090%@", threadError);
            //                }
            //            }];
            
            //        if([allReplyReplies count] > 0) {
            
            //            PFQuery *postRepliesQuery = [PFQuery queryWithClassName:@"PostReplyReplies"];
            //            [postRepliesQuery whereKey:@"objectId" containedIn:allReplyReplies];
            //            [postRepliesQuery whereKey:@"PostReplies" equalTo:object];
            //            [postRepliesQuery findObjectsInBackgroundWithBlock:^(NSArray *replyReplies, NSError *error1) {
            //                if (!error) {
            //                    for(PFObject *reply in replyReplies) {
            //
            //                        [reply deleteInBackground];
            //                    }
            //
            //                } else {
            //                    NSLog(@"%@", error1);
            //
            //                }
            //
            //            }];
            //        }else{
            //            [Hud removeFromSuperview];
            //        }
        } else {
            [Hud removeFromSuperview];
            NSLog(@"++++++++++++++++++++++++++++++++%@", error);
        }
        [object deleteInBackground];
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadSingle:self.view:NSLocalizedString(@"Post Deleted", nil):NSLocalizedString(@"You've successfully deleted the post and all relating replies!", nil)];
        [alertVC.alertView removeFromSuperview];
        [Hud removeFromSuperview];
        
    }];
    
}

-(IBAction)tapReportReply:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedPostId2 = tmp;
    NSLog(@"-x-x-x-x-x- %@", tmp);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Report Thread", nil)
                                                                   message:NSLocalizedString(@"You are about to report this current thread. Please state the reason for this report.", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Report", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *postTitle = alert.textFields[0].text;
                                                              
                                                              if ([postTitle isEqualToString:@""]) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in the reason of the report!", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              } else {
                                                                  
                                                                  PFQuery *loadPostQuery = [PFQuery queryWithClassName:@"PostReplies"];
                                                                  [loadPostQuery whereKey:@"objectId" equalTo:clickedPostId2];
                                                                  [loadPostQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                                                      
                                                                      if(!error) {
                                                                          
                                                                          NSLog(@"-x- %@", object);
                                                                          
                                                                          PFObject *post = [PFObject objectWithClassName:@"ReportedPosts"];
                                                                          post[@"Reason"] = postTitle;
                                                                          post[@"ReportedUser"] = [PFUser currentUser];
                                                                          post[@"Content"] = object[@"ReplyContent"];
                                                                          post[@"Moderated"] = @(NO);
                                                                          post[@"ReportedPost"] = object[@"Post"];
                                                                          
                                                                          [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                              if (succeeded) {
                                                                                  PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                                                                                  [query whereKey:@"User" equalTo:[PFUser currentUser]];
                                                                                  [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                                                                                      if (!error) {
                                                                                          
                                                                                          if ([userAchie[@"KeepingThePeace"]  isEqual: @NO]) {
                                                                                              userAchie[@"KeepingThePeace"] = @YES;
                                                                                              userAchie[@"User"] = [PFUser currentUser];
                                                                                              [userAchie saveInBackground];
                                                                                              
                                                                                              [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                                                                                              [Flurry logEvent:@"User Unlocked Keeping The Peace Achievement" timed:YES];
                                                                                              
                                                                                              alertVC = [[CustomAlert alloc] init];
                                                                                              [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Keeping the Peace' achievement! Well Done!", nil)];
                                                                                              [alertVC.alertView removeFromSuperview];
                                                                                              
                                                                                          }
                                                                                      } else {
                                                                                          //
                                                                                      }
                                                                                  }];
                                                                              } else {
                                                                                  // There was a problem, check error.description
                                                                              }
                                                                          }];
                                                                          
                                                                      } else {
                                                                          
                                                                          NSLog(@"It didn't work");
                                                                          
                                                                      }
                                                                      
                                                                  }];
                                                              }
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Reason...", nil);
    }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(IBAction)tapNewReply:(id)sender {
    NSLog(@"Tap New Reply Worked");
    
    [self customPostAlert];
    
}

-(void)customThreadAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadDoubleTextLineVar:self:NSLocalizedString(@"Create New Thread", nil):NSLocalizedString(@"Start a new thread by adding a suitable thread title and content", nil):3];
    [alertVC.alertView removeFromSuperview];
}

-(void)customPostAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadTextLineVar:self:NSLocalizedString(@"Reply To Post", nil):NSLocalizedString(@"Write your reply to the current post", nil):1];
    [alertVC.alertView removeFromSuperview];
}

-(void)customPostReplyAlert {
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadTextLineVar:self:NSLocalizedString(@"Reply To The Reply", nil):NSLocalizedString(@"Write your reply to the current reply", nil):2];
    [alertVC.alertView removeFromSuperview];
}

-(void)readThreadText:(NSString*)result:(NSString*)varText:(NSString*)varBody {
    if(![result isEqualToString:@"False"]) {
        if ([varText isEqualToString:@""] && [varBody isEqualToString:@""]) {
            
            alertVC = [[CustomAlert alloc] init];
            [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in both of the fields!", nil)];
            [alertVC.alertView removeFromSuperview];
            
        } else if ([varText isEqualToString:@""]) {
            
            alertVC = [[CustomAlert alloc] init];
            [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in the title field!", nil)];
            [alertVC.alertView removeFromSuperview];
            
        } else if ([varBody isEqualToString:@""]) {
            
            alertVC = [[CustomAlert alloc] init];
            [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in the content field!", nil)];
            [alertVC.alertView removeFromSuperview];
            
        } else {
            /*PFQuery *threadQuery = [PFQuery queryWithClassName:@"Posts"];
             [threadQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError * error) {
             if (!error) {
             
             //Text
             
             }
             
             }];*/
            
            //Add the thread to Posts DB Class
            PFObject *post = [PFObject objectWithClassName:@"Posts"];
            post[@"PostTitle"] = varText;
            post[@"PostContent"] = varBody;
            post[@"OriginalPoster"] = [PFUser currentUser];
            post[@"Replies"] = @[];
            
            PFQuery *homeQuery = [PFQuery queryWithClassName:@"Locations"];
            [homeQuery whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
            [homeQuery getFirstObjectInBackgroundWithBlock:^(PFObject *location, NSError *error) {
                
                if (!error) {
                    post[@"Community"] = location;
                    [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            
                            PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                            [query whereKey:@"User" equalTo:[PFUser currentUser]];
                            [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                                if (!error) {
                                    
                                    if ([userAchie[@"SocialBuzz"]  isEqual: @NO]) {
                                        userAchie[@"SocialBuzz"] = @YES;
                                        userAchie[@"User"] = [PFUser currentUser];
                                        [userAchie saveInBackground];
                                        
                                        [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                                        [Flurry logEvent:@"User Unlocked Social Buzz Achievement" timed:YES];
                                        
                                        alertVC = [[CustomAlert alloc] init];
                                        [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Social Buzz' achievement! Well Done!", nil)];
                                        [alertVC.alertView removeFromSuperview];
                                        
                                    }
                                } else {
                                    //
                                }
                            }];
                            
                        } else {
                            // There was a problem, check error.description
                        }
                    }];
                }
            }];
            
            [self tapForumBar:self];
            
            alertVC = [[CustomAlert alloc] init];
            [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):NSLocalizedString(@"The thread has been successfully posted to the your community", nil)];
            [alertVC.alertView removeFromSuperview];
        }
    }
}

-(void)readText:(NSString*)result:(NSString*)varText:(int)selector {
    NSLog(@"%@ %@ %d", result, varText, selector);
    
    if([result isEqualToString:@"True"]) {
        if(selector == 1) {
            
            PFObject *reply = [PFObject objectWithClassName:@"PostReplies"];
            reply[@"ReplyContent"] = varText;
            reply[@"ReplyingUser"] = [PFUser currentUser];
            reply[@"Replies"] = @[];
            reply[@"Post"] = threadObj;
            [reply saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [threadObj addObject:[reply objectId] forKey:@"Replies"];
                    [threadObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error) {
                            [self refreshPost:threadObj];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):NSLocalizedString(@"The post has been successfully posted to the thread", nil)];
                            [alertVC.alertView removeFromSuperview];
                        } else {
                            NSLog(@"----Error: -- %@", error.description);
                        }
                    }];
                } else {
                    // There was a problem, check error.description
                }
            }];
            
        } else if(selector == 2) {
            
            PFObject *reply = [PFObject objectWithClassName:@"PostReplyReplies"];
            reply[@"ReplyContent"] = varText;
            reply[@"ReplyingUser"] = [PFUser currentUser];
            reply[@"Replies"] = @[];
            reply[@"Post"] = postObj;
            [reply saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [postObj addObject:[reply objectId] forKey:@"Replies"];
                    
                    [postObj saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error) {
                            [self refreshPostReplies:postObj];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):NSLocalizedString(@"The reply has been successfully posted to the post", nil)];
                            [alertVC.alertView removeFromSuperview];
                        } else {
                            NSLog(@"----Error: -- %@", error.description);
                        }
                    }];
                } else {
                    // There was a problem, check error.description
                }
            }];
            
        } else {
            NSLog(@"WHAT");
        }
        
    }
    
}

-(IBAction)refreshPost:(PFObject*)passedObj {
    
    clickedObjectId = [passedObj objectId];
    
    pageScroller4 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller4.frame = CGRectMake(0, 145, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller4.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 70);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller4.frame = CGRectMake(0, 144, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 115 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }
    
    pageScroller4.bounces = NO;
    [pageScroller4 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller4];
    
    //Load Posts Query & Loop
    
    PFQuery *query = [PFQuery queryWithClassName:@"Posts"];
    [query whereKey:@"objectId" equalTo:clickedObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            threadObj = object;
        } else {
            
        }
    }];
    
    PFQuery *originalPostQuery = [PFQuery queryWithClassName:@"Posts"];
    [originalPostQuery whereKey:@"objectId" equalTo:clickedObjectId];
    [originalPostQuery findObjectsInBackgroundWithBlock:^(NSArray *replies, NSError *error) {
        
        NSMutableArray *replyArray = [[NSMutableArray alloc] init];
        
        if (!error) {
            for (PFObject *object in replies) {
                [self showLoading];
                
                NSLog(@"ReplyTest2: %@", replies);
                
                postView1 = [[UIView alloc] init];
                postView1.frame = CGRectMake(0, -1, self.view.frame.size.width, 100);
                postView1.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
                
                [pageScroller4 addSubview:postView1];
                
                // Create New Reply
                newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    newReplyButton.frame = CGRectMake(40, 83, 230, 33);//Position of the button
                    
                } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                {
                    newReplyButton.frame = CGRectMake(45, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                {
                    newReplyButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                } else {
                    newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
                }
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                if([language containsString:@"fr"]) {
                    [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply_french"] forState:UIControlStateNormal];
                } else {
                    [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply2"] forState:UIControlStateNormal];
                }
                [newReplyButton addTarget:self action:@selector(tapNewReply:) forControlEvents:UIControlEventTouchUpInside];
                
                [postView1 addSubview:newReplyButton];
                
                UILabel *postTitleLabel = [[UILabel alloc] init];
                postTitleLabel.frame = CGRectMake(30, -5, self.view.frame.size.width - 60, 50);
                postTitleLabel.text = object[@"PostTitle"];
                postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
                postTitleLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postTitleLabel];
                
                UILabel *postContentLabel = [[UILabel alloc] init];
                postContentLabel.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 80);
                postContentLabel.text = object[@"PostContent"];
                postContentLabel.numberOfLines = 4;
                postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                postContentLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postContentLabel];
                
                UILabel *postOriginalPoster = [[UILabel alloc] init];
                postOriginalPoster.frame = CGRectMake(30, 10, self.view.frame.size.width - 60, 20);
                postOriginalPoster.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postOriginalPoster.textAlignment = NSTextAlignmentRight;
                
                [postView1 addSubview:postOriginalPoster];
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"objectId" equalTo:[object[@"OriginalPoster"] objectId]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!object) {
                        NSLog(@"This doesn't work?4");
                        [Hud removeFromSuperview];
                    } else {
                        // The find succeeded.
                        NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                        postOriginalPoster.text = postUserString;
                        NSLog(@"---------%@", object[@"username"]);
                    }
                }];
                
                replyArray = object[@"Replies"];
                NSLog(@"Reply Array: ------ %@", replyArray);
                //NSArray *tmp = [NSArray arrayWithObjects:@"NfjEO8yXWa27", @"FKLFv11dg527", nil];
                PFQuery *reply2Query = [PFQuery queryWithClassName:@"PostReplies"];
                [reply2Query whereKey:@"objectId" containedIn:replyArray];
                [reply2Query orderByDescending:@"createdAt"];
                [reply2Query findObjectsInBackgroundWithBlock:^(NSArray *replies2, NSError *error) {
                    if (!error) {
                        
                        NSLog(@"------------%lu", (unsigned long)[replies2 count]);
                        NSLog(@"Test: -------%@", replies2);
                        
                        int replyCount = 0;
                        
                        for (PFObject *object in replies2) {
                            
                            NSString *objectReplyCount = [NSString stringWithFormat:@"Replies: %lu", [object[@"Replies"] count]];
                            
                            postView = [[UIView alloc] init];
                            postView.frame = CGRectMake(70, 80 * replyCount + 130, self.view.frame.size.width, 70);
                            postView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
                            
                            [pageScroller4 addSubview:postView];
                            
                            UILabel *postTitleLabel = [[UILabel alloc] init];
                            postTitleLabel.frame = CGRectMake(30, -5, 200, 50);
                            postTitleLabel.text = object[@"ReplyContent"];
                            postTitleLabel.numberOfLines = 3;
                            postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                            postTitleLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postTitleLabel];
                            
                            UILabel *postContentLabel = [[UILabel alloc] init];
                            postContentLabel.frame = CGRectMake(30, 30, self.view.frame.size.width, 50);                            postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                            postContentLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postContentLabel];
                            
                            PFQuery *query = [PFUser query];
                            [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                            [query orderByDescending:@"createdAt"];
                            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                if (!object) {
                                    NSLog(@"This doesn't work?5");
                                    [Hud removeFromSuperview];
                                } else {
                                    // The find succeeded.
                                    NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                                    NSString *combine = [NSString stringWithFormat:@"%@ | %@", postUserString, objectReplyCount];
                                    postContentLabel.text = combine;
                                    NSLog(@"---------%@", object[@"username"]);
                                }
                            }];
                            
                            if([[PFUser currentUser].objectId isEqualToString: [object[@"ReplyingUser"] objectId]]) {
                                UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePostTapGesture:)];
                                tapGesture.minimumPressDuration = 0.5f;
                                tapGesture.allowableMovement = 100.0f;
                                [postView addGestureRecognizer:tapGesture];
                            }
                            
                            UIView *replySquare = [[UIView alloc] init];
                            replySquare.frame = CGRectMake(0, 80 * replyCount + 130, 70, 70);
                            replySquare.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            
                            [pageScroller4 addSubview:replySquare];
                            
                            newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            } else {
                                newReplyButton.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);//Position of the button
                            }
                            [newReplyButton setTitle:[object objectId] forState:UIControlStateNormal];
                            newReplyButton.titleLabel.layer.opacity = 0.0f;
                            newReplyButton.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            [newReplyButton setBackgroundImage:[UIImage imageNamed:@"ic_reply"] forState:UIControlStateNormal];
                            [newReplyButton addTarget:self action:@selector(tapOpenFurtherReplies:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [pageScroller4 addSubview:newReplyButton];
                            
                            UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                reportButton.frame = CGRectMake(250, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            }
                            [reportButton setTitle:[object objectId] forState:UIControlStateNormal];
                            reportButton.titleLabel.layer.opacity = 0.0f;
                            [reportButton setBackgroundImage:[UIImage imageNamed:@"ic_report"] forState:UIControlStateNormal];
                            [reportButton addTarget:self action:@selector(tapReportReply:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [postView addSubview:reportButton];
                            
                            replyCount++;
                            NSLog(@"ReplyCount: -------- %d", replyCount);
                        }
                    } else {
                        NSLog(@"This didnt work");
                    }
                    [Hud removeFromSuperview];
                }];
            }
        } else {
            NSLog(@"Posts not found");
        }
        
    }];
    
}

-(IBAction)refreshPostReplies:(PFObject*)passedObj {
    [self showLoading];
    
    clickedObjectId = [passedObj objectId];
    
    pageScroller4 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller4.frame = CGRectMake(0, 145, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller4.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller4.frame = CGRectMake(0, 144, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 115 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }
    
    pageScroller4.bounces = NO;
    [pageScroller4 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller4];
    
    // Create New Reply
    newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        newReplyButton.frame = CGRectMake(40, 83, 230, 33);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        newReplyButton.frame = CGRectMake(45, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        newReplyButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    } else {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply_french"] forState:UIControlStateNormal];
    } else {
        [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply2"] forState:UIControlStateNormal];
    }
    [newReplyButton addTarget:self action:@selector(tapNewReplyReplies:) forControlEvents:UIControlEventTouchUpInside];
    
    [pageScroller4 addSubview:newReplyButton];
    
    //Load Posts Query & Loop
    PFQuery *query = [PFQuery queryWithClassName:@"PostReplies"];
    [query whereKey:@"objectId" equalTo:clickedObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            postObj = object;
        }
    }];
    
    PFQuery *originalPostQuery = [PFQuery queryWithClassName:@"PostReplies"];
    [originalPostQuery whereKey:@"objectId" equalTo:clickedObjectId];
    [originalPostQuery findObjectsInBackgroundWithBlock:^(NSArray *replies, NSError *error) {
        
        NSMutableArray *replyArray = [[NSMutableArray alloc] init];
        
        if (!error) {
            
            int replyCount = 0;
            
            for (PFObject *object in replies) {
                
                NSLog(@"ReplyTest2: %@", replies);
                
                postView1 = [[UIView alloc] init];
                postView1.frame = CGRectMake(0, -1, self.view.frame.size.width, 100);
                postView1.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
                
                [pageScroller4 addSubview:postView1];
                
                UILabel *postContentLabel = [[UILabel alloc] init];
                postContentLabel.frame = CGRectMake(30, -5, self.view.frame.size.width - 60, 80);
                postContentLabel.text = object[@"ReplyContent"];
                postContentLabel.numberOfLines = 4;
                postContentLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postContentLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postContentLabel];
                
                UILabel *postOriginalPoster = [[UILabel alloc] init];
                postOriginalPoster.frame = CGRectMake(30, 50, self.view.frame.size.width - 60, 20);
                postOriginalPoster.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postOriginalPoster.textAlignment = NSTextAlignmentRight;
                
                [postView1 addSubview:postOriginalPoster];
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!object) {
                        NSLog(@"This doesn't work?1");
                        [Hud removeFromSuperview];
                    } else {
                        // The find succeeded.
                        NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                        postOriginalPoster.text = postUserString;
                        NSLog(@"---------%@", object[@"username"]);
                    }
                }];
                
                [postView1 addSubview:newReplyButton];
                
                replyArray = object[@"Replies"];
                NSLog(@"Reply Array: ------ %@", replyArray);
                
                PFQuery *reply2Query = [PFQuery queryWithClassName:@"PostReplyReplies"];
                [reply2Query whereKey:@"objectId" containedIn:replyArray];
                [reply2Query orderByDescending:@"createdAt"];
                [reply2Query findObjectsInBackgroundWithBlock:^(NSArray *replies2, NSError *error) {
                    if (!error) {
                        
                        NSLog(@"------------%lu", (unsigned long)[replies2 count]);
                        NSLog(@"Test: -------%@", replies2);
                        
                        int replyCount = 0;
                        
                        for (PFObject *object in replies2) {
                            
                            postView = [[UIView alloc] init];
                            postView.frame = CGRectMake(70, 80 * replyCount + 130, self.view.frame.size.width, 70);
                            postView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
                            
                            [pageScroller4 addSubview:postView];
                            
                            UILabel *postTitleLabel = [[UILabel alloc] init];
                            postTitleLabel.frame = CGRectMake(30, -5, 200, 50);
                            postTitleLabel.text = object[@"ReplyContent"];
                            postTitleLabel.numberOfLines = 3;
                            postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                            postTitleLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postTitleLabel];
                            
                            UILabel *postContentLabel = [[UILabel alloc] init];
                            postContentLabel.frame = CGRectMake(30, 30, self.view.frame.size.width, 50);
                            postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                            postContentLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postContentLabel];
                            
                            PFQuery *query = [PFUser query];
                            [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                            [query orderByDescending:@"createdAt"];
                            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                if (!object) {
                                    NSLog(@"This doesn't work?2");
                                    [Hud removeFromSuperview];
                                } else {
                                    // The find succeeded.
                                    NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                                    postContentLabel.text = postUserString;
                                    NSLog(@"---------%@", object[@"username"]);
                                }
                            }];
                            
                            if([[PFUser currentUser].objectId isEqualToString: [object[@"ReplyingUser"] objectId]]) {
                                UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleRepliesTapGesture:)];
                                tapGesture.minimumPressDuration = 0.5f;
                                tapGesture.allowableMovement = 100.0f;
                                [postView addGestureRecognizer:tapGesture];
                            }
                            
                            UIView *replySquare = [[UIView alloc] init];
                            replySquare.frame = CGRectMake(0, 80 * replyCount + 130, 70, 70);
                            replySquare.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            
                            [pageScroller4 addSubview:replySquare];
                            
                            UIImageView *replyReplyIcon = [[UIImageView alloc]init];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                                
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            } else {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            replyReplyIcon.image = [UIImage imageNamed:@"ic_reply_reply"];
                            replyReplyIcon.contentMode = UIViewContentModeScaleAspectFit;
                            replyReplyIcon.clipsToBounds = YES;
                            
                            [pageScroller4 addSubview:replyReplyIcon];
                            
                            UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                reportButton.frame = CGRectMake(250, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            }
                            [reportButton setTitle:[object objectId] forState:UIControlStateNormal];
                            reportButton.titleLabel.layer.opacity = 0.0f;
                            [reportButton setBackgroundImage:[UIImage imageNamed:@"ic_report"] forState:UIControlStateNormal];
                            [reportButton addTarget:self action:@selector(tapReportReplyReplies:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [postView addSubview:reportButton];
                            
                            replyCount++;
                            NSLog(@"ReplyCount: -------- %d", replyCount);
                            
                        }
                    } else {
                        NSLog(@"This didnt work");
                    }
                }];
            }
        } else {
            NSLog(@"Posts not found");
        }
        
    }];
    
    [Hud removeFromSuperview];
}

-(void)alertDeleteResponse:(NSString*)result:(NSString*)varText:(int)selector {
    NSLog(@"%@ %@ %d", result, varText, selector);
    
    if([result isEqualToString:@"True"]) {
        if(numberOfAlertVC == 1) {
            [self tappedDeleteThread:varText];
        } else if(numberOfAlertVC == 2) {
            NSLog(@"************************************");
            [self tappedDeletePost: varText];
        } else if(numberOfAlertVC == 3) {
            [self tappedDeleteReplies: varText];
        } else {
            NSLog(@"WHAT");
        }
        
    }
}


-(IBAction)tapOpenFurtherReplies:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedObjectId = tmp;
    
    [pageScroller4 removeFromSuperview];
    [postView removeFromSuperview];
    [postView1 removeFromSuperview];
    NSLog(@"OPENED: ------------------ %@", tmp);
    [self addFurtherReplyViews];
}

-(void) addFurtherReplyViews {
    [self showLoading];
    
    pageScroller4 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller4.frame = CGRectMake(0, 145, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller4.frame = CGRectMake(0, 137, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 100 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller4.frame = CGRectMake(0, 144, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 115 * postCount + 100);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    } else {
        pageScroller4.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller4.contentSize = CGSizeMake(self.view.frame.size.width, 130 * postCount + 100);
    }
    
    pageScroller4.bounces = NO;
    [pageScroller4 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller4];
    
    // Create New Reply
    newReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        newReplyButton.frame = CGRectMake(40, 83, 230, 33);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        newReplyButton.frame = CGRectMake(45, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        newReplyButton.frame = CGRectMake(73, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    } else {
        newReplyButton.frame = CGRectMake(95, 83, 230, 33);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply_french"] forState:UIControlStateNormal];
    } else {
        [newReplyButton setBackgroundImage:[UIImage imageNamed:@"btn_reply2"] forState:UIControlStateNormal];
    }
    [newReplyButton addTarget:self action:@selector(tapNewReplyReplies:) forControlEvents:UIControlEventTouchUpInside];
    
    [pageScroller4 addSubview:newReplyButton];
    
    //Load Posts Query & Loop
    PFQuery *query = [PFQuery queryWithClassName:@"PostReplies"];
    [query whereKey:@"objectId" equalTo:clickedObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            postObj = object;
        }
    }];
    
    PFQuery *originalPostQuery = [PFQuery queryWithClassName:@"PostReplies"];
    [originalPostQuery whereKey:@"objectId" equalTo:clickedObjectId];
    [originalPostQuery findObjectsInBackgroundWithBlock:^(NSArray *replies, NSError *error) {
        
        NSMutableArray *replyArray = [[NSMutableArray alloc] init];
        
        if (!error) {
            
            int replyCount = 0;
            
            for (PFObject *object in replies) {
                
                NSLog(@"ReplyTest2: %@", replies);
                
                postView1 = [[UIView alloc] init];
                postView1.frame = CGRectMake(0, -1, self.view.frame.size.width, 100);
                postView1.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
                
                [pageScroller4 addSubview:postView1];
                
                UILabel *postContentLabel = [[UILabel alloc] init];
                postContentLabel.frame = CGRectMake(30, -5, self.view.frame.size.width - 60, 80);
                postContentLabel.text = object[@"ReplyContent"];
                postContentLabel.numberOfLines = 4;
                postContentLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postContentLabel.textAlignment = NSTextAlignmentLeft;
                
                [postView1 addSubview:postContentLabel];
                
                UILabel *postOriginalPoster = [[UILabel alloc] init];
                postOriginalPoster.frame = CGRectMake(30, 50, self.view.frame.size.width - 60, 20);
                postOriginalPoster.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                postOriginalPoster.textAlignment = NSTextAlignmentRight;
                
                [postView1 addSubview:postOriginalPoster];
                
                PFQuery *query = [PFUser query];
                [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!object) {
                        NSLog(@"This doesn't work?1");
                        [Hud removeFromSuperview];
                    } else {
                        // The find succeeded.
                        NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                        postOriginalPoster.text = postUserString;
                        NSLog(@"---------%@", object[@"username"]);
                    }
                }];
                
                [postView1 addSubview:newReplyButton];
                
                replyArray = object[@"Replies"];
                NSLog(@"Reply Array: ------ %@", replyArray);
                
                PFQuery *reply2Query = [PFQuery queryWithClassName:@"PostReplyReplies"];
                [reply2Query whereKey:@"objectId" containedIn:replyArray];
                [reply2Query orderByDescending:@"createdAt"];
                [reply2Query findObjectsInBackgroundWithBlock:^(NSArray *replies2, NSError *error) {
                    if (!error) {
                        
                        NSLog(@"------------%lu", (unsigned long)[replies2 count]);
                        NSLog(@"Test: -------%@", replies2);
                        
                        int replyCount = 0;
                        
                        for (PFObject *object in replies2) {
                            
                            postView = [[UIView alloc] init];
                            postView.frame = CGRectMake(70, 80 * replyCount + 130, self.view.frame.size.width, 70);
                            postView.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
                            
                            [pageScroller4 addSubview:postView];
                            
                            UILabel *postTitleLabel = [[UILabel alloc] init];
                            postTitleLabel.frame = CGRectMake(30, -5, 200, 50);
                            postTitleLabel.text = object[@"ReplyContent"];
                            postTitleLabel.numberOfLines = 3;
                            postTitleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
                            postTitleLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postTitleLabel];
                            
                            UILabel *postContentLabel = [[UILabel alloc] init];
                            postContentLabel.frame = CGRectMake(30, 30, self.view.frame.size.width, 50);
                            postContentLabel.font = [UIFont fontWithName:@"OpenSans" size:10];
                            postContentLabel.textAlignment = NSTextAlignmentLeft;
                            
                            [postView addSubview:postContentLabel];
                            
                            PFQuery *query = [PFUser query];
                            [query whereKey:@"objectId" equalTo:[object[@"ReplyingUser"] objectId]];
                            [query orderByDescending:@"createdAt"];
                            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                if (!object) {
                                    NSLog(@"This doesn't work?2");
                                    [Hud removeFromSuperview];
                                } else {
                                    // The find succeeded.
                                    NSString *postUserString = [NSString stringWithFormat:@"by: %@", object[@"username"]];
                                    postContentLabel.text = postUserString;
                                    NSLog(@"---------%@", object[@"username"]);
                                }
                            }];
                            
                            if([[PFUser currentUser].objectId isEqualToString: [object[@"ReplyingUser"] objectId]]) {
                                UILongPressGestureRecognizer *tapGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleRepliesTapGesture:)];
                                tapGesture.minimumPressDuration = 0.5f;
                                tapGesture.allowableMovement = 100.0f;
                                [postView addGestureRecognizer:tapGesture];
                            }
                            
                            UIView *replySquare = [[UIView alloc] init];
                            replySquare.frame = CGRectMake(0, 80 * replyCount + 130, 70, 70);
                            replySquare.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
                            
                            [pageScroller4 addSubview:replySquare];
                            
                            UIImageView *replyReplyIcon = [[UIImageView alloc]init];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                                
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            } else {
                                replyReplyIcon.frame = CGRectMake(15, 80 * replyCount + 150, 36, 30);
                            }
                            replyReplyIcon.image = [UIImage imageNamed:@"ic_reply_reply"];
                            replyReplyIcon.contentMode = UIViewContentModeScaleAspectFit;
                            replyReplyIcon.clipsToBounds = YES;
                            
                            [pageScroller4 addSubview:replyReplyIcon];
                            
                            UIButton *reportButton = [UIButton buttonWithType:UIButtonTypeCustom];
                            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                                
                            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
                            {
                                reportButton.frame = CGRectMake(220, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
                            {
                                reportButton.frame = CGRectMake(250, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                            {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            } else {
                                reportButton.frame = CGRectMake(280, 25, 20, 20);//Position of the button
                            }
                            [reportButton setTitle:[object objectId] forState:UIControlStateNormal];
                            reportButton.titleLabel.layer.opacity = 0.0f;
                            [reportButton setBackgroundImage:[UIImage imageNamed:@"ic_report"] forState:UIControlStateNormal];
                            [reportButton addTarget:self action:@selector(tapReportReplyReplies:) forControlEvents:UIControlEventTouchUpInside];
                            
                            [postView addSubview:reportButton];
                            
                            replyCount++;
                            NSLog(@"ReplyCount: -------- %d", replyCount);
                            
                        }
                    } else {
                        NSLog(@"This didnt work");
                    }
                }];
            }
        } else {
            NSLog(@"Posts not found");
        }
        
    }];
    
    [Hud removeFromSuperview];
    
}

- (void)handleRepliesTapGesture:(UITapGestureRecognizer *)sender {
    NSLog(@"%@", sender.view);
    UIView *tmp = (UIView*) sender.view;
    UIButton *button;
    for (UIView *subview in tmp.subviews)
    {
        if([subview isKindOfClass:[UIButton class]]) {
            button =  (UIButton*)subview;
            break;
        }
    }
    if (sender.state == UIGestureRecognizerStateRecognized) {
        numberOfAlertVC = 3;
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadDeletePost:self:NSLocalizedString(@"Delete Thread", nil):NSLocalizedString(@"Are you sure you want to permanantly delete the current thread?", nil):button.titleLabel.text:3];
        [alertVC.alertView removeFromSuperview];
        
    }
}

-(void) tappedDeleteReplies: (NSString*) objectRepliesId {
    [self showLoading];
    PFQuery *postQuery = [PFQuery queryWithClassName:@"PostReplyReplies"];
    [postQuery whereKey:@"objectId" equalTo:objectRepliesId];
    [postQuery whereKey:@"ReplyingUser" equalTo:[PFUser currentUser]];
    [postQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            
            //            PFQuery *replyQuery = [PFQuery queryWithClassName:@"PostReplies"];
            //            [replyQuery whereKey:@"objectId" equalTo:object[@"PostReplies"]];
            //            [replyQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object2, NSError *error2) {
            //                if(!error) {
            //                    NSLog(@"POSTOBJECTS = %@", object2);
            //                } else {
            //                    NSLog(@"%@", error2);
            //                }
            //
            //            }];
            
            
            [Hud removeFromSuperview];
        } else {
            [Hud removeFromSuperview];
            NSLog(@"%@", error);
        }
        [object deleteInBackground];
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadSingle:self.view:NSLocalizedString(@"Post Deleted", nil):NSLocalizedString(@"You've successfully deleted the reply!", nil)];
        [alertVC.alertView removeFromSuperview];
        
    }];
    
}

-(IBAction)tapReportReplyReplies:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedPostId2 = tmp;
    NSLog(@"-x-x-x-x-x- %@", tmp);
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Report Reply", nil)
                                                                   message:NSLocalizedString(@"You are about to report this current reply. Please state the reason for this report.", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Report", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *postTitle = alert.textFields[0].text;
                                                              
                                                              if ([postTitle isEqualToString:@""]) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You need to fill in the reason of the report!", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              } else {
                                                                  
                                                                  PFQuery *loadPostQuery = [PFQuery queryWithClassName:@"PostReplyReplies"];
                                                                  [loadPostQuery whereKey:@"objectId" equalTo:clickedPostId2];
                                                                  [loadPostQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                                                      
                                                                      if(!error) {
                                                                          
                                                                          PFObject *post = [PFObject objectWithClassName:@"ReportedPosts"];
                                                                          post[@"Reason"] = postTitle;
                                                                          post[@"ReportedUser"] = [PFUser currentUser];
                                                                          post[@"Content"] = object[@"ReplyContent"];
                                                                          post[@"Moderated"] = @(NO);
                                                                          
                                                                          [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                              if (succeeded) {
                                                                                  PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                                                                                  [query whereKey:@"User" equalTo:[PFUser currentUser]];
                                                                                  [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                                                                                      if (!error) {
                                                                                          
                                                                                          if ([userAchie[@"KeepingThePeace"]  isEqual: @NO]) {
                                                                                              userAchie[@"KeepingThePeace"] = @YES;
                                                                                              userAchie[@"User"] = [PFUser currentUser];
                                                                                              [userAchie saveInBackground];
                                                                                              
                                                                                              [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                                                                                              [Flurry logEvent:@"User Unlocked Keeping The Peace Achievement" timed:YES];
                                                                                              
                                                                                              alertVC = [[CustomAlert alloc] init];
                                                                                              [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Keeping the Peace' achievement! Well Done!", nil)];
                                                                                              [alertVC.alertView removeFromSuperview];
                                                                                              
                                                                                          }
                                                                                      } else {
                                                                                          //
                                                                                      }
                                                                                  }];
                                                                              } else {
                                                                                  // There was a problem, check error.description
                                                                              }
                                                                          }];
                                                                          
                                                                      } else {
                                                                          
                                                                          NSLog(@"It didn't work");
                                                                          
                                                                      }
                                                                      
                                                                  }];
                                                              }
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = NSLocalizedString(@"Reason...", nil);
    }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(IBAction)tapNewReplyReplies:(id)sender {
    NSLog(@"Tap New Reply Worked");
    
    [self customPostReplyAlert];
    
}

-(void)loadParseContent{
    // Create the UI Scroll View
    
    [pageScroller removeFromSuperview];
    [Hud removeFromSuperview];
    
    pageScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 180);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 180);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0, 160, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 175, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 220);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 175, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 220);
    } else {
        pageScroller.frame = CGRectMake(0, 175, self.view.frame.size.width, self.view.frame.size.height-50);
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 220);
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    pageScroller.bounces = NO;
    [pageScroller setShowsVerticalScrollIndicator:NO];
    //[pageScroller setPagingEnabled : YES];
    [self.view addSubview:pageScroller];
    
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

#pragma mark - Keyboard Handling

//Shows the Keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

//Handles how the keyboard is shown
- (void)keyboardWasShown:(NSNotification *)notification
{
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        //Get the size of the keyboard.
        //CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
        
        //Adjust the bottom content inset of the scroll view by the keyboard height.
        CGPoint point = CGPointMake(0.0, userTextField.frame.origin.y - (keyboardSize.height+50));
        CGRect frame = tmpView.frame;
        frame.origin = point;
        tmpView.frame = frame;
        
        
    }
    
}

//Handles how to hide the keyboard
- (void) keyboardWillHide:(NSNotification *)notification {
    userTextField.text = [userTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    userTextField.text = [userTextField.text lowercaseString];
    //    userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet letterCharacterSet] invertedSet]] componentsJoinedByString:@""];
    userTextField.text = [[userTextField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        tmpView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        
    }
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
    
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Community"];
    
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
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Dashboard"];
    
    [sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
    
    [defaults setInteger:[[arrayOfActiveViews objectAtIndex:anIndex] intValue] forKey:@"sideScrollerOffSet"];
}

-(void)dismissKeyboard
{
    if(alertVC != nil) {
        //Needs revising!!
        //[alertVC resignFocus];
    }
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
