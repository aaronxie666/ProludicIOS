//
//  ProfileViewController.m
//  Proludic
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "ProfileViewController.h"
#import "CustomAlert.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"

@interface ProfileViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation ProfileViewController{
    UIView *tmpView;
    UIView *popUpView;
    UIImageView *profilePicture;
    UIImageView *achievementImageView;
    UIImageView *userStatus;
    UIImage *selectedProfileImage;
    UIScrollView *sideScroller;
    UIScrollView *friendsSideScroller;
    UIView *topView;
    UIView *statView1;
    UIView *statView2;
    UIView *statView3;
    UIView *statView4;
    UIScrollView *pageScroller;
    UIScrollView *pageScroller2;
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
    NSMutableArray *achievementPhotos;
    NSMutableArray *achievementObjectIds;
    NSArray *friendIds;
    NSMutableArray *achievementImages;
    
    IBOutlet UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    
    NSString *todayHearts;
    NSString *todayExercises;
    NSString *dateWeekString;
    NSString *dateMonthString;
    NSString *clickedObjectId;
    
    UICollectionView *cv;
    
    //PFObjects
    PFObject *selectedMatchObject;
    PFObject *selectedOpponent;
    PFObject *achievementsObject;
    
    //AnimationImage
    UIImageView *glowImageView;
    
    UIButton *view1;
    UIButton *view2;
    UIButton *view3;
    UIButton *view4;
    
    UITextView *descTextView;
    UIView *backFriendRequestview;
    UIScrollView *friendRequestScroller;
    UIScrollView *challengeScroller;
    UIScrollView *challengedScroller;
    int challengeType;
    int challengeDuration;
    
    //Custom Alert
    CustomAlert *alertVC;
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
    
    [Flurry logEvent:@"User Opened Profile Page" timed:YES];
    isOpenChallengePage = 0;
    
    //Achievement Check
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"objectId" equalTo: [PFUser currentUser].objectId];
    [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userObj, NSError *error) {
        if (!error) {
            if ([userObj[@"wins"] intValue] > 1) {
                
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"Victorious"]  isEqual: @NO]) {
                            userAchie[@"Victorious"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                            [Flurry logEvent:@"User Unlocked Victorious Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Victorious' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
                
            } else {
                NSLog(@"Not enough wins");
            }
            
            if (userObj[@"wins"] > 0 || userObj[@"loss"] > 0 || userObj[@"draw"] > 0) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ChallengeBegin"]  isEqual: @NO]) {
                            userAchie[@"ChallengeBegin"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                            [Flurry logEvent:@"User Unlocked Challenge Begin Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Challenge Begin' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 25) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicCopper"]  isEqual: @NO]) {
                            userAchie[@"ProludicCopper"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                            [Flurry logEvent:@"User Unlocked Proludic Copper Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Copper' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 50) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicBronze"]  isEqual: @NO]) {
                            userAchie[@"ProludicBronze"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 250);
                            [Flurry logEvent:@"User Unlocked Proludic Bronze Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Bronze' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 75) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicSilver"]  isEqual: @NO]) {
                            userAchie[@"ProludicSilver"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 300);
                            [Flurry logEvent:@"User Unlocked Proludic Silver Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Silver' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 100) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicGold"]  isEqual: @NO]) {
                            userAchie[@"ProludicGold"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 350);
                            [Flurry logEvent:@"User Unlocked Proludic Gold Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Gold' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 150) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicPlatinum"]  isEqual: @NO]) {
                            userAchie[@"ProludicPlatinum"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 400);
                            [Flurry logEvent:@"User Unlocked Proludic Platinum Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Platinum' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalNonWeightExercises"] intValue] > 200) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"ProludicDiamond"]  isEqual: @NO]) {
                            userAchie[@"ProludicDiamond"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 450);
                            [Flurry logEvent:@"User Unlocked Proludic Diamond Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Proludic Diamond' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 25) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightCopper"]  isEqual: @NO]) {
                            userAchie[@"BodyweightCopper"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                            [Flurry logEvent:@"User Unlocked Bodyweight Copper Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Copper' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 50) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightBronze"]  isEqual: @NO]) {
                            userAchie[@"BodyweightBronze"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 250);
                            [Flurry logEvent:@"User Unlocked Bodyweight Bronze Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Bronze' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 75) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightSilver"]  isEqual: @NO]) {
                            userAchie[@"BodyweightSilver"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 300);
                            [Flurry logEvent:@"User Unlocked Bodyweight Silver Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Silver' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 100) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightGold"]  isEqual: @NO]) {
                            userAchie[@"BodyweightGold"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 350);
                            [Flurry logEvent:@"User Unlocked Bodyweight Gold Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Gold' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 150) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightPlatinum"]  isEqual: @NO]) {
                            userAchie[@"BodyweightPlatinum"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 400);
                            [Flurry logEvent:@"User Unlocked Bodyweight Platinum Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Platinum' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
            if ([userObj[@"TotalWeightExercises"] intValue] > 200) {
                PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                [query whereKey:@"User" equalTo:[PFUser currentUser]];
                [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                    if (!error) {
                        
                        if ([userAchie[@"BodyweightDiamond"]  isEqual: @NO]) {
                            userAchie[@"BodyweightDiamond"] = @YES;
                            userAchie[@"User"] = [PFUser currentUser];
                            [userAchie saveInBackground];
                            
                            [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 450);
                            [Flurry logEvent:@"User Unlocked Bodyweight Diamond Achievement" timed:YES];
                            
                            alertVC = [[CustomAlert alloc] init];
                            [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Bodyweight Diamond' achievement! Well Done!", nil)];
                            [alertVC.alertView removeFromSuperview];
                            
                        }
                        
                    } else {
                        //
                    }
                }];
            } else {
                NSLog(@"Not Enough Achievements");
            }
            
        } else {
            NSLog(@"ERROR: %@", error.description);
        }
    }];
    
    
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
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 280);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 93, self.view.frame.size.width, 500); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 240);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 210);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-100); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 160);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 10);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        pageScroller.frame = CGRectMake(0, 138, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 10);
    } else {
        pageScroller.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-90); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 10);
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
        if (i == 2) { // Home
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
    
    // Create the UI Side Scroll View
    friendsSideScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendsSideScroller.frame = CGRectMake(-5, 166, self.view.frame.size.width+20, 95); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        friendsSideScroller.frame = CGRectMake(-5, 166, self.view.frame.size.width+20, 95); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        friendsSideScroller.frame = CGRectMake(-5, 176, self.view.frame.size.width+20, 100); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendsSideScroller.frame = CGRectMake(-5, 186, self.view.frame.size.width+20, 105); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendsSideScroller.frame = CGRectMake(-5, 186, self.view.frame.size.width+20, 105); //Position of the scroller
    } else {
        friendsSideScroller.frame = CGRectMake(-5, 186, self.view.frame.size.width+20, 105); //Position of the scroller
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
    [pageScroller addSubview:friendsSideScroller];
    
    //STAT NAV BAR
    //RECTANGLES
    
    CGRect frame1;
    CGRect frame2;
    CGRect frame3;
    CGRect frame4;
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        frame1 = CGRectMake( -25, 241, 125.0, 50.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -25, 241, 125.0, 50.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -25, 241, 125.0, 50.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -25, 241, 125, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        frame1 = CGRectMake( -25, 241, 125.0, 50.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -25, 241, 125.0, 50.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -25, 241, 125.0, 50.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -25, 241, 125, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        frame1 = CGRectMake( -15, 266, 125.0, 50.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -15, 266, 125.0, 50.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -15, 266, 125.0, 50.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -15, 266, 125, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        frame1 = CGRectMake( -15, 269, 125.0, 75.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -15, 269, 125.0, 75.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -15, 269, 125.0, 75.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -15, 269, 125, 75.0);
    }else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        frame1 = CGRectMake( -15, 279, 125.0, 65.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -15, 279, 125.0, 65.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -15, 279, 125.0, 65.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -15, 279, 125, 65.0);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        frame1 = CGRectMake( -15, 279, 125.0, 65.0);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -15, 279, 125.0, 65.0);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -15, 279, 125.0, 65.0);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -15, 279, 125, 65.0);
    } else {
        frame1 = CGRectMake( -15, 279, 125.0, 65);
        frame2 = CGRectMake( self.view.frame.size.width / 4 -15, 279, 125, 65);
        frame3 = CGRectMake( self.view.frame.size.width / 4 * 2 -15, 279, 125, 65);
        frame4 = CGRectMake( self.view.frame.size.width / 4 * 3 -15, 279, 125, 65);
    }
    
    
    view1 = [[UIButton alloc] initWithFrame:frame1];
    view2 = [[UIButton alloc] initWithFrame:frame2];
    view3 = [[UIButton alloc] initWithFrame:frame3];
    view4 = [[UIButton alloc] initWithFrame:frame4];
    
    [view1 setBackgroundColor:[UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0]];
    [view2 setBackgroundColor:[UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0]];
    [view3 setBackgroundColor:[UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0]];
    [view4 setBackgroundColor:[UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:1.0]];
    
    
    [view1 setTitle:NSLocalizedString(@"Today", nil) forState:UIControlStateNormal];
    [view2 setTitle:NSLocalizedString(@"Weekly", nil) forState:UIControlStateNormal];
    [view3 setTitle:NSLocalizedString(@"Monthly", nil) forState:UIControlStateNormal];
    [view4 setTitle:NSLocalizedString(@"All Time", nil) forState:UIControlStateNormal];
    
    [view1 addTarget:self action:@selector(tapTodayBar:) forControlEvents:UIControlEventTouchUpInside];
    [view2 addTarget:self action:@selector(tapWeeklyBar:) forControlEvents:UIControlEventTouchUpInside];
    [view3 addTarget:self action:@selector(tapMonthlyBar:) forControlEvents:UIControlEventTouchUpInside];
    [view4 addTarget:self action:@selector(tapAllTimeBar:) forControlEvents:UIControlEventTouchUpInside];
    
    [view1 setTitleColor: [UIColor orangeColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view4 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:12]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
    } else {
        [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
        [view4.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:18]];
    }
    
    [pageScroller addSubview:view1];
    [pageScroller addSubview:view2];
    [pageScroller addSubview:view3];
    [pageScroller addSubview:view4];
    
    
    [self loadParseContent];
    
    //LOOP TO LOAD CONTENT ON LOAD ONCE
    int x = 0;
    if (x == 0) {
        [self tapAllTimeBar:self];
        x++;
    }
    
    //Achievement Grid
    UICollectionViewFlowLayout* vfl = [[UICollectionViewFlowLayout alloc] init];
    [vfl setScrollDirection:UICollectionViewScrollDirectionVertical];
    //[vfl setItemSize:CGSizeMake(200,200)];
    
    //ACHIEVEMENTS
    UILabel *yourAchievementsLabel = [[UILabel alloc]init];
    yourAchievementsLabel.textColor = [UIColor blackColor];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourAchievementsLabel.frame = CGRectMake(0, 420, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 450, self.view.frame.size.width, 300) collectionViewLayout:vfl];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourAchievementsLabel.frame = CGRectMake(0, 430, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 460, self.view.frame.size.width, 300) collectionViewLayout:vfl];
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourAchievementsLabel.frame = CGRectMake(0, 520, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 580, self.view.frame.size.width, 300) collectionViewLayout:vfl];
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        yourAchievementsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 550, self.view.frame.size.width, 300) collectionViewLayout:vfl];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourAchievementsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 550, self.view.frame.size.width, 300) collectionViewLayout:vfl];
    } else {
        yourAchievementsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourAchievementsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 20);
        cv = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 550, self.view.frame.size.width, 300) collectionViewLayout:vfl];
    }
    yourAchievementsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"your achievements", nil)];
    yourAchievementsLabel.numberOfLines = 4;
    yourAchievementsLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:yourAchievementsLabel];
    achievementPhotos = [[NSMutableArray alloc] init];
    achievementObjectIds = [[NSMutableArray alloc] init];
    cv.delegate = self;
    cv.dataSource = self;
    cv.backgroundColor = [UIColor clearColor];
    
    NSDictionary *translateEngToFren = @{@"Registration" : @"Enregistrement",
                                         @"GettingStarted" : @"Mise en route",
                                         @"BurjKhalifa" : @"Burj Khalifa",
                                         @"EmpireStateBuilding" :@"Empire State Building",
                                         @"EiffelTower" : @"Tour Eiffel",
                                         @"LondonEye":@"London Eye",
                                         @"WhaleShark":@"Requin baleine",
                                         @"AfricanElephant":@"Éléphant africain",
                                         @"AsianElephant":@"Éléphant d'Asie",
                                         @"WhiteRhinoceros":@"Rhinocéros blanc",
                                         @"Hippopotamus":@"Hippopotame",
                                         @"Giraffe":@"Girafe",
                                         @"ProludicDiamond":@"Proludic Diamant",
                                         @"BodyweightDiamond":@"Poids Diamant",
                                         @"BodyweightPlatinum":@"Poids Platine",
                                         @"Crocodile":@"Crocodile",
                                         @"ProludicPlatinum":@"Proludic Platine",
                                         @"AsianGuar":@"Gaur asiatique",
                                         @"BodyweightGold":@"Poids Or",
                                         @"ProludicGold":@"Proludic Or",
                                         @"BodyweightSilver":@"Poids Argent",
                                         @"ProludicSilver":@"Proludic Argent",
                                         @"BodyweightBronze":@"Poids Bronze",
                                         @"ProludicBronze":@"Proludic Bronze",
                                         @"KodiakBear":@"Ours Kodiak",
                                         @"ChallengeBegin":@"Début du défi !",
                                         @"WorkingOut":@"Entrainement",
                                         @"SocialBuzz":@"Faire le buzz",
                                         @"GoldenGateBridge":@"Golden Gate Bridge",
                                         @"Victorious":@"Victoire",
                                         @"Socialize":@"Partager",
                                         @"ProludicCopper":@"Proludic Cuivre",
                                         @"WeeklyWorker":@"Performeur de la semaine",
                                         @"KeepingthePeace":@"Préserver la paix !",
                                         @"ProfilePerfect":@"Profil parfait",
                                         @"BodyweightCopper":@"Poids Cuivre"
                                         };
    
    PFQuery *achieQuery = [PFQuery queryWithClassName:@"Achievements"];
    [achieQuery orderByAscending:@"HeartsReceived"];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    [achieQuery whereKey:@"isFrench" notEqualTo:[NSNumber numberWithBool:YES]];
    [achieQuery findObjectsInBackgroundWithBlock:^(NSArray *achievementObjects, NSError *error) {
        if (error) {
            NSLog(@"Achievements Query Failed");
        } else {
            NSLog(@"Achievements Loaded.. Objects count = %d",[achievementObjects count]);
            PFQuery *achieQuery2 = [PFQuery queryWithClassName:@"UserAchievements"];
            
            [achieQuery2 whereKey:@"User" equalTo:[PFUser currentUser]];
            [achieQuery2 getFirstObjectInBackgroundWithBlock:^(PFObject *detail, NSError *error2) {
                if (!error2) {
                    __block UIImage *img1;
                    int count = 0;
                    for (PFObject *object in achievementObjects) {
                        UIImageView* tmp = [[UIImageView alloc] init];
                        NSString *criteria = [object[@"AchievementName"] stringByReplacingOccurrencesOfString:@" " withString:@""];
                        PFFile *imageFile = [object objectForKey:@"AchievementImage"];
                        
                        dispatch_async(dispatch_get_global_queue(0,0), ^{
                            
                            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                            if ( data == nil )
                                return;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                img1 = [UIImage imageWithData:data];
                                //NSLog(@"WTFFFFFFFFFFFFFFFFF %@ %@",[detail objectId],criteria);
                                //NSLog([detail[criteria] boolValue] ? @"Yes" : @"No");
                                if([detail[criteria] boolValue]) {
                                    tmp.image = img1;
                                } else {
                                    UIImage *img2 = [UIImage imageNamed:@"lock"];
                                    tmp.image = [self imageByCombiningImage:img1 withImage:img2];
                                }
                                
                            });
                        });
                        
                        //NSLog(@"count: %i", achievementCount);
                        achievementCount = achievementCount + 1;
                        [achievementPhotos addObject:tmp];
                        if([language containsString:@"fr"]) {
                            if([detail[criteria] boolValue]) {
                                NSString *frenCriteria = translateEngToFren[criteria];
                                PFQuery *achieQuery3 = [PFQuery queryWithClassName:@"Achievements"];
                                [achieQuery3 whereKey:@"AchievementName" equalTo:frenCriteria];
                                [achieQuery3 whereKey:@"isFrench" equalTo:[NSNumber numberWithBool:YES]];
                                [achieQuery3 getFirstObjectInBackgroundWithBlock:^(PFObject *frenObj, NSError *frenError) {
                                    if (frenError) {
                                        NSLog(@"Achievements Query Failed");
                                    } else {
                                        //NSLog(@"------------------ %@ , %@",frenCriteria, [frenObj objectId]);
                                        if([[achievementObjectIds objectAtIndex:count] isEqualToString:@""]) {
                                            [achievementObjectIds replaceObjectAtIndex:count withObject:[frenObj objectId]];
                                            [achievementObjectIds addObject:@""];
                                        }
                                    }}];
                            } else {
                                [achievementObjectIds addObject:@""];
                            }
                        } else {
                            if([detail[criteria] boolValue]) {
                                [achievementObjectIds addObject:[object objectId]];
                            } else {
                                [achievementObjectIds addObject:@""];
                            }
                        }
                        
                        
                        
                        count++;
                    }
                    
                    [cv registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
                    
                    [pageScroller addSubview:cv];
                    
                }
            }];
            
        }
    }];
    
    UIView *historyView = [[UIView alloc] init];
    historyView.frame = CGRectMake(70, 450, self.view.frame.size.width - 140, 35);
    [pageScroller addSubview:historyView];
    
    UIButton *trackedEventsBtn = [[UIButton alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        trackedEventsBtn.frame = CGRectMake(0, 0, self.view.frame.size.width - 140, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568) {
        trackedEventsBtn.frame = CGRectMake(0, 0, self.view.frame.size.width - 140, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) {
        trackedEventsBtn.frame = CGRectMake(0, 0, self.view.frame.size.width - 140, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) {
        trackedEventsBtn.frame = CGRectMake(0, 40, self.view.frame.size.width - 140, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        trackedEventsBtn.frame = CGRectMake(0, 10, self.view.frame.size.width - 140, 35);
    } else {
        trackedEventsBtn.frame = CGRectMake(0, 10, self.view.frame.size.width - 140, 35);
    }
    if([language containsString:@"fr"]) {
        [trackedEventsBtn setBackgroundImage:[UIImage imageNamed:@"btn_workouthistory_french"] forState:UIControlStateNormal];
    } else {
        [trackedEventsBtn setBackgroundImage:[UIImage imageNamed:@"btn_workouthistory"] forState:UIControlStateNormal];
    }
    [trackedEventsBtn addTarget:self action:@selector(tapTrackedEvents) forControlEvents:UIControlEventTouchUpInside];
    [historyView addSubview:trackedEventsBtn];
    
}
- (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage {
    UIImage *image = nil;
    
    CGSize newImageSize = CGSizeMake(MAX(firstImage.size.width, secondImage.size.width), MAX(firstImage.size.height, secondImage.size.height));
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(newImageSize);
    }
    [firstImage drawAtPoint:CGPointMake(roundf((newImageSize.width-firstImage.size.width)/2),
                                        roundf((newImageSize.height-firstImage.size.height)/2))];
    [secondImage drawAtPoint:CGPointMake(roundf((newImageSize.width-secondImage.size.width)/2),
                                         roundf((newImageSize.height-secondImage.size.height)/2))];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [achievementPhotos count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell=[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    UIButton *reloadButton = [[UIButton alloc]init];
    reloadButton.frame = CGRectMake(0, 0, self.view.frame.size.width /3 - 8, self.view.frame.size.width /3 - 8);
    reloadButton.backgroundColor = [UIColor clearColor];
    [reloadButton setTag:indexPath.item];
    
    //NSLog(@"----------------%@",achievementObjectIds);
    
    if(![[achievementObjectIds objectAtIndex:indexPath.item] isEqualToString:@""]) {
        [reloadButton setTitle:[achievementObjectIds objectAtIndex:indexPath.item] forState:UIControlStateNormal];
        [reloadButton addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
        reloadButton.titleLabel.layer.opacity = 0.0f;
    }
    
    
    [cell.self addSubview:reloadButton];
    
    UIImageView *test = [[UIImageView alloc] init];
    //test.image = [UIImage imageNamed:@"Heart"];//[achievementPhotos objectAtIndex:indexPath.row];
    if([[achievementPhotos objectAtIndex:indexPath.row] image] != nil) {
        test.image = [[achievementPhotos objectAtIndex:indexPath.item] image];
        cell.backgroundView = test;
        
    } else {
        cell.backgroundView = [achievementPhotos objectAtIndex:indexPath.item];
    }
    //[self.view addSubview:achievementImageView];
    cell.hidden = FALSE;
    
    return cell;
    
    
}
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}
-(IBAction) reload:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    [self setupAchievementGrid: tmp];
    
    
}
-(void) setupAchievementGrid: (NSString*) objectId {
    [self showLoading];
    pageScroller.scrollEnabled = NO;
    for(UIView *subview in [pageScroller subviews]) {
        subview.userInteractionEnabled = NO;
    }
    backFriendRequestview = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [backFriendRequestview setBackgroundColor:[UIColor blackColor]];
    backFriendRequestview.layer.zPosition = 1;
    backFriendRequestview.alpha = 0.95;
    backFriendRequestview.userInteractionEnabled = YES;
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setBackgroundColor:[UIColor clearColor]];
    back.tag = 0;
    [back addTarget:self action:@selector(backTappedFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
    [back setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
    [backFriendRequestview addSubview:back];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        
        [back setFrame:CGRectMake(self.view.frame.size.width - 47, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    } else {
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
        [UIView animateWithDuration:0.5f // This can be changed.
                         animations:^
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }
                         completion:^(BOOL finished)
         {
             [backFriendRequestview setFrame:CGRectMake(0, 90, self.view.frame.size.width, self.view.frame.size.height)];
         }];
    }
    UIImageView *achievementPicture = [[UIImageView alloc]init];
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.numberOfLines = 10;
    UILabel *descLabel2 = [[UILabel alloc] init];
    descLabel2.numberOfLines = 20;
    
    
    descLabel.textAlignment = NSTextAlignmentCenter;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 100, 100, 100);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        descLabel.frame = CGRectMake(0, 30, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:14];
        descLabel2.frame = CGRectMake(10, 250, self.view.frame.size.width-20, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 150, 100, 100);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        descLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:14];
        descLabel2.frame = CGRectMake(10, 270, self.view.frame.size.width - 20, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 60, 160, 120, 120);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        descLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:16];
        descLabel2.frame = CGRectMake(10, 330, self.view.frame.size.width - 20, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 60, 160, 120, 120);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        descLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:16];
        descLabel2.frame = CGRectMake(10, 330, self.view.frame.size.width - 20, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 60, 160, 120, 120);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        descLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:16];
        descLabel2.frame = CGRectMake(10, 330, self.view.frame.size.width - 20, 50);
    } else {
        achievementPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 60, 160, 120, 120);
        descLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        descLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 50);
        descLabel2.font = [UIFont fontWithName:@"Open Sans" size:16];
        descLabel2.frame = CGRectMake(10, 330, self.view.frame.size.width - 20, 50);
    }
    
    achievementPicture.clipsToBounds = YES;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.textColor = [UIColor whiteColor];
    descLabel2.textAlignment = NSTextAlignmentCenter;
    descLabel2.textColor = [UIColor whiteColor];
    
    PFQuery *getIdQuery = [PFQuery queryWithClassName:@"Achievements"];
    [getIdQuery whereKey:@"objectId" equalTo:objectId];
    [getIdQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            
            PFFile *imageFile = [object objectForKey:@"AchievementImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    achievementPicture.image = [UIImage imageWithData:data];
                    
                });
            });
            
            
            
            descLabel.text = object[@"AchievementName"];
            descLabel2.text = object[@"AchievementDescription"];
            [Hud removeFromSuperview];
        }
        else {
            [Hud removeFromSuperview];
        }
    }];
    
    [backFriendRequestview addSubview:achievementPicture];
    [backFriendRequestview addSubview:descLabel];
    [backFriendRequestview addSubview:descLabel2];
    [self.view addSubview:backFriendRequestview];
}


-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(self.view.frame.size.width/3 - 8, self.view.frame.size.width /3 - 8);
    
}

-(void)tapTrackedEvents {
    [pageScroller setContentOffset:CGPointMake(0, pageScroller.contentInset.top) animated:NO];
    
    for (UIView *view in [pageScroller subviews])
    {
        [view removeFromSuperview];
    }
    
    [self loadTrackedEvents];
}

-(void)loadTrackedEvents {
    UILabel *headLabel = [[UILabel alloc] init];
    headLabel.frame = CGRectMake(50, 15, self.view.frame.size.width - 100, 30);
    headLabel.text = NSLocalizedString(@"Exercise History", nil);
    headLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
    headLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:headLabel];
    
    PFQuery *query = [PFQuery queryWithClassName:@"TrackedEvents"];
    [query whereKey:@"User" equalTo:[PFUser currentUser]];
    [query orderByAscending:@"updatedAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error) {
            
            int count = 0;
            for(PFObject *object in objects) {
                UIView *eventView = [[UIView alloc] init];
                eventView.frame = CGRectMake(0, (count * 60) + 60, self.view.frame.size.width, 50);
                eventView.backgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
                [pageScroller addSubview:eventView];
                
                UILabel *dateLabel = [[UILabel alloc] init];
                dateLabel.frame = CGRectMake(35, 10, self.view.frame.size.width - 100, 30);
                dateLabel.text = [NSString stringWithFormat:@"%@", object[@"Date"]];
                dateLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
                dateLabel.textAlignment = NSTextAlignmentRight;
                [eventView addSubview:dateLabel];
                
                UILabel *exerciseLabel = [[UILabel alloc] init];
                exerciseLabel.frame = CGRectMake(40, 0, self.view.frame.size.width - 100, 25);
                exerciseLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
                exerciseLabel.text = [NSString stringWithFormat:@"Exercises: %@", object[@"Exercises"]];
                [eventView addSubview:exerciseLabel];
                
                UILabel *heartsLabel = [[UILabel alloc] init];
                heartsLabel.frame = CGRectMake(40, 25, self.view.frame.size.width - 100, 25);
                heartsLabel.text = [NSString stringWithFormat:@"%@", object[@"Hearts"]];
                heartsLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
                [eventView addSubview:heartsLabel];
                
                UIButton *eventBtn = [[UIButton alloc] init];
                eventBtn.frame = CGRectMake(self.view.frame.size.width - 50, 0, 50, 50);
                eventBtn.backgroundColor = [UIColor orangeColor];
                [eventBtn setTitle:[object objectId] forState:UIControlStateNormal];
                [eventBtn addTarget:self action:@selector(loadSpecificEvent:) forControlEvents:UIControlEventTouchUpInside];
                eventBtn.titleLabel.layer.opacity = 0.0f;
                [eventView addSubview:eventBtn];
                
                UIImageView *arrow = [[UIImageView alloc] init];
                arrow.image = [UIImage imageNamed:@"right_arrow"];
                arrow.frame = CGRectMake(self.view.frame.size.width - 37, 13, 24, 24);
                [eventView addSubview:arrow];
                
                count++;
            }
            
            pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, (count * 60) + 200);
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}

-(IBAction)loadSpecificEvent:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    
    [pageScroller setContentOffset:CGPointMake(0, pageScroller.contentInset.top) animated:NO];
    
    for (UIView *view in [pageScroller subviews])
    {
        [view removeFromSuperview];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:@"TrackedEvents"];
    [query whereKey:@"objectId" equalTo:tmp];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if(!error) {
            
            UILabel *headLabel = [[UILabel alloc] init];
            headLabel.frame = CGRectMake(50, 15, self.view.frame.size.width - 100, 30);
            headLabel.text = NSLocalizedString(@"Exercise Summary", nil);
            headLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
            headLabel.textAlignment = NSTextAlignmentCenter;
            [pageScroller addSubview:headLabel];
            
            UILabel *dateLabel = [[UILabel alloc] init];
            dateLabel.frame = CGRectMake(50, 45, self.view.frame.size.width - 100, 30);
            dateLabel.text = [NSString stringWithFormat:@"%@", object[@"Date"]];
            dateLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
            dateLabel.textAlignment = NSTextAlignmentCenter;
            [pageScroller addSubview:dateLabel];
            
            NSMutableArray *exerciseArray = [[NSMutableArray alloc] init];
            for(PFObject *string in object[@"ExercisesUsed"]) {
                [exerciseArray addObject:string];
            }
            
            PFQuery *exerciseQuery = [PFQuery queryWithClassName:@"Exercises"];
            [exerciseQuery whereKey:@"objectId" containedIn:exerciseArray];
            [exerciseQuery findObjectsInBackgroundWithBlock:^(NSArray *exercises, NSError *error) {
                if(!error) {
                    
                    int count = 0;
                    for(PFObject *exercise in exercises) {
                        UILabel *exerciseName = [[UILabel alloc] init];
                        exerciseName.frame = CGRectMake(50, (count * 30) + 80, self.view.frame.size.width - 100, 30);
                        exerciseName.text = [NSString stringWithFormat:@"%@", exercise[@"ExerciseName"]];
                        exerciseName.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
                        [pageScroller addSubview:exerciseName];
                        
                        count++;
                    }
                    
                } else {
                    NSLog(@"%@", error.description);
                }
            }];
            
        } else {
            NSLog(@"%@", error.description);
        }
    }];
}
int isOpenChallengePage = 0;
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if(isOpenChallengePage == 0) {
        [pageScroller addSubview:friendsSideScroller];
        [pageScroller addSubview:openChallengeButton];
    }
}


-(void)scrollViewDidScroll:(UIScrollView *)friendsSideScroller{
    
}

-(IBAction)tapTodayBar:(id)sender
{
    [self showLoading];
    statView1 = [[UIView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        statView1.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        statView1.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        statView1.frame = CGRectMake(0, 306, self.view.frame.size.width, self.view.frame.size.height - 450); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        statView1.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        statView1.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else {
        statView1.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    }
    
    [pageScroller addSubview:statView1];
    
    // Your Stats Label
    UILabel *yourStatsLabel = [[UILabel alloc]init];
    yourStatsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 15, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    }
    yourStatsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"your stats", nil)];
    
    yourStatsLabel.textAlignment = NSTextAlignmentCenter;
    [statView1 addSubview:yourStatsLabel];
    
    // Hearts Earned Label
    UILabel *heartsEarnedLabel = [[UILabel alloc]init];
    heartsEarnedLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 80, self.view.frame.size.width, 18);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 100, self.view.frame.size.width, 18);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 23);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 23);
    } else {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 23);
    }
    heartsEarnedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Hearts Earned", nil)];
    
    heartsEarnedLabel.textAlignment = NSTextAlignmentCenter;
    [statView1 addSubview:heartsEarnedLabel];
    
    // Heart Image
    
    UIImageView *heartImage2 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage2.frame = CGRectMake(70, 40, 20, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage2.frame = CGRectMake(70, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    }
    heartImage2.image = [UIImage imageNamed:@"Heart"];
    heartImage2.contentMode = UIViewContentModeScaleAspectFit;
    heartImage2.clipsToBounds = YES;
    
    [statView1 addSubview:heartImage2];
    
    //////////////
    
    // Total Exercises Label
    UILabel *totalExercisesLabel = [[UILabel alloc]init];
    totalExercisesLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 80, self.view.frame.size.width, 20);
        
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 100, self.view.frame.size.width, 20);
        
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    }
    totalExercisesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total Exercises", nil)];
    
    totalExercisesLabel.textAlignment = NSTextAlignmentCenter;
    [statView1 addSubview:totalExercisesLabel];
    
    // Weight Image
    
    UIImageView *weightImg = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 40, 20, 20);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 110, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    }
    
    weightImg.image = [UIImage imageNamed:@"ic_weight"];
    weightImg.contentMode = UIViewContentModeScaleAspectFit;
    weightImg.clipsToBounds = YES;
    
    [statView1 addSubview:weightImg];
    
    //Date Formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    
    NSDate *currentDate = [NSDate date];
    NSString *dateString = [formatter stringFromDate:currentDate];
    
    NSLog(@"%@", dateString);
    
    PFQuery *trackedEventsQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
    [trackedEventsQuery whereKey:@"User" equalTo:[PFUser currentUser]];
    [trackedEventsQuery whereKey:@"Date" containsString:dateString];
    [trackedEventsQuery getFirstObjectInBackgroundWithBlock:^(PFObject *todayObject, NSError *error) {
        
        if (!error) {
            
            NSLog(@"%@", todayObject);
            
            todayHearts = [NSString stringWithFormat:@"%@", todayObject[@"Hearts"]];
            NSLog(NSLocalizedString(@"Today Hearts: %@", nil), todayHearts);
            
            todayExercises = [NSString stringWithFormat:@"%@", todayObject[@"Exercises"]];
            NSLog(NSLocalizedString(@"Today Exercises: %@", nil), todayExercises);
            
            // USER Hearts Labels
            UILabel *mainHeartLabel = [[UILabel alloc]init];
            mainHeartLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            mainHeartLabel.text = todayHearts;
            mainHeartLabel.textAlignment = NSTextAlignmentCenter;
            [statView1 addSubview:mainHeartLabel];
            
            // USER Exercise Labels
            UILabel *exerciseCountLabel = [[UILabel alloc]init];
            exerciseCountLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            exerciseCountLabel.text = todayExercises;
            exerciseCountLabel.textAlignment = NSTextAlignmentCenter;
            [statView1 addSubview:exerciseCountLabel];
            
        } else {
            
            NSLog(@"Failed to gather user tracked events");
            todayHearts = @"0";
            todayExercises = @"0";
            
            // USER Hearts Labels
            UILabel *mainHeartLabel = [[UILabel alloc]init];
            mainHeartLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            mainHeartLabel.text = todayHearts;
            mainHeartLabel.textAlignment = NSTextAlignmentCenter;
            [statView1 addSubview:mainHeartLabel];
            
            // USER Exercise Labels
            UILabel *exerciseCountLabel = [[UILabel alloc]init];
            exerciseCountLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            exerciseCountLabel.text = todayExercises;
            exerciseCountLabel.textAlignment = NSTextAlignmentCenter;
            [statView1 addSubview:exerciseCountLabel];
        }
        
    }];
    
    
    
    [view1 setTitleColor: [UIColor orangeColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view4 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [statView2 removeFromSuperview];
    [statView3 removeFromSuperview];
    [statView4 removeFromSuperview];
    [Hud removeFromSuperview];
}

-(IBAction)tapWeeklyBar:(id)sender
{
    [self showLoading];
    
    statView2 = [[UIView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        statView2.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        statView2.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        statView2.frame = CGRectMake(0, 306, self.view.frame.size.width, self.view.frame.size.height - 450); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        statView2.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        statView2.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else {
        statView2.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    }
    
    [pageScroller addSubview:statView2];
    
    // Your Stats Label
    UILabel *yourStatsLabel = [[UILabel alloc]init];
    yourStatsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 15, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    }
    yourStatsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"your stats", nil)];
    
    yourStatsLabel.textAlignment = NSTextAlignmentCenter;
    [statView2 addSubview:yourStatsLabel];
    
    // Hearts Earned Label
    UILabel *heartsEarnedLabel = [[UILabel alloc]init];
    heartsEarnedLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 80, self.view.frame.size.width, 18);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 100, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    } else {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    }
    heartsEarnedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Hearts Earned", nil)];
    
    heartsEarnedLabel.textAlignment = NSTextAlignmentCenter;
    [statView2 addSubview:heartsEarnedLabel];
    
    
    // Heart Image
    
    UIImageView *heartImage2 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage2.frame = CGRectMake(70, 40, 20, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage2.frame = CGRectMake(70, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    }
    heartImage2.image = [UIImage imageNamed:@"Heart"];
    heartImage2.contentMode = UIViewContentModeScaleAspectFit;
    heartImage2.clipsToBounds = YES;
    
    [statView2 addSubview:heartImage2];
    
    //////////////
    
    // Total Exercises Label
    UILabel *totalExercisesLabel = [[UILabel alloc]init];
    totalExercisesLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 80, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 100, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    }
    totalExercisesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total Exercises", nil)];
    
    totalExercisesLabel.textAlignment = NSTextAlignmentCenter;
    [statView2 addSubview:totalExercisesLabel];
    
    
    // Weight Image
    
    UIImageView *weightImg = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 40, 20, 20);
        
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 100, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 110, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 120, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 120, 50, 30, 30);
    } else {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 120, 50, 30, 30);
    }
    weightImg.image = [UIImage imageNamed:@"ic_weight"];
    weightImg.contentMode = UIViewContentModeScaleAspectFit;
    weightImg.clipsToBounds = YES;
    
    [statView2 addSubview:weightImg];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy"];
    
    NSArray *allDatesOfThisWeek = [self daysThisWeek];
    NSMutableArray *tmpDateString = [[NSMutableArray alloc] init];
    for (NSDate *date in allDatesOfThisWeek) {
        [tmpDateString addObject:[formatter stringFromDate:date]];
        NSLog(@"-----------------%@", [formatter stringFromDate:date]);
    }
    
    PFQuery *trackedEventsQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
    [trackedEventsQuery whereKey:@"Date" containedIn:tmpDateString];
    [trackedEventsQuery whereKey:@"User" equalTo:[PFUser currentUser]];
    [trackedEventsQuery findObjectsInBackgroundWithBlock:^(NSArray *weekObjects, NSError *error) {
        
        if (!error || [weekObjects count] != 0) {
            
            NSLog(@"%@", weekObjects);
            
            int heartsNumber = 0;
            int exercisesNumber = 0;
            for (PFObject *dateObject in weekObjects) {
                heartsNumber += [dateObject[@"Hearts"] intValue];
                exercisesNumber += [dateObject[@"Exercises"] intValue];
            }
            NSString *weekHearts = [NSString stringWithFormat:@"%d", heartsNumber];
            NSLog(NSLocalizedString(@"Week Hearts: %@", nil), weekHearts);
            
            
            NSString *weekExercises = [NSString stringWithFormat:@"%d", exercisesNumber];
            NSLog(NSLocalizedString(@"Week Exercises: %@", nil), weekExercises);
            
            
            // USER Hearts Labels
            UILabel *mainHeartLabel = [[UILabel alloc]init];
            mainHeartLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            mainHeartLabel.text = weekHearts;
            mainHeartLabel.textAlignment = NSTextAlignmentCenter;
            [statView2 addSubview:mainHeartLabel];
            
            // USER Exercise Labels
            UILabel *exerciseCountLabel = [[UILabel alloc]init];
            exerciseCountLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            exerciseCountLabel.text = weekExercises;
            exerciseCountLabel.textAlignment = NSTextAlignmentCenter;
            [statView2 addSubview:exerciseCountLabel];
        } else {
            
            NSLog(@"Failed to gather user tracked events");
            
        }
        
    }];
    
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor orangeColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view4 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [statView1 removeFromSuperview];
    [statView3 removeFromSuperview];
    [statView4 removeFromSuperview];
    [Hud removeFromSuperview];
}
-(NSArray*)daysThisWeek
{
    return  [self daysInWeek:0 fromDate:[NSDate date]];
}
-(NSArray*)daysInWeek:(int)weekOffset fromDate:(NSDate*)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    //ask for current week
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps=[calendar components:NSWeekCalendarUnit|NSYearCalendarUnit fromDate:date];
    //create date on week start
    NSDate* weekstart=[calendar dateFromComponents:comps];
    
    NSDateComponents* moveWeeks=[[NSDateComponents alloc] init];
    moveWeeks.weekOfYear=weekOffset;
    weekstart=[calendar dateByAddingComponents:moveWeeks toDate:weekstart options:0];
    
    
    //add 7 days
    NSMutableArray* week=[NSMutableArray arrayWithCapacity:7];
    for (int i=1; i<=7; i++) {
        NSDateComponents *compsToAdd = [[NSDateComponents alloc] init];
        compsToAdd.day=i;
        NSDate *nextDate = [calendar dateByAddingComponents:compsToAdd toDate:weekstart options:0];
        [week addObject:nextDate];
        
    }
    return [NSArray arrayWithArray:week];
}
-(IBAction)tapMonthlyBar:(id)sender
{
    [self showLoading];
    statView3 = [[UIView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        statView3.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        statView3.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        statView3.frame = CGRectMake(0, 306, self.view.frame.size.width, self.view.frame.size.height - 450); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        statView3.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        statView3.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else {
        statView3.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    }
    
    [pageScroller addSubview:statView3];
    
    // Your Stats Label
    UILabel *yourStatsLabel = [[UILabel alloc]init];
    yourStatsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    }
    yourStatsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"your stats", nil)];
    
    yourStatsLabel.textAlignment = NSTextAlignmentCenter;
    [statView3 addSubview:yourStatsLabel];
    
    // Hearts Earned Label
    UILabel *heartsEarnedLabel = [[UILabel alloc]init];
    heartsEarnedLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 80, self.view.frame.size.width, 18);
        
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 100, self.view.frame.size.width, 20);
        
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    } else {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    }
    heartsEarnedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Hearts Earned", nil)];
    
    heartsEarnedLabel.textAlignment = NSTextAlignmentCenter;
    [statView3 addSubview:heartsEarnedLabel];
    
    
    // Heart Image
    
    UIImageView *heartImage2 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage2.frame = CGRectMake(70, 40, 20, 20);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage2.frame = CGRectMake(70, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    } else {
        heartImage2.frame = CGRectMake(80, 50, 30, 30);
    }
    heartImage2.image = [UIImage imageNamed:@"Heart"];
    heartImage2.contentMode = UIViewContentModeScaleAspectFit;
    heartImage2.clipsToBounds = YES;
    
    [statView3 addSubview:heartImage2];
    
    //////////////
    
    // Total Exercises Label
    UILabel *totalExercisesLabel = [[UILabel alloc]init];
    totalExercisesLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 80, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 100, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    }
    totalExercisesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total Exercises", nil)];
    
    totalExercisesLabel.textAlignment = NSTextAlignmentCenter;
    [statView3 addSubview:totalExercisesLabel];
    
    
    // Weight Image
    
    UIImageView *weightImg = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 40, 20, 20);
        
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 110, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    }
    weightImg.image = [UIImage imageNamed:@"ic_weight"];
    weightImg.contentMode = UIViewContentModeScaleAspectFit;
    weightImg.clipsToBounds = YES;
    
    [statView3 addSubview:weightImg];
    
    //Date Formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"/MM/yyyy"];
    
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit
                                    | NSMonthCalendarUnit
                                               fromDate:[NSDate date]];
    
    NSDate *date = [calendar dateFromComponents:components];
    dateMonthString = [formatter stringFromDate:date];
    NSLog(@"%@", dateMonthString);
    
    
    PFQuery *trackedEventsQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
    [trackedEventsQuery whereKey:@"User" equalTo:[PFUser currentUser]];
    [trackedEventsQuery whereKey:@"Date" containsString:dateMonthString];
    [trackedEventsQuery findObjectsInBackgroundWithBlock:^(NSArray *monthObjects, NSError *error) {
        
        if (!error) {
            
            int heartCount = 0;
            int exerciseCount = 0;
            for(PFObject *object in monthObjects) {
                NSString *monthHearts = object[@"Hearts"];
                heartCount += [object[@"Hearts"] intValue];
                
                NSString *monthExercises = object[@"Exercises"];
                exerciseCount += [object[@"Exercises"] intValue];
            }
            
            NSString *heartString = [NSString stringWithFormat:@"%d", heartCount];
            NSString *exerciseString = [NSString stringWithFormat:@"%d", exerciseCount];
            
            // USER Hearts Labels
            UILabel *mainHeartLabel = [[UILabel alloc]init];
            mainHeartLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            } else {
                mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
            }
            mainHeartLabel.text = heartString;
            mainHeartLabel.textAlignment = NSTextAlignmentCenter;
            [statView3 addSubview:mainHeartLabel];
            
            
            // USER Exercise Labels
            UILabel *exerciseCountLabel = [[UILabel alloc]init];
            exerciseCountLabel.textColor = [UIColor blackColor];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 50, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            } else {
                exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
                exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
            }
            exerciseCountLabel.text = exerciseString;
            exerciseCountLabel.textAlignment = NSTextAlignmentCenter;
            [statView3 addSubview:exerciseCountLabel];
            
        } else {
            
            NSLog(@"Failed to gather user tracked events");
            
        }
        
    }];
    
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor orangeColor] forState:UIControlStateNormal];
    [view4 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [statView1 removeFromSuperview];
    [statView2 removeFromSuperview];
    [statView4 removeFromSuperview];
    [Hud removeFromSuperview];
}
-(IBAction)tapAllTimeBar:(id)sender
{
    
    statView4 = [[UIView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        statView4.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        statView4.frame = CGRectMake(0, 286, self.view.frame.size.width, self.view.frame.size.height-430); //Position of the scroller
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        statView4.frame = CGRectMake(0, 306, self.view.frame.size.width, self.view.frame.size.height - 450); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        statView4.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        statView4.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        statView4.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    } else {
        statView4.frame = CGRectMake(0, 326, self.view.frame.size.width, self.view.frame.size.height-470); //Position of the scroller
    }
    
    [pageScroller addSubview:statView4];
    
    
    // Your Stats Label
    UILabel *yourStatsLabel = [[UILabel alloc]init];
    yourStatsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:17];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    } else {
        yourStatsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        yourStatsLabel.frame = CGRectMake(0, 20, self.view.frame.size.width, 20);
    }
    yourStatsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"your stats", nil)];
    
    yourStatsLabel.textAlignment = NSTextAlignmentCenter;
    [statView4 addSubview:yourStatsLabel];
    
    // Hearts Earned Label
    UILabel *heartsEarnedLabel = [[UILabel alloc]init];
    heartsEarnedLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 80, self.view.frame.size.width, 18);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 100, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    } else {
        heartsEarnedLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartsEarnedLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 110, self.view.frame.size.width, 20);
    }
    heartsEarnedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Hearts Earned", nil)];
    
    heartsEarnedLabel.textAlignment = NSTextAlignmentCenter;
    [statView4 addSubview:heartsEarnedLabel];
    
    
    // USER Hearts Labels
    UILabel *mainHeartLabel = [[UILabel alloc]init];
    mainHeartLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 50, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
    } else {
        mainHeartLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        mainHeartLabel.frame = CGRectMake(-self.view.frame.size.width / 3 * 1 + 30, 70, self.view.frame.size.width, 50);
    }
    mainHeartLabel.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"Hearts"]];
    mainHeartLabel.textAlignment = NSTextAlignmentCenter;
    [statView4 addSubview:mainHeartLabel];
    
    // Heart Image
    
    UIImageView *heartImage2 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage2.frame = CGRectMake(70, 40, 20, 20);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    } else {
        heartImage2.frame = CGRectMake(75, 50, 30, 30);
    }
    heartImage2.image = [UIImage imageNamed:@"Heart"];
    heartImage2.contentMode = UIViewContentModeScaleAspectFit;
    heartImage2.clipsToBounds = YES;
    
    [statView4 addSubview:heartImage2];
    
    //////////////
    
    // Total Exercises Label
    UILabel *totalExercisesLabel = [[UILabel alloc]init];
    totalExercisesLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 80, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 100, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 105, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:17];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    } else {
        totalExercisesLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        totalExercisesLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 110, self.view.frame.size.width, 20);
    }
    totalExercisesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total Exercises", nil)];
    
    totalExercisesLabel.textAlignment = NSTextAlignmentCenter;
    [statView4 addSubview:totalExercisesLabel];
    
    
    // USER Exercise Labels
    UILabel *exerciseCountLabel = [[UILabel alloc]init];
    exerciseCountLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 50, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:22];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:30];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
        
    } else {
        exerciseCountLabel.font = [UIFont fontWithName:@"Ethnocentric" size:26];
        exerciseCountLabel.frame = CGRectMake(self.view.frame.size.width / 3 * 1 - 30, 70, self.view.frame.size.width, 50);
    }
    exerciseCountLabel.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"TotalExercises"]];
    exerciseCountLabel.textAlignment = NSTextAlignmentCenter;
    [statView4 addSubview:exerciseCountLabel];
    
    // Weight Image
    
    UIImageView *weightImg = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 40, 20, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 105, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 110, 50, 30, 30);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    } else {
        weightImg.frame = CGRectMake(self.view.frame.size.width - 115, 50, 30, 30);
    }
    weightImg.image = [UIImage imageNamed:@"ic_weight"];
    weightImg.contentMode = UIViewContentModeScaleAspectFit;
    weightImg.clipsToBounds = YES;
    
    [statView4 addSubview:weightImg];
    [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view4 setTitleColor: [UIColor orangeColor] forState:UIControlStateNormal];
    
    [statView1 removeFromSuperview];
    [statView2 removeFromSuperview];
    [statView3 removeFromSuperview];
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
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 620); //Position of the scroller
    }else if([[UIScreen mainScreen] bounds].size.height == 896){
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 620); //Position of the scroller
    } else {
        topView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 620); //Position of the scroller
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
                                                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error!"
                                                                                                   message:error.description delegate:nil
                                                                                         cancelButtonTitle:@"OK"
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
    
    
    
    PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"User"];
    [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             for (PFObject *object in objects) {
                 NSLog(@"OK: %@", object[@"Friends"]);
             }
             collectedFriends = objects;
             [self setFriendsGrid:objects : [PFUser currentUser][@"Friends"]];
         }
     }];
    
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

-(void)loadUser{
    
    //Profile Group View
    
    UIImageView *profileGroupView = [[UIImageView alloc] init];
    profileGroupView.contentMode = UIViewContentModeScaleAspectFit;
    profileGroupView.clipsToBounds = YES;
    [profileGroupView setBackgroundColor:[UIColor colorWithRed:0.90 green:0.72 blue:0.54 alpha:1.0]];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        profileGroupView.frame = CGRectMake(0, -1, self.view.frame.size.width, 120);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        profileGroupView.frame = CGRectMake(0, -1, self.view.frame.size.width, 120);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 130);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 140);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 140);
    } else {
        profileGroupView.frame = CGRectMake(0, 0, self.view.frame.size.width, 140);
    }
    [topView addSubview:profileGroupView];
    
    //Profile Picture
    
    profilePicture = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        profilePicture.frame = CGRectMake(15, 15, 55, 55);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        profilePicture.frame = CGRectMake(15, 15, 55, 55);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        profilePicture.frame = CGRectMake(20, 20, 60, 60);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        profilePicture.frame = CGRectMake(25, 20, 70, 70);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        profilePicture.frame = CGRectMake(25, 20, 70, 70);
    } else {
        profilePicture.frame = CGRectMake(25, 20, 70, 70);
    }
    
    CALayer *imageLayer = profilePicture.layer;
    [imageLayer setCornerRadius:5];
    [imageLayer setBorderWidth:1];
    [profilePicture.layer setCornerRadius:profilePicture.frame.size.width/2];
    [imageLayer setMasksToBounds:YES];
    profilePicture.layer.borderWidth = 3.0f;
    profilePicture.contentMode = UIViewContentModeScaleAspectFill;
    profilePicture.layer.borderColor = [UIColor colorWithRed:0.29 green:0.28 blue:0.28 alpha:1.0].CGColor;
    
    [topView addSubview:profilePicture];
    
    
    PFQuery * statusQuery = [PFQuery queryWithClassName:@"UserAchievements"];
    [statusQuery whereKey:@"User" equalTo:[PFUser currentUser]];
    [statusQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            NSLog(@"-i-i-i-i-i- %@", objects);
            for (PFObject *object in objects) {
                if([PFUser currentUser]) {
                    NSLog(@"-i-i-i-i-i- %@", object);
                    
                    if (([object[@"ProludicCopper"]  isEqual: @YES] && [object[@"BodyweightCopper"]  isEqual: @YES]) && ([object[@"ProludicBronze"]  isEqual: @NO] || [object[@"BodyweightBronze"]  isEqual: @NO])) {
                        NSLog(@"PROLUDIC STATUS: Copper");
                        userStatus.image = [UIImage imageNamed:@"coin_copper"];
                    } else if (([object[@"ProludicBronze"]  isEqual: @YES] && [object[@"BodyweightBronze"]  isEqual: @YES]) && ([object[@"ProludicSilver"]  isEqual: @NO] || [object[@"BodyweightSilver"]  isEqual: @NO])) {
                        NSLog(@"PROLUDIC STATUS: Bronze");
                        userStatus.image = [UIImage imageNamed:@"coin_bronze"];
                    } else if (([object[@"ProludicSilver"]  isEqual: @YES] && [object[@"BodyweightSilver"]  isEqual: @YES]) && ([object[@"ProludicGold"]  isEqual: @NO] || [object[@"BodyweightGold"]  isEqual: @NO])) {
                        NSLog(@"PROLUDIC STATUS: Silver");
                        userStatus.image = [UIImage imageNamed:@"coin_silver"];
                    } else if (([object[@"ProludicGold"]  isEqual: @YES] && [object[@"BodyweightGold"]  isEqual: @YES]) && ([object[@"ProludicPlatinum"]  isEqual: @NO] || [object[@"BodyweightPlatinum"]  isEqual: @NO])) {
                        NSLog(@"PROLUDIC STATUS: Gold");
                        userStatus.image = [UIImage imageNamed:@"coin_gold"];
                    } else if (([object[@"ProludicPlatinum"]  isEqual: @YES] && [object[@"BodyweightPlatinum"]  isEqual: @YES]) && ([object[@"ProludicDiamond"]  isEqual: @NO] || [object[@"BodyweightDiamond"]  isEqual: @NO])) {
                        NSLog(@"PROLUDIC STATUS: Platinum");
                        userStatus.image = [UIImage imageNamed:@"coin_platinum"];
                    } else if ([object[@"ProludicDiamond"]  isEqual: @YES] && [object[@"BodyweightDiamond"]  isEqual: @YES]) {
                        NSLog(@"PROLUDIC STATUS: Diamond");
                        userStatus.image = [UIImage imageNamed:@"coin_diamond"];
                    } else {
                        NSLog(@"PROLUDIC STATUS: NOTHING!");
                        
                    }
                } else {
                    //nothing
                }
            }
        } else {
            NSLog(@"Failed");
        }
    }];
    
    
    userStatus = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        userStatus.frame = CGRectMake(15, 15, 22, 22);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        userStatus.frame = CGRectMake(15, 15, 22, 22);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        userStatus.frame = CGRectMake(20, 20, 25, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        userStatus.frame = CGRectMake(25, 20, 28, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        userStatus.frame = CGRectMake(25, 20, 28, 28);
    } else {
        userStatus.frame = CGRectMake(25, 20, 28, 28);
    }
    [topView addSubview:userStatus];
    
    
    UIActivityIndicatorView *activityView1 = [[UIActivityIndicatorView alloc]
                                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        activityView1.frame = CGRectMake(5, 2, 80, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        activityView1.frame = CGRectMake(5, 2, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        activityView1.frame = CGRectMake(7, 5, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        activityView1.frame = CGRectMake(12, 5, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        activityView1.frame = CGRectMake(12, 5, 100, 100);
    } else {
        activityView1.frame = CGRectMake(12, 5, 100, 100);
    }
    [activityView1 startAnimating];
    [topView addSubview:activityView1];
    
    //Change Profile Button
    
    UIButton *changeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        changeImageButton.frame = CGRectMake(5, 2, 80, 80);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        changeImageButton.frame = CGRectMake(5, 2, 80, 80);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        changeImageButton.frame = CGRectMake(7, 15, 90, 90);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        changeImageButton.frame = CGRectMake(12, 15, 100, 100);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        changeImageButton.frame = CGRectMake(12, 15, 100, 100);
    } else {
        changeImageButton.frame = CGRectMake(12, 15, 100, 100);
    }
    
    changeImageButton.backgroundColor = [UIColor clearColor];
    changeImageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    changeImageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    changeImageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [topView addSubview:changeImageButton];
    
    NSString *typeOfUser = [[PFUser currentUser] objectForKey:@"login"];
    /*if([typeOfUser isEqualToString:@"Facebook"]){
     [changeImageButton addTarget:self action:@selector(tapChangeKit) forControlEvents:UIControlEventTouchUpInside];
     //Facebook User
     dispatch_async(dispatch_get_global_queue(0,0), ^{
     NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[PFUser currentUser].username]]];
     if ( data == nil )
     return;
     dispatch_async(dispatch_get_main_queue(), ^{
     [activityView1 stopAnimating];
     [activityView1 removeFromSuperview];
     profilePicture.image =  [UIImage imageWithData:data];
     [PFUser currentUser][@"profilePictureLink"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large",[PFUser currentUser].username];
     });
     });
     
     
     }else {*/
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
                    changeImageButton.frame = CGRectMake(20, 15, 80, 80);
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    changeImageButton.frame = CGRectMake(20, 15, 80, 80);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    changeImageButton.frame = CGRectMake(30, 20, 90, 90);
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    changeImageButton.frame = CGRectMake(30, 20, 100, 100);
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    changeImageButton.frame = CGRectMake(30, 20, 100, 100);
                } else {
                    changeImageButton.frame = CGRectMake(30, 20, 100, 100);
                }
                [changeImageButton addTarget:self action:@selector(tapChangeImage) forControlEvents:UIControlEventTouchUpInside];
                changeImageButton.backgroundColor = [UIColor clearColor];
                changeImageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
                changeImageButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
                changeImageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
                [topView addSubview:changeImageButton];
                
            });
        });
    } else {
        
        [activityView1 stopAnimating];
        [activityView1 removeFromSuperview];
        //User hasnt set a profile picture
        profilePicture.image = [UIImage imageNamed:@"profile_pic"];
        
        
        //}
        
    }
    
    
    // Name Label
    UILabel *nameLabel = [[UILabel alloc]init];
    nameLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        nameLabel.frame = CGRectMake(85, 5, 200, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        nameLabel.frame = CGRectMake(85, 5, 200, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        nameLabel.frame = CGRectMake(95, 5, 230, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        nameLabel.frame = CGRectMake(105, 5, 250, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        nameLabel.frame = CGRectMake(105, 5, 250, 41);
    } else {
        nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        nameLabel.frame = CGRectMake(105, 5, 250, 41);
    }
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = [[PFUser currentUser] objectForKey:@"name"];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    [topView addSubview:nameLabel];
    
    // Park Label
    UILabel *parkLabel = [[UILabel alloc]init];
    parkLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        parkLabel.frame = CGRectMake(85, 40, 200, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        parkLabel.frame = CGRectMake(85, 42, 200, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        parkLabel.frame = CGRectMake(95, 51, 230, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(105, 55, 250, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(105, 55, 250, 20);
    } else {
        parkLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        parkLabel.frame = CGRectMake(105, 55, 250, 20);
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
    
    parkLabel.textAlignment = NSTextAlignmentLeft;
    [topView addSubview:parkLabel];
    
    // HEART Label
    
    UIImageView *heartImage = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heartImage.frame = CGRectMake(85, 60, 10, 10);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heartImage.frame = CGRectMake(85, 60, 10, 10);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartImage.frame = CGRectMake(95, 71, 15, 15);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartImage.frame = CGRectMake(105, 76, 15, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartImage.frame = CGRectMake(105, 76, 15, 15);
    } else {
        heartImage.frame = CGRectMake(105, 76, 15, 15);
    }
    heartImage.image = [UIImage imageNamed:@"Heart"];
    heartImage.contentMode = UIViewContentModeScaleAspectFit;
    heartImage.clipsToBounds = YES;
    [topView addSubview:heartImage];
    
    UILabel *heartLabel = [[UILabel alloc]init];
    heartLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        heartLabel.frame = CGRectMake(97, 58, 200, 15);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        heartLabel.frame = CGRectMake(97, 58, 200, 15);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        heartLabel.frame = CGRectMake(115, 71, 230, 15);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(125, 76, 250, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(125, 76, 250, 15);
    } else {
        heartLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        heartLabel.frame = CGRectMake(125, 76, 250, 15);
    }
    heartLabel.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"Hearts"]];
    heartLabel.textAlignment = NSTextAlignmentLeft;
    [topView addSubview:heartLabel];
    
    
    // USER Description Label
    descTextView = [[UITextView alloc]init];
    descTextView.textColor = [UIColor blackColor];
    descTextView.backgroundColor = [UIColor clearColor];
    descTextView.editable = NO;
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:10];
        descTextView.frame = CGRectMake(30, 75, 275, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:10];
        descTextView.frame = CGRectMake(30, 75, 275, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:12];
        descTextView.frame = CGRectMake(35, 80, 300, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:14];
        descTextView.frame = CGRectMake(40, 85, 340, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:14];
        descTextView.frame = CGRectMake(40, 85, 340, 50);
    } else {
        descTextView.font = [UIFont fontWithName:@"Open Sans" size:14];
        descTextView.frame = CGRectMake(40, 85, 340, 50);
    }
    descTextView.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"Description"]];
    descTextView.textAlignment = NSTextAlignmentLeft;
    [topView addSubview:descTextView];
    
    
    // USERNAME Label
    UILabel *usernameLabel = [[UILabel alloc]init];
    usernameLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        usernameLabel.frame = CGRectMake(85, 15, 90, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        usernameLabel.frame = CGRectMake(85, 15, 85, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        usernameLabel.frame = CGRectMake(95, 20, 105, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        usernameLabel.frame = CGRectMake(105, 25, 140, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        usernameLabel.frame = CGRectMake(105, 25, 140, 50);
    } else {
        usernameLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        usernameLabel.frame = CGRectMake(105, 25, 140, 50);
    }
    usernameLabel.text = [NSString stringWithFormat:@"%@",[[PFUser currentUser] objectForKey:@"username"]];
    usernameLabel.textAlignment = NSTextAlignmentLeft;
    
    [topView addSubview:usernameLabel];
    
    // WDL Label
    NSString *wdl = [[NSString alloc] initWithFormat:NSLocalizedString(@"%@W-%@L-%@D", nil), [[PFUser currentUser]objectForKey:@"wins"], [[PFUser currentUser]objectForKey:@"wins"], [[PFUser currentUser]objectForKey:@"wins"]];
    
    UILabel *wdlLabel = [[UILabel alloc]init];
    wdlLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        wdlLabel.frame = CGRectMake(195, 0, 100, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:10];
        wdlLabel.frame = CGRectMake(195, 0, 100, 50);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        wdlLabel.frame = CGRectMake(210, 0, 120, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        wdlLabel.frame = CGRectMake(220, 0, 140, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        wdlLabel.frame = CGRectMake(220, 0, 140, 50);
    } else {
        wdlLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        wdlLabel.frame = CGRectMake(220, 0, 140, 50);
    }
    wdlLabel.text = wdl;
    wdlLabel.textAlignment = NSTextAlignmentRight;
    
    [topView addSubview:wdlLabel];
    
    //Friends Label
    
    CGRect friendFrame;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendFrame = CGRectMake( 0, 123, self.view.frame.size.width, 50.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        friendFrame = CGRectMake( 0, 123, self.view.frame.size.width, 50.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        friendFrame = CGRectMake( 0, 127, self.view.frame.size.width, 50.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendFrame = CGRectMake( 0, 138, self.view.frame.size.width, 50.0);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendFrame = CGRectMake( 0, 138, self.view.frame.size.width, 50.0);
    } else {
        friendFrame = CGRectMake( 0, 138, self.view.frame.size.width, 50.0);
    }
    
    UILabel *friendsLabel = [[UILabel alloc] initWithFrame:friendFrame];
    friendsLabel.text = NSLocalizedString(@"Friends", nil);
    friendsLabel.textAlignment = NSTextAlignmentCenter;
    friendsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
    
    [topView addSubview:friendsLabel];
    
    //Add Friend Button
    
    addFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        addFriendButton.frame = CGRectMake(20, 10, 60, 55);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        addFriendButton.frame = CGRectMake(20, 10, 60, 55);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        addFriendButton.frame = CGRectMake(20, 12, 63, 57);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        addFriendButton.frame = CGRectMake(20, 14, 65, 60);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        addFriendButton.frame = CGRectMake(20, 14, 65, 60);//Position of the button
    } else {
        addFriendButton.frame = CGRectMake(20, 14, 65, 60);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [addFriendButton setBackgroundImage:[UIImage imageNamed:@"btn_addfriend_2"] forState:UIControlStateNormal];
    } else {
        [addFriendButton setBackgroundImage:[UIImage imageNamed:@"btn_add"] forState:UIControlStateNormal];
    }
    [addFriendButton addTarget:self action:@selector(tapAddFriend:) forControlEvents:UIControlEventTouchUpInside];
    
    [friendsSideScroller addSubview:addFriendButton];
    //Add FB Friend Button
    
    UIButton *addFBFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    openChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        addFBFriendButton.frame = CGRectMake(90, 10, 60, 55);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 247, 150, 30);//Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        addFBFriendButton.frame = CGRectMake(90, 10, 60, 55);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 247, 150, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        addFBFriendButton.frame = CGRectMake(90, 12, 63, 57);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 247, 150, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        addFBFriendButton.frame = CGRectMake(90, 14, 65, 60);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 247, 150, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        addFBFriendButton.frame = CGRectMake(90, 14, 65, 60);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 260, 150, 30);//Position of the button
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        addFBFriendButton.frame = CGRectMake(90, 14, 65, 60);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 260, 150, 30);//Position of the button
    }
    else {
        addFBFriendButton.frame = CGRectMake(90, 14, 65, 60);//Position of the button
        openChallengeButton.frame = CGRectMake(self.view.frame.size.width/2-75, 260, 150, 30);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [addFBFriendButton setBackgroundImage:[UIImage imageNamed:@"btn_invitefb_french"] forState:UIControlStateNormal];
    } else {
        [addFBFriendButton setBackgroundImage:[UIImage imageNamed:@"btn_invite"] forState:UIControlStateNormal];
    }
    [openChallengeButton setBackgroundImage:[UIImage imageNamed:@"btn_challenge"] forState:UIControlStateNormal];
    //tapAddFriend:
    [addFBFriendButton addTarget:self action:@selector(sendFBInvite:) forControlEvents:UIControlEventTouchUpInside];
    
    //tapAddFriend:
    [openChallengeButton addTarget:self action:@selector(openChallengePage:) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:openChallengeButton];
    [friendsSideScroller addSubview:addFBFriendButton];
    
    
    //Parse Friends
    if(![[PFUser currentUser][@"Friends"] count] == 0) {
        //QUERY FOR GETTING MY EXERCISES
        PFQuery * browseMyQuery = [PFUser query];
        [browseMyQuery orderByAscending:@"username"];
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
    
    // Edit USER Desc
    isFindingNearestParkOn = false;
    editDescButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        editDescButton.frame = CGRectMake(180, 40, 95, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        editDescButton.frame = CGRectMake(170, 40, 95, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        editDescButton.frame = CGRectMake(200, 45, 98, 32);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        editDescButton.frame = CGRectMake(250, 50, 100, 35);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        editDescButton.frame = CGRectMake(250, 50, 80, 30);//Position of the button
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        editDescButton.frame = CGRectMake(250, 50, 80, 30);//Position of the button
    }
    else {
        editDescButton.frame = CGRectMake(250, 50, 100, 35);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [editDescButton setBackgroundImage:[UIImage imageNamed:@"btn_edit_french"] forState:UIControlStateNormal];
    } else {
        [editDescButton setBackgroundImage:[UIImage imageNamed:@"btn_edit"] forState:UIControlStateNormal];
    }
    [editDescButton addTarget:self action:@selector(tapEditDesc:) forControlEvents:UIControlEventTouchUpInside];
    
    [topView addSubview:editDescButton];
    
    UIButton *requestFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UILabel *cover = [[UILabel alloc] init];
    UILabel *labelNumberOfRequests = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        requestFriendButton.frame = CGRectMake(280, 40, 37, 30);//Position of the button
        
        cover.frame = CGRectMake(300,35, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(298,35, 20, 15);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        requestFriendButton.frame = CGRectMake(270, 40, 37, 30);//Position of the button
        
        cover.frame = CGRectMake(294,35, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(293,35, 20, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        requestFriendButton.frame = CGRectMake(305, 45, 39, 32);//Position of the button
        
        cover.frame = CGRectMake(329,40, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(328,40, 20, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        requestFriendButton.frame = CGRectMake(355, 50, 44, 35);//Position of the button
        
        cover.frame = CGRectMake(382,45, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(381,45, 20, 15);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        requestFriendButton.frame = CGRectMake(335, 50, 35, 30);//Position of the button
        
        cover.frame = CGRectMake(358,45, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(357,45, 20, 15);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        requestFriendButton.frame = CGRectMake(335, 50, 35, 30);//Position of the button
        
        cover.frame = CGRectMake(360,45, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(359,45, 20, 15);
    } else {
        requestFriendButton.frame = CGRectMake(355, 50, 44, 35);//Position of the button
        
        cover.frame = CGRectMake(382,45, 20, 20);
        labelNumberOfRequests.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        labelNumberOfRequests.frame = CGRectMake(381,45, 20, 15);
    }
    [requestFriendButton setBackgroundImage:[UIImage imageNamed:@"btn_requests"] forState:UIControlStateNormal];
    [topView addSubview:requestFriendButton];
    
    PFQuery *queryFriendRequest = [PFQuery queryWithClassName:@"FriendRequests"];
    [queryFriendRequest whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
    [queryFriendRequest whereKey:@"accepted" equalTo:@NO];
    [queryFriendRequest whereKey:@"isPending" equalTo:@YES];
    [queryFriendRequest findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if([objects count] > 0) {
                // The find succeeded.
                labelNumberOfRequests.text = [NSString stringWithFormat:@"%d", [objects count]];
                [requestFriendButton addTarget:self action:@selector(tapFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
                [topView addSubview:cover];
                [topView addSubview:labelNumberOfRequests];
            }
        } else {
            // Log details of the failure
            labelNumberOfRequests.text = @"0";
        }
    }];
    labelNumberOfRequests.textAlignment = NSTextAlignmentCenter;
    labelNumberOfRequests.textColor = [UIColor whiteColor];
    // Create the shape layer
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 17, 17)].CGPath;
    circleLayer.fillColor = [UIColor redColor].CGColor;
    circleLayer.strokeColor = [UIColor whiteColor].CGColor;
    circleLayer.lineWidth = 1;
    
    // Add it do your label's layer hierarchy
    
    [cover.layer addSublayer:circleLayer];
    
    
    [Hud removeFromSuperview];
    
}
UIButton *openChallengeButton;
-(IBAction) tapFriendRequest:(id)sender {
    pageScroller.scrollEnabled = NO;
    for(UIView *subview in [pageScroller subviews]) {
        subview.userInteractionEnabled = NO;
    }
    
    [self showLoading];
    backFriendRequestview = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [backFriendRequestview setBackgroundColor:[UIColor blackColor]];
    backFriendRequestview.layer.zPosition = 1;
    backFriendRequestview.alpha = 0.8;
    backFriendRequestview.userInteractionEnabled = YES;
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setBackgroundColor:[UIColor clearColor]];
    back.tag = 0;
    [back addTarget:self action:@selector(backTappedFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
    [back setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
    [backFriendRequestview addSubview:back];
    [UIView animateWithDuration:0.5f // This can be changed.
                     animations:^
     {
         [backFriendRequestview setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
     }
                     completion:^(BOOL finished)
     {
         [backFriendRequestview setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
     }];
    friendRequestScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 47, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    } else {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    friendRequestScroller.bounces = NO;
    //friendRequestScroller.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    //[friendRequestScroller setShowsVerticalScrollIndicator:NO];
    [backFriendRequestview addSubview:friendRequestScroller];
    [self setupFriendRequestGrid];
    [pageScroller addSubview:backFriendRequestview];
}
-(void) setupFriendRequestGrid {
    for(UIView *subview in [friendRequestScroller subviews]) {
        [subview removeFromSuperview];
    }
    PFQuery *queryFriendRequest = [PFQuery queryWithClassName:@"FriendRequests"];
    [queryFriendRequest whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
    [queryFriendRequest whereKey:@"accepted" equalTo:@NO];
    [queryFriendRequest whereKey:@"isPending" equalTo:@YES];
    [queryFriendRequest orderByDescending:@"createdAt"];
    [queryFriendRequest findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            int count = 0;
            for (PFObject *object in objects) {
                PFUser *user = object[@"UserRequesting"];
                
                UIImageView *friendRequestPicture = [[UIImageView alloc]init];
                UIButton *accept = [UIButton buttonWithType:UIButtonTypeCustom];
                UIButton *decline = [UIButton buttonWithType:UIButtonTypeCustom];
                UILabel *friendRequestText = [[UILabel alloc] init];
                UILabel *challengeText = [[UILabel alloc] init];
                challengeText.textColor = [UIColor whiteColor];
                challengeText.textAlignment = NSTextAlignmentLeft;
                friendRequestText.textColor = [UIColor whiteColor];
                friendRequestText.textAlignment = NSTextAlignmentLeft;
                if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
                {
                    friendRequestPicture.frame = CGRectMake(40, 20+ count*70, 60, 60);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    friendRequestText.frame = CGRectMake(110, 45 + count*70, 100, 20);
                    challengeText.frame = CGRectMake(110, 25 + count*70, 100, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:12];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 95, 30+ count*70, 40, 40)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 55, 30+ count*70, 40, 40)];
                    
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
                {
                    friendRequestPicture.frame = CGRectMake(40, 20 + count*70, 60, 60);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    friendRequestText.frame = CGRectMake(110, 45 + count*70, 100, 20);
                    challengeText.frame = CGRectMake(110, 25 + count*70, 100, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:12];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 95, 30+ count*70, 40, 40)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 55, 30+ count*70, 40, 40)];
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
                {
                    friendRequestPicture.frame = CGRectMake(25, 20 + count*90, 70, 70);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:16];
                    friendRequestText.frame = CGRectMake(120, 50 + count*90, 120, 20);
                    challengeText.frame = CGRectMake(120, 25 + count*90, 120, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 110, 40+ count*90, 40, 40)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 60, 40+ count*90, 40, 40)];
                }
                else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
                {
                    friendRequestPicture.frame = CGRectMake(50, 20 + count*80, 70, 70);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:16];
                    friendRequestText.frame = CGRectMake(150, 60 + count*80, 120, 20);
                    challengeText.frame = CGRectMake(150, 35 + count*80, 120, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 120, 40+ count*80, 50, 50)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 60, 40+ count*80, 50, 50) ];
                } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
                {
                    friendRequestPicture.frame = CGRectMake(50, 20 + count*80, 70, 70);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:16];
                    friendRequestText.frame = CGRectMake(150, 60 + count*80, 120, 20);
                    challengeText.frame = CGRectMake(150, 35 + count*80, 120, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 120, 40+ count*80, 50, 50)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 60, 40+ count*80, 50, 50) ];
                } else {
                    friendRequestPicture.frame = CGRectMake(50, 20 + count*80, 70, 70);
                    friendRequestText.font = [UIFont fontWithName:@"Open Sans" size:16];
                    friendRequestText.frame = CGRectMake(150, 60 + count*80, 120, 20);
                    challengeText.frame = CGRectMake(150, 35 + count*80, 120, 20);
                    challengeText.font = [UIFont fontWithName:@"Open Sans" size:14];
                    [accept setFrame:CGRectMake(self.view.frame.size.width - 120, 40+ count*80, 50, 50)];
                    [decline setFrame:CGRectMake(self.view.frame.size.width - 60, 40+ count*80, 50, 50) ];
                }
                
                friendRequestPicture.layer.cornerRadius = friendRequestPicture.frame.size.width / 2;
                friendRequestPicture.clipsToBounds = YES;
                friendRequestPicture.contentMode = UIViewContentModeScaleAspectFill;
                
                //[friendPictureBtn addTarget:self action:@selector(tapFriendBtn:) forControlEvents:UIControlEventTouchUpInside];
                [user fetchIfNeededInBackgroundWithBlock:^(PFObject *post, NSError *error) {
                    if([user[@"profilePicture"] isEqualToString:@"NoPicture"]) {
                        //User hasnt set a profile picture
                        friendRequestPicture.image = [UIImage imageNamed:@"profile_pic"];
                    } else {
                        NSString *imageUrl = [user objectForKey:@"profilePicture"];
                        dispatch_async(dispatch_get_global_queue(0,0), ^{
                            
                            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                            if ( data == nil )
                                return;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                friendRequestPicture.image = [UIImage imageWithData:data];
                                
                            });
                        });
                    }
                    
                    friendRequestText.text = user[@"username"];
                    challengeText.text = @"CHALLENGE";
                }];
                [accept setTitle:[object objectId] forState:UIControlStateNormal];
                accept.userInteractionEnabled = YES;
                [decline setTitle:[object objectId] forState:UIControlStateNormal];
                decline.userInteractionEnabled = YES;
                accept.titleLabel.layer.opacity = 0.0f;
                decline.titleLabel.layer.opacity = 0.0f;
                [accept setImage:[UIImage imageNamed:@"btn_yes"] forState:UIControlStateNormal];
                [decline setImage:[UIImage imageNamed:@"btn_no"] forState:UIControlStateNormal];
                [accept addTarget:self action:@selector(acceptFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
                [decline addTarget:self action:@selector(declineFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
                
                if([object[@"isChallenge"] isEqual:@YES]) {
                    [friendRequestScroller addSubview:challengeText];
                }
                [friendRequestScroller addSubview:friendRequestPicture];
                [friendRequestScroller addSubview:friendRequestText];
                [friendRequestScroller addSubview:accept];
                [friendRequestScroller addSubview:decline];
                
                count++;
            }
            friendRequestScroller.contentSize = CGSizeMake(self.view.frame.size.width, friendRequestScroller.frame.size.height + count * 100);
            [Hud removeFromSuperview];
        } else {
            // Log details of the failure
            [Hud removeFromSuperview];
            
        }
    }];
}
-(IBAction)acceptFriendRequest:(UIButton*)sender {
    [self showLoading];
    NSString *objectId = sender.titleLabel.text;
    PFQuery *query = [PFQuery queryWithClassName:@"FriendRequests"];
    [query whereKey:@"objectId" equalTo:objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *requestObject, NSError *error) {
        if (!error) {
            PFUser *user = requestObject[@"UserRequesting"];
            [user fetchIfNeededInBackgroundWithBlock:^(PFObject *post, NSError *error) {
                [PFCloud callFunctionInBackground:@"AddNewFriend"
                                   withParameters:@{@"senderUserId": [[PFUser currentUser] objectId], @"recipientUserId": [user objectId]}
                                            block:^(NSString *addFriendString, NSError *error1) {
                                                if (!error) {
                                                    
                                                } else {
                                                    NSLog(error1.description);
                                                }
                                            }];
                
                
                NSMutableArray *arrayOfFriends = [[NSMutableArray alloc] initWithArray:[PFUser currentUser][@"Friends"] copyItems:YES];
                
                [arrayOfFriends addObject:user.objectId];
                
                [PFUser currentUser][@"Friends"] = arrayOfFriends;
                
                [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                    if (!error) {
                        
                        NSString *pushMessage = [NSString stringWithFormat:@"%@ Just Accepted Your Friend Request!", [PFUser currentUser][@"username"]];
                        PFQuery *pushQuery = [PFInstallation query];
                        [pushQuery whereKey:@"user" equalTo:user];
                        
                        NSDictionary *data = @{
                                               @"alert" : pushMessage,
                                               @"badge" : @"Increment",
                                               @"sound" : @"default"
                                               };
                        PFPush *push = [[PFPush alloc] init];
                        [push setQuery:pushQuery];
                        [push setData:data];
                        [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                            if (succeeded && !error) {
                                
                                NSLog(@"success");
                                
                                alertVC = [[CustomAlert alloc] init];
                                [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:@"User %@ has been added to your friends list",user[@"username"]]];
                                [alertVC.alertView removeFromSuperview];
                                
                                [Hud removeFromSuperview];
                                
                            } else {
                                NSLog(@"%@",error.description);
                                
                                
                                alertVC = [[CustomAlert alloc] init];
                                [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:@"User %@ has been added to your friends list",user[@"username"]]];
                                [alertVC.alertView removeFromSuperview];
                                
                                [Hud removeFromSuperview];
                                
                            }
                        }];
                        [requestObject deleteInBackground];
                        [self setupFriendRequestGrid];
                        
                    } else {
                        NSLog(@"%@",error.description);
                    }
                }];
                
            }];
            [Hud removeFromSuperview];
        } else {
            [Hud removeFromSuperview];
        }
    }];
}
-(IBAction)declineFriendRequest:(UIButton*)sender {
    [self showLoading];
    NSString *objectId = sender.titleLabel.text;
    PFQuery *query = [PFQuery queryWithClassName:@"FriendRequests"];
    [query whereKey:@"objectId" equalTo:objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error){
                if(!error) {
                    [self setupFriendRequestGrid];
                    [Hud removeFromSuperview];
                }
            }];
            
        } else {
            [Hud removeFromSuperview];
        }
    }];
}
-(IBAction)backTappedFriendRequest:(UIButton*)sender {
    self.revealViewController.panGestureRecognizer.enabled=YES;
    if(sender.tag == 0) {
        pageScroller.scrollEnabled = YES;
        
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = YES;
        }
    } else {
        if(callerClickedChallengeBtn == 0) {
            pageScroller2.scrollEnabled = YES;
            for(UIView *subview in [pageScroller2 subviews]) {
                subview.userInteractionEnabled = YES;
            }
        } else {
            pageScroller.scrollEnabled = YES;
            for(UIView *subview in [pageScroller subviews]) {
                subview.userInteractionEnabled = YES;
            }
        }
    }
    
    [UIView animateWithDuration:0.5f // This can be changed.
                     animations:^
     {
         self.navigationController.navigationBar.alpha = 1;
         [backFriendRequestview setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
     }
                     completion:^(BOOL finished)
     {
         self.navigationController.navigationBar.alpha = 1;
         [backFriendRequestview setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
         [backFriendRequestview removeFromSuperview];
         
         view1.hidden = FALSE;
         view2.hidden = FALSE;
         view3.hidden = FALSE;
         searchBar.hidden = FALSE;
     }];
    
}


-(IBAction)finishChallenge:(UIButton*)sender {
    self.revealViewController.panGestureRecognizer.enabled=YES;
    if(sender.tag == 0) {
        pageScroller.scrollEnabled = YES;
        
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = YES;
        }
    } else {
        if(callerClickedChallengeBtn == 0) {
            pageScroller2.scrollEnabled = YES;
            for(UIView *subview in [pageScroller2 subviews]) {
                subview.userInteractionEnabled = YES;
            }
        } else {
            pageScroller.scrollEnabled = YES;
            for(UIView *subview in [pageScroller subviews]) {
                subview.userInteractionEnabled = YES;
            }
        }
    }
    
    [UIView animateWithDuration:0.5f // This can be changed.
                     animations:^
     {
         self.navigationController.navigationBar.alpha = 1;
         [backFriendRequestview setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
     }
                     completion:^(BOOL finished)
     {
         self.navigationController.navigationBar.alpha = 1;
         [backFriendRequestview setFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
         [backFriendRequestview removeFromSuperview];
         
         view1.hidden = FALSE;
         view2.hidden = FALSE;
         view3.hidden = FALSE;
         searchBar.hidden = FALSE;
     }];
    
}




-(IBAction) sendFBInvite:(id)sender {
    NSString *shareString = [NSString stringWithFormat:@"I'm using the Proludic Sport App! You should join and add me as a friend. My username is %@.\n\n https://itunes.apple.com/us/app/proludic-sport/id1268691512?mt=8", [PFUser currentUser][@"username"]];
    
    
    NSArray* sharedObjects=[NSArray arrayWithObjects:shareString,  nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:sharedObjects applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
    
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:shareString];
    NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++");
    
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.fromViewController = self;
    dialog.shareContent = content;
    dialog.mode = FBSDKShareDialogModeShareSheet;
    [dialog show];
}
-(void)setFriendsGrid:(NSArray*) objects :(NSArray*) collectedFriends {
    
    int count = 0;
    friendsSideScroller.contentSize = CGSizeMake(self.view.frame.size.width + [objects count]*48, 50);
    for (PFObject *object in objects) {
        
        //Exercise Bar Label
        UILabel *friendHeartsLabel;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(145 + count*63, 38, 65, 45)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(145 + count*63, 38, 65, 45)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(155 + count*63, 38, 70, 50)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(160 + count*63, 38, 75, 55)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(160 + count*63, 38, 75, 55)];
        } else {
            friendHeartsLabel = [[UILabel alloc] initWithFrame:CGRectMake(160 + count*63, 38, 75, 55)];
        }
        
        friendHeartsLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        friendHeartsLabel.textColor = [UIColor blackColor];
        friendHeartsLabel.numberOfLines = 1;
        friendHeartsLabel.textAlignment = NSTextAlignmentCenter;
        friendHeartsLabel.text = [object objectForKey:@"username"];
        
        UIButton *friendPictureBtn = [[UIButton alloc]init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            friendPictureBtn.frame = CGRectMake(160 + count*63, 13, 40, 40);
            
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            friendPictureBtn.frame = CGRectMake(160 + count*63, 13, 40, 40);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            friendPictureBtn.frame = CGRectMake(170 + count*63, 13, 40, 40);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            friendPictureBtn.frame = CGRectMake(177 + count*63, 13, 40, 40);
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            friendPictureBtn.frame = CGRectMake(177 + count*63, 13, 40, 40);
        } else {
            friendPictureBtn.frame = CGRectMake(177 + count*63, 13, 40, 40);
        }
        
        [friendPictureBtn setTitle:[object objectId] forState:UIControlStateNormal];
        friendPictureBtn.titleLabel.layer.opacity = 0.0f;
        friendPictureBtn.layer.cornerRadius = friendPictureBtn.frame.size.width / 2;
        friendPictureBtn.clipsToBounds = YES;
        friendPictureBtn.contentMode = UIViewContentModeScaleAspectFill;
        [friendPictureBtn addTarget:self action:@selector(tapFriendBtn:) forControlEvents:UIControlEventTouchUpInside];
        
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
        [friendsSideScroller addSubview:friendPictureBtn];
        count++;
        
    }
}

-(IBAction)tapFriendBtn:(UIButton*)sender {
    NSString *tmp = sender.titleLabel.text;
    clickedObjectId = tmp;
    
    NSLog(@"OPENED: ------------------ %@", tmp);
    [pageScroller removeFromSuperview];
    [self addFriendViews];
}

-(IBAction)openChallengePage:(UIButton*)sender {
    isOpenChallengePage = 1;
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
    }else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone XR/Max size
    {
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
    
    [view1 setTitle:NSLocalizedString(@"Friend List", nil) forState:UIControlStateNormal];
    [view2 setTitle:NSLocalizedString(@"Challenged Friends", nil) forState:UIControlStateNormal];
    [view3 setTitle:NSLocalizedString(@"Record", nil) forState:UIControlStateNormal];
    
    view1.tag = 111;
    [view1 addTarget:self action:@selector(tapBrowseAllFriends:) forControlEvents:UIControlEventTouchUpInside];
    view2.tag = 112;
    [view2 addTarget:self action:@selector(tapBrowseAllFriends:) forControlEvents:UIControlEventTouchUpInside];
    view3.tag = 113;
    [view3 addTarget:self action:@selector(tapBrowseAllFriends:) forControlEvents:UIControlEventTouchUpInside];
    
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
    
    //[self.view addSubview:view1];
    //[self.view addSubview:view2];
    //[self.view addSubview:view3];
    
    //Search Bar
    //Navigational Bar
    /*UIView *gapImage = [[UIView alloc] init];
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
     gapImage.frame = CGRectMake(0, 153, self.view.frame.size.width, 70); //Image scaled
     }
     
     [self.view addSubview:gapImage];*/
    
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
        searchBar.frame = CGRectMake(19, 208, self.view.frame.size.width - 40, 40);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        searchBar.frame = CGRectMake(19, 218, self.view.frame.size.width - 40, 40);
    } else {
        searchBar.frame = CGRectMake(19, 165, self.view.frame.size.width - 40, 40);
    }
    searchBar.barTintColor = [UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0];
    searchBar.layer.borderWidth = 1;
    searchBar.layer.borderColor = [[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0] CGColor];
    UITextField *searchField = [searchBar valueForKey:@"searchField"];
    
    // To change background color
    searchField.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
    searchBar.delegate = self;
    [self tapBrowseAllFriends:view1];
    //[self.view addSubview:searchBar];
}
NSMutableArray *challengedFriends;
NSMutableArray *challengedObjects;
int pageNumber;
-(IBAction)tapBrowseAllFriends:(UIButton*)sender
{
    if(sender.tag == 111) {
        [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    } else if (sender.tag == 112) {
        [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [view2 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
        [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [view1 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
        [view3 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    }
    [self showLoading];
    
    PFQuery * browseAllQuery = [PFUser query];
    [browseAllQuery orderByAscending:@"username"];
    [browseAllQuery whereKey:@"objectId" containedIn:[PFUser currentUser][@"Friends"]];
    [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
             PFQuery *subquery21 = [PFQuery queryWithClassName:@"FriendRequests"];
             [subquery21 whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
             
             PFQuery *subquery22 = [PFQuery queryWithClassName:@"FriendRequests"];
             [subquery22 whereKey:@"UserRequesting" equalTo:[PFUser currentUser]];
             PFQuery *query2 = [PFQuery orQueryWithSubqueries:@[subquery21,subquery22]];
             [query2 whereKey:@"isChallenge" equalTo:[NSNumber numberWithBool:YES]];
             if(sender.tag != 113) {
                 NSLog(@"===========================================================================%ld", sender.tag);
                 [query2 whereKey:@"isComplete" equalTo:[NSNumber numberWithBool:NO]];
             } else {
                 NSLog(@"===========================================================================~~~~~~~~~~~~~~~~~~~~%ld", sender.tag);
                 [query2 whereKey:@"isComplete" equalTo:[NSNumber numberWithBool:YES]];
             }
             
             [query2 findObjectsInBackgroundWithBlock:^(NSArray *objs, NSError *error2)
              {
                  if (!error) {
                      challengedObjects = objs;
                      challengedFriends = [[NSMutableArray alloc] init];
                      for (PFObject *obj in challengedObjects) {
                          if([[obj[@"UserRequested"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                              [challengedFriends addObject:obj[@"UserRequesting"]];
                              
                          } else {
                              [challengedFriends addObject:obj[@"UserRequested"]];
                              
                          }
                      }
                      if(sender.tag == 111) {
                          pageNumber = 1;
                          collectedFriends = objects;
                          [self setChallegeFriendGrid:objects: challengedObjects: challengedFriends: 1];
                      } else if (sender.tag == 112) {
                          pageNumber = 2;
                          [self setChallegeFriendGrid:objects: challengedObjects: challengedFriends: 2];
                      } else {
                          [self setChallegeRecordGrid:objects: challengedObjects: challengedFriends];
                      }
                  } else {
                      NSLog(@"-------------- %@", [error2 description]);
                  }
                  [self.view addSubview:view1];
                  [self.view addSubview:view2];
                  [self.view addSubview:view3];
                  if(sender.tag != 113) {
                      [self.view addSubview:searchBar];
                  } else {
                      [searchBar removeFromSuperview];
                  }
                  [Hud removeFromSuperview];
              }];
             
         } else{
             NSLog(@"-------------- %@", [error description]);
             [self.view addSubview:view1];
             [self.view addSubview:view2];
             [self.view addSubview:view3];
             if(sender.tag != 113) {
                 [self.view addSubview:searchBar];
             } else {
                 [searchBar removeFromSuperview];
             }
             [Hud removeFromSuperview];
         }
         
     }];
}
-(void)setChallegeRecordGrid:(NSMutableArray*) friendObjects :(NSMutableArray*) challengedObjects: (NSMutableArray*) challengedFriends {
    NSLog(@"------------------ %@", challengedFriends);
    NSLog(@"------------------ %@", challengedObjects);
    int y = 150;
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 90 - 200 + y);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 50 + y);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200 + y);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200 + y);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200 + y);
    } else {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200 + y);
    }
    
    UILabel *topAchiever5 = [[UILabel alloc]init];
    topAchiever5.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
    } else {
        topAchiever5.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        topAchiever5.frame = CGRectMake(0, 75, self.view.frame.size.width, 20);
    }
    
    topAchiever5.text = [NSString stringWithFormat:NSLocalizedString(@"Finished Challenges", nil)];
    
    topAchiever5.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:topAchiever5];
    
    UIImageView *topRankPicture7 = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 40, 105, 80, 75);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 40, 105, 80, 75);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 45, 125, 90, 85);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 45, 125, 90, 85);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 45, 125, 90, 85);
    } else {
        topRankPicture7.frame = CGRectMake(self.view.frame.size.width/4 - 45, 125, 90, 85);
    }
    //topRankPicture7.image = [UIImage imageNamed:@"leaderboard_rank"];
    topRankPicture7.image = [UIImage imageNamed:@"heart_gold"];
    [pageScroller addSubview:topRankPicture7];
    
    UILabel *totalWins = [[UILabel alloc]init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height ==736)
    {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
        
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
    } else {
        totalWins.frame = CGRectMake(self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    totalWins.text = [NSString stringWithFormat:@"%@ %@", [PFUser.currentUser valueForKey:@"wins"], @"Wins"];
    [pageScroller addSubview:totalWins];
    
    UILabel *totalDraws = [[UILabel alloc]init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height ==736)
    {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
        
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
    } else {
        totalDraws.frame = CGRectMake(self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    totalDraws.text = [NSString stringWithFormat:@"%@ %@", @"Draws: ", [PFUser.currentUser valueForKey:@"draw"]];
    [pageScroller addSubview:totalDraws];
    
    
    
    
    UIImageView *topAchieverPicture5 = [[UIImageView alloc]init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 100, 80, 75);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 100, 80, 75);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 125, 90, 85);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        
    {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 125, 90, 85);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 125, 90, 85);
    } else {
        topAchieverPicture5.frame = CGRectMake(3*self.view.frame.size.width/4 - 45, 125, 90, 85);
    }
    
    topAchieverPicture5.image = [UIImage imageNamed:@"heart_broken"];
    [pageScroller addSubview:topAchieverPicture5];
    
    
    UILabel *totalLosses = [[UILabel alloc]init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height ==736)
    {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
        
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
    } else {
        totalLosses.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 220, 80, 15);
    }
    totalLosses.text = [NSString stringWithFormat:@"%@ %@", [PFUser.currentUser valueForKey:@"loss"], @"Losses"];
    [pageScroller addSubview:totalLosses];
    
    UILabel *totalCompetation = [[UILabel alloc]init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    else if([[UIScreen mainScreen] bounds].size.height ==736)
    {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
        
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
    } else {
        totalCompetation.frame = CGRectMake(3*self.view.frame.size.width/4 - 40, 250, 80, 15);
    }
    int winsTimes = [[PFUser.currentUser valueForKey:@"wins"] intValue];
    int lossTimes = [[PFUser.currentUser valueForKey:@"loss"] intValue];
    int drawTimes = [[PFUser.currentUser valueForKey:@"draw"] intValue];
    totalCompetation.text = [NSString stringWithFormat:@"%@ %d", @"Total: ", winsTimes+lossTimes+drawTimes];
    [pageScroller addSubview:totalCompetation];
    
    
    
    
    int count = 0;
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [challengedFriends count]; i++) {
        PFObject *object;
        bool *isContinue = YES;
        for(PFObject *tmpObj2 in friendObjects) {
            if([[[challengedFriends objectAtIndex:i] objectId] isEqualToString:[tmpObj2 objectId]]) {
                object = tmpObj2;
                isContinue = NO;
            }
        }
        
        if(isContinue) {
            continue;
        }
        PFObject *recordObject = [challengedObjects objectAtIndex:i];
        UIView *friendView = [[UIView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        } else {
            [friendView setFrame:CGRectMake(0, 120 + count*140 + y, self.view.frame.size.width, 80)];
        }
        [friendView setBackgroundColor:[UIColor whiteColor]];
        [pageScroller addSubview:friendView];
        
        //Exercise Bar Label
        UILabel *title;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(85, 135 + count*140 + y, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(85, 135 + count*140 + y, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(120, 135 + count*140 + y, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(120, 135 + count*140 + y, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(120, 135 + count*140 + y, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else {
            title = [[UILabel alloc] initWithFrame:CGRectMake(120, 135 + count*140 + y, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        
        title.textColor = [UIColor blackColor];
        title.numberOfLines = 2;
        title.textAlignment = NSTextAlignmentLeft;
        title.text = [NSString stringWithFormat:@"%@ %@",[object objectForKey:@"username"], @" VS. You"];
        [pageScroller addSubview:title];
        
        
        //add by chang start
        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"dd/MM/yyyy";
        NSDate* beginDate = [formatter dateFromString:recordObject[@"Date"]];
        NSString* beginDateString = [formatter stringFromDate:beginDate];
        
        NSDateComponents* comps = [[NSDateComponents alloc]init];
        NSNumber* days =  recordObject[@"LengthTime"];
        comps.day = days.longValue;
        
        
        
        NSCalendar* calendar = [NSCalendar currentCalendar];
        
        NSDate* newDate = [calendar dateByAddingComponents:comps toDate:beginDate options:0];
        
        NSString* interDateString = [formatter stringFromDate:newDate];
        
        
        //test
        NSMutableArray *totalDates = [@[beginDateString] mutableCopy];
        for (int i = 1; i < comps.day; ++i) {
            NSDateComponents *newComponents = [NSDateComponents new];
            newComponents.day = i;
            
            NSDate *date = [calendar dateByAddingComponents:newComponents toDate:beginDate options:0];
            NSString* dateString = [formatter stringFromDate:date];
            [totalDates addObject:dateString];
        }
        [totalDates addObject:interDateString];
        //test
        
        
        Boolean isWeight = [recordObject[@"isWeight"]boolValue];
        
        PFQuery *query = [PFQuery queryWithClassName:@"TrackedEvents"];
        [query whereKey:@"User" equalTo:PFUser.currentUser];
        [query whereKey:@"Date" containedIn:totalDates];
        //        NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        NSArray* queryArray = [query findObjects];
        //        NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%long", queryArray.count);
        int UserTotalScore = 0;
        for(PFObject* j in queryArray){
            //            NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%@", j[@"Hearts"]);
            if(isWeight){
                UserTotalScore = UserTotalScore + [j[@"Exercises"] intValue];
            }else{
                UserTotalScore = UserTotalScore + [j[@"Hearts"] intValue];
            }
        }
        
        
        
        PFQuery* query1 = [PFQuery queryWithClassName:@"TrackedEvents"];
        [query1 whereKey:@"User" equalTo:[challengedFriends objectAtIndex:i]];
        [query1 whereKey:@"Date" containedIn:totalDates];
        NSArray* queryArray1 = [query1 findObjects];
        //        NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%long", queryArray1.count);
        int FriendTotalScore = 0;
        for(PFObject* j_1 in queryArray1){
            //            NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++%@", j_1[@"Hearts"]);
            if(isWeight){
                FriendTotalScore = FriendTotalScore + [j_1[@"Exercises"] intValue];
            }else{
                FriendTotalScore = FriendTotalScore + [j_1[@"Hearts"] intValue];
            }
        }
        
        
        NSString *WhoWin;
        if(UserTotalScore>FriendTotalScore){
            WhoWin = @"You Win!!!";
        }else if(UserTotalScore == FriendTotalScore){
            WhoWin = @"You Draw";
            
        }else{
            WhoWin = @"You Lose";
        }
        
        //add by chang end
        
        
        UILabel *whoWin;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        } else {
            whoWin = [[UILabel alloc] initWithFrame:CGRectMake(160, 175 + count*140 + y, 220, 30)];
        }
        whoWin.text = [NSString stringWithFormat:@"%@", WhoWin];
        [pageScroller addSubview:whoWin];
        
        UILabel *scoreVS;
        UIImageView *challengType;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        } else {
            scoreVS = [[UILabel alloc] initWithFrame:CGRectMake(160, 195 + count*140 + y, 220, 30)];
            challengType = [[UIImageView alloc] initWithFrame:CGRectMake(140, 202 + count*140 + y, 15, 15)];
        }
        
        scoreVS.text = [NSString stringWithFormat:@"%d VS %d", FriendTotalScore, UserTotalScore];
        if(isWeight){
            challengType.image = [UIImage imageNamed:@"ic_weight"];
        }else{
            challengType.image = [UIImage imageNamed:@"Heart"];
        }
        
        [pageScroller addSubview:scoreVS];
        [pageScroller addSubview:challengType];
        
        UILabel *DateThrough;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        } else {
            DateThrough = [[UILabel alloc] initWithFrame:CGRectMake(100, 215 + count*140 + y, 300, 30)];
        }
        
        
        DateThrough.text = [NSString stringWithFormat:@"Date: %@ - %@",recordObject[@"Date"],interDateString];
        [pageScroller addSubview:DateThrough];
        
        
        
        
        
        
        
        //Exercise Bar Button Star
        
        //Image Thumbnail
        UIImageView *brandedImg = [[UIImageView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
            
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
        } else {
            brandedImg.frame = CGRectMake(25, 145 + count*135 + y, 75, 75); //Image scaled
        }
        CALayer *imageLayer = brandedImg.layer;
        [imageLayer setCornerRadius:5];
        [imageLayer setBorderWidth:1];
        [brandedImg.layer setCornerRadius:brandedImg.frame.size.width/2];
        [imageLayer setMasksToBounds:YES];
        brandedImg.layer.borderWidth = 2.0f;
        brandedImg.layer.borderColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0].CGColor;
        
        
        
        
        
        
        
        if([object[@"profilePicture"] isEqualToString:@"NoPicture"]) {
            //User hasnt set a profile picture
            brandedImg.image = [UIImage imageNamed:@"profile_pic"];
        } else {
            NSString *imageUrl = [object objectForKey:@"profilePicture"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    brandedImg.image =  [UIImage imageWithData:data];
                    
                });
            });
        }
        [pageScroller addSubview:brandedImg];
        count++;
    }
    [Hud removeFromSuperview];
}


-(void)setChallegeFriendGrid:(NSMutableArray*) friendObjects :(NSMutableArray*) challengedObjects: (NSMutableArray*) challengedFriends: (int) pageNumber{
    for(UIView *subview in [pageScroller subviews]) {
        [subview removeFromSuperview];
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 90 - 200);    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200);
    } else {
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, pageScroller.frame.size.height + friendObjects.count * 85 - 200);
    }
    
    int count = 0;
    //NSMutableArray *tmp = [[NSMutableArray alloc] init];
    
    for (PFObject *object in friendObjects) {
        bool *isChallenged = NO;
        for(PFObject *tmp in challengedFriends) {
            if([[object objectId] isEqualToString:[tmp objectId]]) {
                isChallenged = YES;
            }
        }
        if(pageNumber == 2 && !isChallenged) {
            continue;
        }
        UIView *friendView = [[UIView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        } else {
            [friendView setFrame:CGRectMake(0, 120 + count*90, self.view.frame.size.width, 80)];
        }
        [friendView setBackgroundColor:[UIColor whiteColor]];
        [pageScroller addSubview:friendView];
        
        //Exercise Bar Label
        UILabel *title;
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 135 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(65, 135 + count*90, 200, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(100, 135 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 135 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 135 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        } else {
            title = [[UILabel alloc] initWithFrame:CGRectMake(90, 135 + count*90, 220, 60)];
            title.font = [UIFont fontWithName:@"ethnocentric" size:14];
        }
        
        title.textColor = [UIColor blackColor];
        title.numberOfLines = 2;
        title.textAlignment = NSTextAlignmentLeft;
        title.text = [object objectForKey:@"username"];
        [pageScroller addSubview:title];
        
        //Exercise Bar Button Star
        
        UIButton *starBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            [starBtn setFrame:CGRectMake(210, 150 + count*90, 150, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            [starBtn setFrame:CGRectMake(210, 150 + count*90, 150, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            [starBtn setFrame:CGRectMake(210, 150 + count*90, 150, 30)];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            [starBtn setFrame:CGRectMake(210, 150 + count*90, 150, 30)];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            [starBtn setFrame:CGRectMake(220, 150 + count*90, 150, 30)];
        } else {
            [starBtn setFrame:CGRectMake(220, 150 + count*90, 150, 30)];
        }
        [starBtn setTitle:[object objectId] forState:UIControlStateNormal];
        starBtn.titleLabel.layer.opacity = 0.0f;
        
        callerClickedChallengeBtn = 1;
        if(isChallenged) {
            starBtn.tag = 1002; // View Info Button
            [starBtn setImage:[UIImage imageNamed:@"btn_infochallenge"] forState:UIControlStateNormal];
            [starBtn addTarget:self action:@selector(clickedChallengeBtn:) forControlEvents:UIControlEventTouchUpInside];
        } else {
            starBtn.tag = 1001; // Challenge Button
            [starBtn setImage:[UIImage imageNamed:@"btn_challenge"] forState:UIControlStateNormal];
            [starBtn addTarget:self action:@selector(clickedChallengeBtn:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [pageScroller addSubview:starBtn];
        
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
        
        if([object[@"profilePicture"] isEqualToString:@"NoPicture"]) {
            //User hasnt set a profile picture
            brandedImg.image = [UIImage imageNamed:@"profile_pic"];
        } else {
            NSString *imageUrl = [object objectForKey:@"profilePicture"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    brandedImg.image =  [UIImage imageWithData:data];
                    
                });
            });
        }
        [pageScroller addSubview:brandedImg];
        count++;
    }
    [Hud removeFromSuperview];
}

- (void)viewDidUnload {
    [self setSearchBar:nil];
    [self setSearchBarController:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)resetData
{
    [self setChallegeFriendGrid:collectedFriends :challengedObjects:challengedFriends: pageNumber];
}
- (void)searchTableList
{
    NSMutableArray *tmp = [NSMutableArray array];;
    NSString *searchString = searchBar.text;
    NSLog(@"Search Text %@",searchBar.text);
    for (PFObject *object in collectedFriends) {
        NSString *text = object[@"username"];
        if([[text lowercaseString] containsString:[searchString lowercaseString]]) {
            [tmp addObject:object];
        }
    }
    [self setChallegeFriendGrid:tmp :challengedObjects:challengedFriends: pageNumber];
    
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

-(void)addFriendViews {
    
    pageScroller2 = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller2.frame = CGRectMake(0, 93, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller2.frame = CGRectMake(0, 93, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller2.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller2.frame = CGRectMake(0, 94, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller2.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        pageScroller2.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    } else {
        pageScroller2.frame = CGRectMake(0, 154, self.view.frame.size.width, self.view.frame.size.height-50); //Position of the scroller
        pageScroller2.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    }
    
    pageScroller2.bounces = NO;
    [pageScroller2 setShowsVerticalScrollIndicator:NO];
    [self.view addSubview:pageScroller2];
    
    //Load User Query
    
    PFQuery *loadFriendQuery = [PFUser query];
    [loadFriendQuery whereKey:@"objectId" equalTo:clickedObjectId];
    [loadFriendQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (!error) {
            NSLog(@"%@", object);
            
            UIImageView *friendPicture = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 13, 70, 70);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 13, 70, 70);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 13, 80, 80);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 13, 80, 80);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 13, 80, 80);
            } else {
                friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 13, 80, 80);
            }
            
            friendPicture.layer.cornerRadius = friendPicture.frame.size.width / 2;
            friendPicture.clipsToBounds = YES;
            friendPicture.contentMode = UIViewContentModeScaleAspectFill;
            
            if([object[@"profilePicture"] isEqualToString:@"NoPicture"]) {
                //User hasnt set a profile picture
                friendPicture.image = [UIImage imageNamed:@"profile_pic"];
            } else {
                NSString *imageUrl = object[@"profilePicture"];
                dispatch_async(dispatch_get_global_queue(0,0), ^{
                    
                    NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                    if ( data == nil )
                        return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        friendPicture.image = [UIImage imageWithData:data];
                        
                    });
                });
            }
            
            [pageScroller2 addSubview:friendPicture];
            
            NSLog(@"PROLUDIC STATUS: %@", clickedObjectId);
            
            PFQuery *getIdQuery = [PFUser query];
            PFObject *tmpObj = [PFObject objectWithoutDataWithClassName:@"UserAchievements" objectId:clickedObjectId];
            [getIdQuery whereKey:@"User" equalTo:tmpObj];
            [getIdQuery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
                if (!error) {
                    NSLog(@" -x-x-x-x-x-x- %@", tmpObj);
                    NSLog(@" -x-x-x-x-x-x- %@", [PFUser currentUser]);
                    
                    PFQuery * statusQuery = [PFQuery queryWithClassName:@"UserAchievements"];
                    [statusQuery whereKey:@"User" equalTo:tmpObj];
                    [statusQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        
                        if (!error) {
                            for (PFObject *coinObject in objects) {
                                if (([coinObject[@"ProludicCopper"]  isEqual: @YES] && [coinObject[@"BodyweightCopper"]  isEqual: @YES]) && ([coinObject[@"ProludicBronze"]  isEqual: @NO] || [coinObject[@"BodyweightBronze"]  isEqual: @NO])) {
                                    NSLog(@"PROLUDIC STATUS: Copper");
                                    userStatus.image = [UIImage imageNamed:@"coin_copper"];
                                } else if (([coinObject[@"ProludicBronze"]  isEqual: @YES] && [coinObject[@"BodyweightBronze"]  isEqual: @YES]) && ([coinObject[@"ProludicSilver"]  isEqual: @NO] || [coinObject[@"BodyweightSilver"]  isEqual: @NO])) {
                                    NSLog(@"PROLUDIC STATUS: Bronze");
                                    userStatus.image = [UIImage imageNamed:@"coin_bronze"];
                                } else if (([coinObject[@"ProludicSilver"]  isEqual: @YES] && [coinObject[@"BodyweightSilver"]  isEqual: @YES]) && ([coinObject[@"ProludicGold"]  isEqual: @NO] || [coinObject[@"BodyweightGold"]  isEqual: @NO])) {
                                    NSLog(@"PROLUDIC STATUS: Silver");
                                    userStatus.image = [UIImage imageNamed:@"coin_silver"];
                                } else if (([coinObject[@"ProludicGold"]  isEqual: @YES] && [coinObject[@"BodyweightGold"]  isEqual: @YES]) && ([coinObject[@"ProludicPlatinum"]  isEqual: @NO] || [coinObject[@"BodyweightPlatinum"]  isEqual: @NO])) {
                                    NSLog(@"PROLUDIC STATUS: Gold");
                                    userStatus.image = [UIImage imageNamed:@"coin_gold"];
                                } else if (([coinObject[@"ProludicPlatinum"]  isEqual: @YES] && [coinObject[@"BodyweightPlatinum"]  isEqual: @YES]) && ([coinObject[@"ProludicDiamond"]  isEqual: @NO] || [coinObject[@"BodyweightDiamond"]  isEqual: @NO])) {
                                    NSLog(@"PROLUDIC STATUS: Platinum");
                                    userStatus.image = [UIImage imageNamed:@"coin_platinum"];
                                } else if ([coinObject[@"ProludicDiamond"]  isEqual: @YES] && [coinObject[@"BodyweightDiamond"]  isEqual: @YES]) {
                                    NSLog(@"PROLUDIC STATUS: Diamond");
                                    userStatus.image = [UIImage imageNamed:@"coin_diamond"];
                                } else {
                                    NSLog(@"PROLUDIC STATUS: NOTHING!");
                                }
                            }
                        } else {
                            NSLog(@"Failed %@", error.description);
                        }
                    }];
                } else {
                    NSLog(@"Failed Main Query %@", error.description);
                }
            }];
            
            userStatus = [[UIImageView alloc]init];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                userStatus.frame = CGRectMake(15, 15, 22, 22);
                
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
            {
                userStatus.frame = CGRectMake(15, 15, 22, 22);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                userStatus.frame = CGRectMake(20, 20, 25, 25);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                userStatus.frame = CGRectMake(25, 20, 28, 28);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                userStatus.frame = CGRectMake(25, 20, 28, 28);
            } else {
                userStatus.frame = CGRectMake(25, 20, 28, 28);
            }
            [pageScroller2 addSubview:userStatus];
            
            UILabel *nameLabel = [[UILabel alloc] init];
            nameLabel.frame = CGRectMake(30, 85, self.view.frame.size.width - 60, 50);
            nameLabel.text = object[@"name"];
            nameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16];
            nameLabel.textAlignment = NSTextAlignmentCenter;
            
            [pageScroller2 addSubview:nameLabel];
            
            //Win Loss Draw Sting Combine
            NSString *wins = object[@"wins"];
            NSString *loss = object[@"loss"];
            NSString *draw = object[@"draw"];
            NSString *combined = [NSString stringWithFormat:NSLocalizedString(@"%@W-%@L-%@D", nil), wins, loss, draw];
            
            
            UILabel *wldLabel = [[UILabel alloc] init];
            wldLabel.frame = CGRectMake(30, 170, self.view.frame.size.width - 60, 50);
            wldLabel.text = combined;
            wldLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
            wldLabel.textAlignment = NSTextAlignmentCenter;
            
            [pageScroller2 addSubview:wldLabel];
            
            //Heart Int Conversion
            NSString *friendHearts = [NSString stringWithFormat:NSLocalizedString(@"Hearts: %@", nil), object[@"Hearts"]];
            
            UILabel *heartsLabel = [[UILabel alloc] init];
            heartsLabel.frame = CGRectMake(30, 190, self.view.frame.size.width - 60, 50);
            heartsLabel.text = friendHearts;
            heartsLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
            heartsLabel.textAlignment = NSTextAlignmentCenter;
            
            [pageScroller2 addSubview:heartsLabel];
            
            UILabel *friendParkLabel = [[UILabel alloc] init];
            friendParkLabel.frame = CGRectMake(30, 110, self.view.frame.size.width - 60, 50);
            friendParkLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
            friendParkLabel.textAlignment = NSTextAlignmentCenter;
            
            [pageScroller2 addSubview:friendParkLabel];
            
            UIButton *challengeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if ([[UIScreen mainScreen] bounds].size.height == 480)
            {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 568)
            {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
            {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            }
            else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            } else {
                challengeBtn.frame = CGRectMake(self.view.frame.size.width / 2 - 90, 150, 180, 33);
            }
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            if([language containsString:@"fr"]) {
                [challengeBtn setImage:[UIImage imageNamed:@"btn_challengefriend_french"] forState:UIControlStateNormal];
            } else {
                [challengeBtn setImage:[UIImage imageNamed:@"btn_challenge"] forState:UIControlStateNormal];
            }
            [challengeBtn setTitle:[object objectId] forState:UIControlStateNormal];
            challengeBtn.titleLabel.layer.opacity = 0.0f;
            callerClickedChallengeBtn = 0;
            [challengeBtn addTarget:self action:@selector(clickedChallengeBtn:) forControlEvents:UIControlEventTouchUpInside];
            
            [pageScroller2 addSubview:challengeBtn];
            
            //Query to get Home Park from id
            PFQuery *homeQuery = [PFQuery queryWithClassName:@"Locations"];
            [homeQuery whereKey:@"objectId" equalTo:object[@"HomePark"]];
            [homeQuery getFirstObjectInBackgroundWithBlock:^(PFObject *location, NSError *error) {
                
                if (!error) {
                    NSLog(@"%@", location);
                    NSString *homepark = [NSString stringWithFormat:@"%@", location[@"Location"]];
                    friendParkLabel.text = homepark;
                } else {
                    friendParkLabel.text = NSLocalizedString(@"Home Park Not Selected", nil);
                }
            }];
            
            UILabel *descLabel = [[UILabel alloc] init];
            descLabel.frame = CGRectMake(30, 220, self.view.frame.size.width - 60, 50);
            descLabel.numberOfLines = 4;
            descLabel.text = object[@"Description"];
            descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
            descLabel.textAlignment = NSTextAlignmentCenter;
            
            [pageScroller2 addSubview:descLabel];
            
            //DIVIDER
            
            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [UIColor grayColor];
            line.frame = CGRectMake(20, 280, self.view.frame.size.width - 40, 2);
            
            [pageScroller2 addSubview:line];
            
            //DIVIDER
            
            
            
        }
    }];
    
}

-(IBAction)tapAddFriend:(id)sender {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Friend", nil)
                                                                   message:NSLocalizedString(@"Add a friend by a username", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add Friend", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *username = alert.textFields[0].text;
                                                              
                                                              if ( [username caseInsensitiveCompare:@""] == NSOrderedSame ) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"Please add a username", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              }
                                                              else {
                                                                  if ([username isEqualToString:[PFUser currentUser][@"username"]]){
                                                                      
                                                                      alertVC = [[CustomAlert alloc] init];
                                                                      [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"You cannot add yourself as a friend!", nil)];
                                                                      [alertVC.alertView removeFromSuperview];
                                                                      
                                                                  }
                                                                  else {
                                                                      [self showLoading];
                                                                      
                                                                      PFQuery *userQuery = [PFUser query];
                                                                      [userQuery whereKey:@"username" equalTo:username];
                                                                      [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject * object, NSError * error) {
                                                                          if (!error) {
                                                                              
                                                                              if ([[PFUser currentUser][@"Friends"] containsObject:object.objectId]) {
                                                                                  
                                                                                  alertVC = [[CustomAlert alloc] init];
                                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):[NSString stringWithFormat:NSLocalizedString(@"You are already friends with %@, please choose a different username!", nil),username]];
                                                                                  [alertVC.alertView removeFromSuperview];
                                                                                  
                                                                                  [Hud removeFromSuperview];
                                                                                  
                                                                              } else {
                                                                                  PFQuery *queryRequest = [PFQuery queryWithClassName:@"FriendRequests"];
                                                                                  [queryRequest whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
                                                                                  [queryRequest whereKey:@"UserRequesting" equalTo:object];
                                                                                  [queryRequest getFirstObjectInBackgroundWithBlock:^(PFObject *tmpObj, NSError *tmpError) {
                                                                                      if (!tmpError) {
                                                                                          [PFCloud callFunctionInBackground:@"AddNewFriend"
                                                                                                             withParameters:@{@"senderUserId": [[PFUser currentUser] objectId], @"recipientUserId": [object objectId]}
                                                                                                                      block:^(NSString *addFriendString, NSError *error) {
                                                                                                                          if (!error) {
                                                                                                                              
                                                                                                                          } else {
                                                                                                                              NSLog(error.description);
                                                                                                                          }
                                                                                                                      }];
                                                                                          
                                                                                          
                                                                                          NSMutableArray *arrayOfFriends = [[NSMutableArray alloc] initWithArray:[PFUser currentUser][@"Friends"] copyItems:YES];
                                                                                          
                                                                                          [arrayOfFriends addObject:object.objectId];
                                                                                          
                                                                                          [PFUser currentUser][@"Friends"] = arrayOfFriends;
                                                                                          
                                                                                          [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                                                              if (!error) {
                                                                                                  
                                                                                                  NSString *pushMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ Just Accepted Your Friend Request", nil), [PFUser currentUser][@"username"]];
                                                                                                  PFQuery *pushQuery = [PFInstallation query];
                                                                                                  [pushQuery whereKey:@"user" equalTo:object];
                                                                                                  
                                                                                                  NSDictionary *data = @{
                                                                                                                         @"alert" : pushMessage,
                                                                                                                         @"badge" : @"Increment",
                                                                                                                         @"sound" : @"default"
                                                                                                                         };
                                                                                                  PFPush *push = [[PFPush alloc] init];
                                                                                                  [push setQuery:pushQuery];
                                                                                                  [push setData:data];
                                                                                                  [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                                                                      if (succeeded && !error) {
                                                                                                          
                                                                                                          alertVC = [[CustomAlert alloc] init];
                                                                                                          [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:NSLocalizedString(@"User %@ has been added to your friends list", nil),username]];
                                                                                                          [alertVC.alertView removeFromSuperview];
                                                                                                          
                                                                                                          [Hud removeFromSuperview];
                                                                                                          
                                                                                                      } else {
                                                                                                          NSLog(@"%@",error.description);
                                                                                                          
                                                                                                          alertVC = [[CustomAlert alloc] init];
                                                                                                          [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:NSLocalizedString(@"User %@ has been added to your friends list", nil),username]];
                                                                                                          [alertVC.alertView removeFromSuperview];
                                                                                                          
                                                                                                          [Hud removeFromSuperview];
                                                                                                          
                                                                                                      }
                                                                                                  }];
                                                                                                  
                                                                                              } else {
                                                                                                  NSLog(@"%@",error.description);
                                                                                              }
                                                                                          }];
                                                                                          [tmpObj deleteInBackground];
                                                                                      } else {
                                                                                          if(tmpError.code == 101) {
                                                                                              PFQuery *queryFriendRequest = [PFQuery queryWithClassName:@"FriendRequests"];
                                                                                              [queryFriendRequest whereKey:@"UserRequested" equalTo:object];
                                                                                              [queryFriendRequest whereKey:@"UserRequesting" equalTo:[PFUser currentUser]];
                                                                                              [queryFriendRequest getFirstObjectInBackgroundWithBlock:^(PFObject *tmp, NSError *error) {
                                                                                                  if (!error) {
                                                                                                      
                                                                                                      alertVC = [[CustomAlert alloc] init];
                                                                                                      [alertVC loadSingle:self.view:NSLocalizedString(@"Failed!", nil):[NSString stringWithFormat:NSLocalizedString(@"You already sent user %@ a friend request", nil),username]];
                                                                                                      [alertVC.alertView removeFromSuperview];
                                                                                                      
                                                                                                      [Hud removeFromSuperview];
                                                                                                      
                                                                                                  } else {
                                                                                                      // Log details of the failure
                                                                                                      NSLog(@"Error: %@ %@", error, [error userInfo]);
                                                                                                      if(error.code == 101) {
                                                                                                          PFObject *friendRequest = [PFObject objectWithClassName:@"FriendRequests"];
                                                                                                          friendRequest[@"UserRequested"] = object;
                                                                                                          friendRequest[@"UserRequesting"] = [PFUser currentUser];
                                                                                                          friendRequest[@"accepted"] = @NO;
                                                                                                          friendRequest[@"isPending"] = @YES;
                                                                                                          friendRequest[@"isChallenge"] = @NO;
                                                                                                          friendRequest[@"isComplete"] = @NO;
                                                                                                          friendRequest[@"isWeight"] = @NO;
                                                                                                          friendRequest[@"LengthTime"] = @0;
                                                                                                          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                                                                                          [formatter setDateFormat:@"dd/MM/yyyy"];
                                                                                                          
                                                                                                          NSDate *currentDate = [NSDate date];
                                                                                                          friendRequest[@"Date"] = [formatter stringFromDate:currentDate];
                                                                                                          [friendRequest saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                                                              if (succeeded) {
                                                                                                                  
                                                                                                                  alertVC = [[CustomAlert alloc] init];
                                                                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:NSLocalizedString(@"User %@ has received your friend request", nil),username]];
                                                                                                                  [alertVC.alertView removeFromSuperview];
                                                                                                                  
                                                                                                                  PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                                                                                                                  [query whereKey:@"User" equalTo:[PFUser currentUser]];
                                                                                                                  [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                                                                                                                      if (!error) {
                                                                                                                          
                                                                                                                          if ([userAchie[@"Socialize"]  isEqual: @NO]) {
                                                                                                                              userAchie[@"Socialize"] = @YES;
                                                                                                                              userAchie[@"User"] = [PFUser currentUser];
                                                                                                                              [userAchie saveInBackground];
                                                                                                                              
                                                                                                                              [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                                                                                                                              [Flurry logEvent:@"User Unlocked Socialize Achievement" timed:YES];
                                                                                                                              
                                                                                                                              alertVC = [[CustomAlert alloc] init];
                                                                                                                              [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Socialize' achievement! Well Done!", nil)];
                                                                                                                              [alertVC.alertView removeFromSuperview];
                                                                                                                              
                                                                                                                          }
                                                                                                                      } else {
                                                                                                                          //
                                                                                                                      }
                                                                                                                  }];
                                                                                                                  
                                                                                                                  NSString *pushMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ Just Sent You A Friend Request!", nil), [PFUser currentUser][@"username"]];
                                                                                                                  PFQuery *pushQuery = [PFInstallation query];
                                                                                                                  [pushQuery whereKey:@"user" equalTo:object];
                                                                                                                  
                                                                                                                  NSDictionary *data = @{
                                                                                                                                         @"alert" : pushMessage,
                                                                                                                                         @"badge" : @"Increment",
                                                                                                                                         @"sound" : @"default"
                                                                                                                                         };
                                                                                                                  PFPush *push = [[PFPush alloc] init];
                                                                                                                  [push setQuery:pushQuery];
                                                                                                                  [push setData:data];
                                                                                                                  [push sendPushInBackground];
                                                                                                              } else {
                                                                                                                  // There was a problem, check error.description
                                                                                                              }
                                                                                                              [Hud removeFromSuperview];
                                                                                                          }];
                                                                                                      }
                                                                                                      [Hud removeFromSuperview];
                                                                                                  }
                                                                                                  
                                                                                              }];
                                                                                              
                                                                                              /*[PFCloud callFunctionInBackground:@"AddNewFriend"
                                                                                               withParameters:@{@"senderUserId": [[PFUser currentUser] objectId], @"recipientUserId": [object objectId]}
                                                                                               block:^(NSString *addFriendString, NSError *error) {
                                                                                               if (!error) {
                                                                                               
                                                                                               } else {
                                                                                               NSLog(error.description);
                                                                                               }
                                                                                               }];
                                                                                               
                                                                                               
                                                                                               NSMutableArray *arrayOfFriends = [[NSMutableArray alloc] initWithArray:[PFUser currentUser][@"Friends"] copyItems:YES];
                                                                                               
                                                                                               [arrayOfFriends addObject:object.objectId];
                                                                                               
                                                                                               [PFUser currentUser][@"Friends"] = arrayOfFriends;
                                                                                               
                                                                                               [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                                                               if (!error) {
                                                                                               
                                                                                               NSString *pushMessage = [NSString stringWithFormat:@"%@ Just Sent You A Friend Request!", [PFUser currentUser][@"username"]];
                                                                                               PFQuery *pushQuery = [PFInstallation query];
                                                                                               [pushQuery whereKey:@"user" equalTo:object];
                                                                                               
                                                                                               NSDictionary *data = @{
                                                                                               @"alert" : pushMessage,
                                                                                               @"badge" : @"Increment",
                                                                                               @"sound" : @"default"
                                                                                               };
                                                                                               PFPush *push = [[PFPush alloc] init];
                                                                                               [push setQuery:pushQuery];
                                                                                               [push setData:data];
                                                                                               [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                                                               if (succeeded && !error) {
                                                                                               
                                                                                               NSLog(@"success");
                                                                                               UIAlertView *alert2 = [[UIAlertView alloc]initWithTitle:@"Success!"
                                                                                               message:[NSString stringWithFormat:@"User %@ has been added to your friends list",username] delegate:nil
                                                                                               cancelButtonTitle:@"OK"
                                                                                               otherButtonTitles:nil, nil];
                                                                                               [alert2 show];
                                                                                               
                                                                                               [Hud removeFromSuperview];
                                                                                               
                                                                                               } else {
                                                                                               NSLog(@"%@",error.description);
                                                                                               
                                                                                               UIAlertView *alert2 = [[UIAlertView alloc]initWithTitle:@"Success!"
                                                                                               message:[NSString stringWithFormat:@"User %@ has been added to your friends list",username] delegate:nil
                                                                                               cancelButtonTitle:@"OK"
                                                                                               otherButtonTitles:nil, nil];
                                                                                               [alert2 show];
                                                                                               
                                                                                               [Hud removeFromSuperview];
                                                                                               
                                                                                               }
                                                                                               }];
                                                                                               
                                                                                               } else {
                                                                                               NSLog(@"%@",error.description);
                                                                                               }
                                                                                               }];
                                                                                               */
                                                                                              
                                                                                          } else {
                                                                                              [Hud removeFromSuperview];
                                                                                          }
                                                                                      }
                                                                                  }];
                                                                                  
                                                                              }
                                                                              
                                                                          } else {
                                                                              
                                                                              alertVC = [[CustomAlert alloc] init];
                                                                              [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"User doesn't exist, Please choose a different one!", nil)];
                                                                              [alertVC.alertView removeFromSuperview];
                                                                              
                                                                              [Hud removeFromSuperview];
                                                                          }
                                                                          
                                                                      }];
                                                                  }
                                                              }
                                                              
                                                              
                                                              
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             //cancel action
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        // A block for configuring the text field prior to displaying the alert
    }];
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}
int callerClickedChallengeBtn = 0;
- (IBAction)clickedChallengeBtn:(UIButton*)sender {
    
    NSLog(@"Clicked Challenge Button");
    if(callerClickedChallengeBtn == 0) {
        pageScroller2.scrollEnabled = NO;
        for(UIView *subview in [pageScroller2 subviews]) {
            subview.userInteractionEnabled = NO;
        }
    } else {
        view1.hidden = TRUE;
        view2.hidden = TRUE;
        view3.hidden = TRUE;
        searchBar.hidden = TRUE;
        pageScroller.scrollEnabled = NO;
        for(UIView *subview in [pageScroller subviews]) {
            subview.userInteractionEnabled = NO;
        }
    }
    
    [self showLoading];
    backFriendRequestview = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [backFriendRequestview setBackgroundColor:[UIColor blackColor]];
    backFriendRequestview.layer.zPosition = 1;
    backFriendRequestview.alpha = 0.95;
    backFriendRequestview.userInteractionEnabled = YES;
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setBackgroundColor:[UIColor clearColor]];
    back.tag = 1;
    [back addTarget:self action:@selector(backTappedFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
    [back setImage:[UIImage imageNamed:@"btn_x"] forState:UIControlStateNormal];
    [backFriendRequestview addSubview:back];
    [UIView animateWithDuration:0.5f // This can be changed.
                     animations:^
     {
         [backFriendRequestview setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
     }
                     completion:^(BOOL finished)
     {
         [backFriendRequestview setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
     }];
    friendRequestScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        friendRequestScroller.frame = CGRectMake(0, 35, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 47, 10, 25, 25)];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    } else {
        friendRequestScroller.frame = CGRectMake(0, 40, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        [back setFrame:CGRectMake(self.view.frame.size.width - 45, 10, 25, 25)];
    }
    friendRequestScroller.bounces = NO;
    //friendRequestScroller.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    //[friendRequestScroller setShowsVerticalScrollIndicator:NO];
    [backFriendRequestview addSubview:friendRequestScroller];
    
    if(callerClickedChallengeBtn == 0) {
        [pageScroller2 addSubview:backFriendRequestview];
        [self setupFriendChallengeGrid: sender.titleLabel.text];
    } else {
        [pageScroller addSubview:backFriendRequestview];
        if(sender.tag == 1001) {
            
            [self setupFriendChallengeGrid: sender.titleLabel.text];
        } else {
            [self setupViewInfoChallengeGrid: sender.titleLabel.text];
        }
    }
    
}
-(void)setupViewInfoChallengeGrid: (NSString*) userObjectId {
    // CHANG
    //    UILabel *example = [[UILabel alloc] init];
    //    example.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
    //    example.frame = CGRectMake(0, 160, self.view.frame.size.width, 50);
    //    example.textColor = [UIColor whiteColor];
    //    example.text = @"This is example for you Chang to add image and stat to this view";
    challengedScroller = [[UIScrollView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    } else {
        challengedScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    
    [backFriendRequestview addSubview:challengedScroller];
    //[backFriendRequestview addSubview:example2];
    //[backFriendRequestview addSubview:example3];
    
    UIImageView *userPicture = [[UIImageView alloc] init];
    UILabel *userName = [[UILabel alloc] init];
    UIImageView *challengedType = [[UIImageView alloc] init];
    UILabel *userScore = [[UILabel alloc] init];
    UILabel *challengeDate = [[UILabel alloc] init];
    UIButton *finishOrCancel = [[UIButton alloc] init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 736)
    {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    } else {
        userPicture.frame = CGRectMake((self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        userName.frame = CGRectMake(0, 50, self.view.frame.size.width/2, 50);
        challengedType.frame = CGRectMake(60, 210, 20, 20);
        userScore.frame = CGRectMake(90, 210, 40, 20);
        challengeDate.frame = CGRectMake(50, 280, self.view.frame.size.width-50, 100);
        finishOrCancel.frame = CGRectMake(100, 370, self.view.frame.size.width-200, 30);
    }
    
    userPicture.layer.cornerRadius = userPicture.frame.size.width / 2;
    userPicture.clipsToBounds = YES;
    userPicture.contentMode = UIViewContentModeScaleAspectFill;
    userName.textColor = [UIColor whiteColor];
    userName.textAlignment = NSTextAlignmentCenter;
    userScore.textColor = [UIColor whiteColor];
    challengeDate.textColor = [UIColor whiteColor];
    userName.text = PFUser.currentUser[@"username"];
    finishOrCancel.backgroundColor = [UIColor orangeColor];
    if([PFUser.currentUser[@"profilePicture"] isEqualToString:@"NoPicture"]){
        userPicture.image = [UIImage imageNamed:@"NoPicture"];
    }else{
        NSString *imageUrl = PFUser.currentUser[@"profilePicture"];
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            
            NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
            if ( data == nil )
                return;
            dispatch_async(dispatch_get_main_queue(), ^{
                userPicture.image = [UIImage imageWithData:data];
                
            });
        });
    }
    [challengedScroller addSubview:userName];
    [challengedScroller addSubview:userPicture];
    
    
    
    UIImageView *friendPicture = [[UIImageView alloc] init];
    UILabel *friendName = [[UILabel alloc] init];
    UIImageView *challengedType2 = [[UIImageView alloc] init];
    UILabel *friendScore = [[UILabel alloc] init];
    if([[UIScreen mainScreen] bounds].size.height == 480)
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 568)
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 667)
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 736)
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    }
    else if([[UIScreen mainScreen] bounds].size.height == 812)
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    } else {
        friendPicture.frame = CGRectMake(self.view.frame.size.width/2+(self.view.frame.size.width/2 - 80)/2, 100, 80, 80);
        friendName.frame = CGRectMake(self.view.frame.size.width/2, 50, self.view.frame.size.width/2, 50);
        challengedType2.frame = CGRectMake(self.view.frame.size.width/2+60, 210, 20, 20);
        friendScore.frame = CGRectMake(self.view.frame.size.width/2+90, 210, 40, 20);
    }
    
    friendPicture.layer.cornerRadius = friendPicture.frame.size.width / 2;
    friendPicture.clipsToBounds = YES;
    friendPicture.contentMode = UIViewContentModeScaleAspectFill;
    friendName.textColor = [UIColor whiteColor];
    friendName.textAlignment = NSTextAlignmentCenter;
    friendScore.textColor = [UIColor whiteColor];
    
    
    
    
    
    //    PFQuery *subquery21 = [PFQuery queryWithClassName:@"FriendRequests"];
    //    [subquery21 whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
    //
    //    PFQuery *subquery22 = [PFQuery queryWithClassName:@"FriendRequests"];
    //    [subquery22 whereKey:@"UserRequesting" equalTo:[PFUser currentUser]];
    //    PFQuery *query2 = [PFQuery orQueryWithSubqueries:@[subquery21,subquery22]];
    //    [query2 whereKey:@"isChallenge" equalTo:[NSNumber numberWithBool:YES]];
    
    
    PFQuery *getFriendObject = [PFUser query];
    [getFriendObject whereKey:@"objectId" equalTo:userObjectId];
    [getFriendObject getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object_friend, NSError * _Nullable error) {
        if(!error){
            friendName.text = object_friend[@"username"];
            if([object_friend[@"profilePicture"] isEqualToString:@"NoPicture"]){
                friendPicture.image = [UIImage imageNamed:@"NoPicture"];
            }else{
                NSString *imageUrl = object_friend[@"profilePicture"];
                dispatch_async(dispatch_get_global_queue(0,0), ^{
                    
                    NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                    if ( data == nil )
                        return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        friendPicture.image = [UIImage imageWithData:data];
                        
                    });
                });
            }
            
            
            
            
            
            
            PFQuery *getTypeQuery1 = [PFQuery queryWithClassName:@"FriendRequests"];
            [getTypeQuery1 whereKey:@"UserRequested" equalTo:[PFUser currentUser]];
            [getTypeQuery1 whereKey:@"UserRequesting" equalTo:object_friend];
            PFQuery *getTypeQuery2 = [PFQuery queryWithClassName:@"FriendRequests"];
            [getTypeQuery2 whereKey:@"UserRequested" equalTo:object_friend];
            [getTypeQuery2 whereKey:@"UserRequesting" equalTo:[PFUser currentUser]];
            PFQuery *getTypeQuery = [PFQuery orQueryWithSubqueries:@[getTypeQuery1, getTypeQuery2]];
            [getTypeQuery whereKey:@"isChallenge" equalTo:[NSNumber numberWithBool:YES]];
            [getTypeQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable friendRequestObject, NSError * _Nullable error) {
                Boolean isWeight;
                NSMutableArray *totalDates;
                NSDate* newDate;
                if(!error){
                    if([friendRequestObject[@"isWeight"] isEqualToNumber:[NSNumber numberWithBool:YES]]){
                        isWeight = true;
                        challengedType.image = [UIImage imageNamed:@"ic_weight_white"];
                        challengedType2.image = [UIImage imageNamed:@"ic_weight_white"];
                        //                        NSLog(@"-------------------------------------------------------------------------------------------------");
                        
                    }else{
                        isWeight = false;
                        challengedType.image = [UIImage imageNamed:@"heart_orange"];
                        challengedType2.image = [UIImage imageNamed:@"heart_orange"];
                        NSLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
                    }
                    if([friendRequestObject[@"Date"] isEqualToString:@"no_date"] || [friendRequestObject[@"Date"] isEqual:nil] ){
                        challengeDate.text = [NSString stringWithFormat:@"Sorry, No Date Record"];
                    }else{
                        //add by chang start
                        NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
                        formatter.dateFormat = @"dd/MM/yyyy";
                        NSDate* beginDate = [formatter dateFromString:friendRequestObject[@"Date"]];
                        NSString* beginDateString = [formatter stringFromDate:beginDate];
                        
                        NSDateComponents* comps = [[NSDateComponents alloc]init];
                        NSNumber* days =  friendRequestObject[@"LengthTime"];
                        comps.day = days.longValue;
                        
                        
                        
                        NSCalendar* calendar = [NSCalendar currentCalendar];
                        
                        newDate = [calendar dateByAddingComponents:comps toDate:beginDate options:0];
                        
                        NSString* interDateString = [formatter stringFromDate:newDate];
                        
                        
                        //test
                        totalDates = [@[beginDateString] mutableCopy];
                        for (int i = 1; i < comps.day; ++i) {
                            NSDateComponents *newComponents = [NSDateComponents new];
                            newComponents.day = i;
                            
                            NSDate *date = [calendar dateByAddingComponents:newComponents toDate:beginDate options:0];
                            NSString* dateString = [formatter stringFromDate:date];
                            [totalDates addObject:dateString];
                        }
                        [totalDates addObject:interDateString];
                        //test
                        
                        challengeDate.text = [NSString stringWithFormat:@"Start: %@     End:%@  ", beginDateString, interDateString];
                    }
                    
                    PFQuery *user_scoreQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
                    [user_scoreQuery whereKey:@"User" equalTo:[PFUser currentUser]];
                    [user_scoreQuery whereKey:@"Date" containedIn:totalDates];
                    [user_scoreQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable score_objects, NSError * _Nullable error) {
                        int userScoreInt = 0;
                        if(!error){
                            for(PFObject* j in score_objects){
                                if(isWeight){
                                    userScoreInt = userScoreInt + [j[@"Exercises"] intValue];
                                }else{
                                    userScoreInt = userScoreInt + [j[@"Hearts"] intValue];
                                }
                                
                            }
                            
                            userScore.text = [NSString stringWithFormat:@"%d", userScoreInt];
                            
                            
                        }
                    }];
                    
                    
                    PFQuery *friend_scoreQuery = [PFQuery queryWithClassName:@"TrackedEvents"];
                    [friend_scoreQuery whereKey:@"User" equalTo:object_friend];
                    [friend_scoreQuery whereKey:@"Date" containedIn:totalDates];
                    [friend_scoreQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable score_objects, NSError * _Nullable error) {
                        int friendScoreInt = 0;
                        if(!error){
                            for(PFObject* j in score_objects){
                                if(isWeight){
                                    friendScoreInt = friendScoreInt + [j[@"Exercises"] intValue];
                                }else{
                                    friendScoreInt = friendScoreInt + [j[@"Hearts"] intValue];
                                }
                                
                            }
                            friendScore.text = [NSString stringWithFormat:@"%d", friendScoreInt];
                            
                        }
                    }];
                    
                    
                    if([newDate timeIntervalSinceNow] < 0.0){
                        [finishOrCancel setTitle:@"FINISH!" forState:(UIControlStateNormal)];
                        friendRequestObject[@"isComplete"] = [NSNumber numberWithBool:YES];
                        [friendRequestObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                            if(succeeded){
                                
                            }else{
                                
                            }
                        }];
                        [finishOrCancel addTarget:self action:@selector(finishChallenge:) forControlEvents:UIControlEventTouchUpInside];
                    }else{
                        [finishOrCancel setTitle:@"CANCEL" forState:(UIControlStateNormal)];
                        [finishOrCancel addTarget:self action:@selector(backTappedFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
                    }
                    
                    
                    
                }
            }];
        }
        
    }];
    
    
    [challengedScroller addSubview:challengedType];
    [challengedScroller addSubview:challengedType2];
    [challengedScroller addSubview:friendName];
    [challengedScroller addSubview:friendPicture];
    [challengedScroller addSubview:challengeDate];
    [challengedScroller addSubview:userScore];
    [challengedScroller addSubview:friendScore];
    [challengedScroller addSubview:finishOrCancel];
    
    
    
    
    
    
    
    
    
    
    
    [Hud removeFromSuperview];
}
-(void)setupFriendChallengeGrid: (NSString*) userObjectId {
    // Create the UI Side Scroll View
    challengeScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    } else {
        challengeScroller.frame = CGRectMake(0, 50, self.view.frame.size.width*3, self.view.frame.size.height); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    challengeScroller.bounces = YES;
    //challangeScroller.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    challengeScroller.delegate = self;
    challengeScroller.scrollEnabled = YES;
    challengeScroller.userInteractionEnabled = YES;
    [challengeScroller setShowsHorizontalScrollIndicator:NO];
    [challengeScroller setShowsVerticalScrollIndicator:NO];
    [backFriendRequestview addSubview:challengeScroller];
    
    UIImageView *friendPicture = [[UIImageView alloc]init];
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.numberOfLines = 10;
    
    descLabel.textAlignment = NSTextAlignmentCenter;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 30, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        descLabel.frame = CGRectMake(0, 130, self.view.frame.size.width, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 50, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        descLabel.frame = CGRectMake(0, 150, self.view.frame.size.width, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 50, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        descLabel.frame = CGRectMake(0, 160, self.view.frame.size.width, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 50, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        descLabel.frame = CGRectMake(0, 160, self.view.frame.size.width, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 50, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        descLabel.frame = CGRectMake(0, 160, self.view.frame.size.width, 50);
    } else {
        friendPicture.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 50, 80, 80);
        descLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        descLabel.frame = CGRectMake(0, 160, self.view.frame.size.width, 50);
    }
    
    friendPicture.layer.cornerRadius = friendPicture.frame.size.width / 2;
    friendPicture.clipsToBounds = YES;
    friendPicture.contentMode = UIViewContentModeScaleAspectFill;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.textColor = [UIColor whiteColor];
    
    PFQuery *getIdQuery = [PFUser query];
    [getIdQuery whereKey:@"objectId" equalTo:userObjectId];
    [getIdQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            if([object[@"profilePicture"] isEqualToString:@"NoPicture"]) {
                //User hasnt set a profile picture
                friendPicture.image = [UIImage imageNamed:@"profile_pic"];
            } else {
                NSString *imageUrl = object[@"profilePicture"];
                dispatch_async(dispatch_get_global_queue(0,0), ^{
                    
                    NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageUrl]]];
                    if ( data == nil )
                        return;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        friendPicture.image = [UIImage imageWithData:data];
                        
                    });
                });
            }
            
            descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Would you like to challenge %@ to a workout challenge?", nil), object[@"username"]];
            [Hud removeFromSuperview];
        }
        else {
            [Hud removeFromSuperview];
        }
    }];
    
    [challengeScroller addSubview:friendPicture];
    [challengeScroller addSubview:descLabel];
    
    UIButton *yesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *noButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesButton setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
        [noButton setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [yesButton setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
        [noButton setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    
    noButton.tag = 1;
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 210, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 210, 130, 40);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
    } else {
        yesButton.frame = CGRectMake(self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
        noButton.frame =  CGRectMake(self.view.frame.size.width/4-65, 230, 130, 40);//Position of the button
    }
    [yesButton
     addTarget:self
     action:@selector(tabYesChallenge:) forControlEvents:UIControlEventTouchUpInside];
    [noButton
     addTarget:self
     action:@selector(backTappedFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [challengeScroller addSubview:yesButton];
    [challengeScroller addSubview:noButton];
    
    //////////////////////////////////////////
    
    UILabel *desc2Label = [[UILabel alloc] init];
    desc2Label.numberOfLines = 10;
    UIButton *weightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *heartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if([language containsString:@"fr"]) {
        [weightButton setBackgroundImage:[UIImage imageNamed:@"btn_weight_french"] forState:UIControlStateNormal];
        [heartButton setBackgroundImage:[UIImage imageNamed:@"btn_hearts_french"] forState:UIControlStateNormal];
    } else {
        [weightButton setBackgroundImage:[UIImage imageNamed:@"btn_weight"] forState:UIControlStateNormal];
        [heartButton setBackgroundImage:[UIImage imageNamed:@"btn_hearts"] forState:UIControlStateNormal];
    }
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 50, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 120, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 120, 110, 100);//Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
    } else {
        desc2Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc2Label.frame = CGRectMake(self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        weightButton.frame = CGRectMake(5*self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
        heartButton.frame = CGRectMake(3*self.view.frame.size.width/2 + self.view.frame.size.width/4-55, 140, 110, 100);//Position of the button
    }
    desc2Label.textColor = [UIColor whiteColor];
    desc2Label.text = NSLocalizedString(@"Please Choose Type of Challenge", nil);
    desc2Label.textAlignment = NSTextAlignmentCenter;
    [weightButton
     addTarget:self
     action:@selector(tabWeightChallenge:) forControlEvents:UIControlEventTouchUpInside];
    [heartButton
     addTarget:self
     action:@selector(tabHeartChallenge:) forControlEvents:UIControlEventTouchUpInside];
    [challengeScroller addSubview:desc2Label];
    [challengeScroller addSubview:weightButton];
    [challengeScroller addSubview:heartButton];
    
    //////////////////////////////////////////////////////
    UILabel *desc3Label = [[UILabel alloc] init];
    desc3Label.numberOfLines = 2;
    desc3Label.textColor = [UIColor whiteColor];
    desc3Label.text = NSLocalizedString(@"Please Choose Duration of Challenge", nil);
    desc3Label.textAlignment = NSTextAlignmentCenter;
    UILabel *dayLabel = [[UILabel alloc] init];
    dayLabel.numberOfLines = 2;
    dayLabel.textColor = [UIColor whiteColor];
    dayLabel.text = NSLocalizedString(@"1 Day", nil);
    dayLabel.textAlignment = NSTextAlignmentLeft;
    UILabel *weekLabel = [[UILabel alloc] init];
    weekLabel.numberOfLines = 2;
    weekLabel.textColor = [UIColor whiteColor];
    weekLabel.text = NSLocalizedString(@"2 Weeks", nil);
    weekLabel.textAlignment = NSTextAlignmentRight;
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if([language containsString:@"fr"]) {
        [confirmButton setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
        [backButton setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [confirmButton setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
        [backButton setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    UISlider *slider = [[UISlider alloc] init];
    [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
    [slider setBackgroundColor:[UIColor whiteColor]];
    slider.minimumValue = 1;
    slider.maximumValue = 14;
    slider.continuous = YES;
    [slider setValue:1 animated:YES];
    challengeDuration = 1;
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 50, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 130, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 120, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 180, 130, 40);//Position of the button
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 180, 130, 40);//Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 150, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 140, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 150, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 140, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 200, 130, 40);
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 200, 130, 40);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 150, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 140, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 150, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 140, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
    } else {
        desc3Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        desc3Label.frame = CGRectMake(2*self.view.frame.size.width, 70, self.view.frame.size.width, 50);
        dayLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        dayLabel.frame = CGRectMake(2*self.view.frame.size.width + 10, 150, self.view.frame.size.width, 50);
        weekLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12];
        weekLabel.frame = CGRectMake(2*self.view.frame.size.width, 150, self.view.frame.size.width - 20, 50);
        slider.frame = CGRectMake(2.125*self.view.frame.size.width, 140, self.view.frame.size.width*0.75, 5.0);
        backButton.frame = CGRectMake(9*self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
        confirmButton.frame = CGRectMake(5*self.view.frame.size.width/2 + self.view.frame.size.width/4-65, 200, 130, 40);//Position of the button
    }
    [backButton
     addTarget:self
     action:@selector(tabBackChallenge:) forControlEvents:UIControlEventTouchUpInside];
    [confirmButton setTitle:userObjectId forState:UIControlStateNormal];
    confirmButton.titleLabel.layer.opacity = 0.0f;
    [confirmButton
     addTarget:self
     action:@selector(tabConfirmChallenge:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [challengeScroller addSubview:dayLabel];
    [challengeScroller addSubview:weekLabel];
    [challengeScroller addSubview:desc3Label];
    [challengeScroller addSubview:slider];
    [challengeScroller addSubview:backButton];
    [challengeScroller addSubview:confirmButton];
}
-(void)sliderAction:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    challengeDuration = (int) slider.value;
}
-(IBAction) tabYesChallenge:(id)sender {
    [self moveChallengeStage:self.view.frame.size.width];
}
-(IBAction) tabBackChallenge:(id)sender {
    [self moveChallengeStage:self.view.frame.size.width];
}
-(IBAction) tabWeightChallenge:(id)sender {
    self.revealViewController.panGestureRecognizer.enabled=NO;
    challengeType = 0;
    [self moveChallengeStage:self.view.frame.size.width*2];
}
-(IBAction) tabHeartChallenge:(id)sender {
    self.revealViewController.panGestureRecognizer.enabled=NO;
    challengeType = 1;
    [self moveChallengeStage:self.view.frame.size.width*2];
}
-(IBAction) tabConfirmChallenge:(UIButton*)sender {
    [self showLoading];
    NSString *userObjectId = sender.titleLabel.text;
    PFQuery *getIdQuery = [PFUser query];
    [getIdQuery whereKey:@"objectId" equalTo:userObjectId];
    [getIdQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            PFObject *friendRequest = [PFObject objectWithClassName:@"FriendRequests"];
            friendRequest[@"UserRequested"] = object;
            friendRequest[@"UserRequesting"] = [PFUser currentUser];
            friendRequest[@"accepted"] = @NO;
            friendRequest[@"isPending"] = @YES;
            friendRequest[@"isChallenge"] = @YES;
            friendRequest[@"isComplete"] = @NO;
            friendRequest[@"isWeight"] = (challengeType == 0) ? @YES: @NO;
            
            friendRequest[@"LengthTime"] = @(challengeDuration);
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"dd/MM/yyyy"];
            
            NSDate *currentDate = [NSDate date];
            friendRequest[@"Date"] = [formatter stringFromDate:currentDate];
            [friendRequest saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    
                    alertVC = [[CustomAlert alloc] init];
                    [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:NSLocalizedString(@"Challenge request sent to user %@", nil),object[@"username"]]];
                    [alertVC.alertView removeFromSuperview];
                    
                    NSString *pushMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ Just Sent You A Challenge Request!", nil), [PFUser currentUser][@"username"]];
                    PFQuery *pushQuery = [PFInstallation query];
                    [pushQuery whereKey:@"user" equalTo:object];
                    
                    NSDictionary *data = @{
                                           @"alert" : pushMessage,
                                           @"badge" : @"Increment",
                                           @"sound" : @"default"
                                           };
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery];
                    [push setData:data];
                    [push sendPushInBackground];
                } else {
                    // There was a problem, check error.description
                }
                self.revealViewController.panGestureRecognizer.enabled=YES;
                [Hud removeFromSuperview];
            }];
            [Hud removeFromSuperview];
        } else {
            [Hud removeFromSuperview];
        }
    }];
    /*
     
     */
    sender.tag = 1;
    [self backTappedFriendRequest:sender];
}

-(void) moveChallengeStage:(int) distance {
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        challengeScroller.contentOffset = CGPointMake(distance, 0);
    } completion:NULL];
}

-(IBAction)tapEditDesc:(id)sender
{
    descTextView.editable = YES;
    [descTextView becomeFirstResponder];
    
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [editDescButton setBackgroundImage:[UIImage imageNamed:@"btn_confirm_french"] forState:UIControlStateNormal];
    } else {
        [editDescButton setBackgroundImage:[UIImage imageNamed:@"btn_edit_submit"] forState:UIControlStateNormal];
    }
    
    [editDescButton addTarget:self action:@selector(updateUserDesc:) forControlEvents:UIControlEventTouchUpInside];
    
    if(!isFindingNearestParkOn) {
        isFindingNearestParkOn = true;
        
        
        /*//Text View
         UITextView *tf = [[UITextView alloc] initWithFrame:CGRectMake(45, 130, 200, 40)];
         tf.textColor = [UIColor colorWithRed:0/256.0 green:84/256.0 blue:129/256.0 alpha:1.0];
         
         tf.font = [UIFont fontWithName:@"Open Sans" size:14];
         tf.backgroundColor=[UIColor lightGrayColor];
         tf.text=@"Hello World";
         
         
         //Save Button
         saveButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
         if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
         {
         saveButton.frame = CGRectMake(50, 550, self.view.frame.size.width-100, 30);//Position of the button
         
         } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
         {
         saveButton.frame = CGRectMake(50, 550, self.view.frame.size.width-100, 30);//Position of the button
         } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
         {
         saveButton.frame = CGRectMake(200, 130, 98, 40);//Position of the button
         } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
         {
         saveButton.frame = CGRectMake(50, 650, self.view.frame.size.width-100, 40);//Position of the button
         }
         saveButton.backgroundColor = [UIColor orangeColor];
         [saveButton addTarget:self action:@selector(updateUserDesc:) forControlEvents:UIControlEventTouchUpInside];
         
         [topView addSubview:saveButton];
         
         [topView addSubview:tf];*/
    }
}

-(IBAction)updateUserDesc:(id)sender {
    PFUser *user = [PFUser currentUser];
    
    //user[@"Description"] = _tf.text;
    user[@"Description"] = descTextView.text;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"Yes it did work!");
            
            [self sendDescSuccess];
            
            [[PFUser currentUser] saveInBackground];
            
            PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
            [query whereKey:@"User" equalTo:[PFUser currentUser]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                if (!error) {
                    
                    if ([userAchie[@"ProfilePerfect"]  isEqual: @NO]) {
                        userAchie[@"ProfilePerfect"] = @YES;
                        userAchie[@"User"] = [PFUser currentUser];
                        [userAchie saveInBackground];
                        
                        [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                        [Flurry logEvent:@"User Unlocked Profile Perfect Achievement" timed:YES];
                        
                        /** deleted to temp stop overlap
                         alertVC = [[CustomAlert alloc] init];
                         [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Profile Perfect' achievement! Well Done!", nil)];
                         [alertVC.alertView removeFromSuperview];
                         **/
                        
                    }
                } else {
                    //
                }
            }];
        }
        [Hud removeFromSuperview];
    }];
    
    descTextView.editable = NO;
    
    [editDescButton setBackgroundImage:[UIImage imageNamed:@"btn_edit"] forState:UIControlStateNormal];
    [editDescButton addTarget:self action:@selector(tapEditDesc:) forControlEvents:UIControlEventTouchUpInside];
    
    
}

-(void)sendDescSuccess {
    [editDescButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [editDescButton addTarget:self action:@selector(tapEditDesc:) forControlEvents:UIControlEventTouchUpInside];
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):NSLocalizedString(@"Your description has been saved!", nil)];
    [alertVC.alertView removeFromSuperview];
    
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
            Hud.labelText = NSLocalizedString(@"Loading", nil);
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

#pragma mark - Keyboard Handling

//Shows the Keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    NSLog(@"WTF------------------------");
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
// Dismiss the keyboard

//- (IBAction)dismissKeyboard:(id)sender
-(void)dismissKeyboard
{
    if(![[PFUser currentUser][@"Description"] isEqualToString:descTextView.text]) {
        [self showLoading];
        [self updateUserDesc:self];
    }
    
    descTextView.editable = NO;
    [descTextView resignFirstResponder];
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

-(void)tapChangeImage{
    
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Change Profile", nil)
                                 message:NSLocalizedString(@"Upload your Profile picture", nil)
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
    
    //Background for photo upload
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
    titleLabel.text = NSLocalizedString(@"Edit Profile", nil);
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
    Hud.labelText = NSLocalizedString(@"Loading", nil);
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
- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results{
    NSLog(@"app invite result: %@", results);
    BOOL complete = [[results valueForKeyPath:@"didComplete"] boolValue];
    if (complete) {
        
    }
}


- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error{
    NSLog(@"app invite error: %@", error.localizedDescription);
}

-(void) viewWillAppear:(BOOL)animated {
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
}

@end
