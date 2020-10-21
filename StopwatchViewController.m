//
//  StopwatchViewController.m
//  Proludic
//
//  Created by Geoff Baker on 18/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "StopwatchViewController.h"
#import "Reachability.h"
#import <Parse/Parse.h>
#import "SWRevealViewController.h"
#import "NavBar.h"
#import "MBProgressHUD.h"
#import "Flurry.h"
#import <HealthKit/HealthKit.h>
#import "CustomAlert.h"

@interface StopwatchViewController ()
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation StopwatchViewController {
    
    NSUserDefaults *defaults;
    
    int iteration;
    int min;
    int sec;
    bool refreshView;
    bool userIsOnOverlay;
    bool libraryPicked;
    bool viewHasFinishedLoading;
    
    UITextField *userTextField;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;
    UIScrollView *challengeScroller;
    NSString *weeklyExerciseId;
    
    UIView *mainContainer;
    UISlider *slider;
    
    CustomAlert *alertVC;
}
extern NSData *parsedImage;
@synthesize timerLabel;
@synthesize stopWatchParseObject;
@synthesize stopwatchTypeOfExercise;
@synthesize imageView;
@synthesize setImageData;


- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    /*
     Observer For Push Notifications
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationRefresh) name:@"PushNotificationRefresh" object:nil];
    
    
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
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    
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
    }
    
    [workaroundImageView addSubview:navigationImage];
    self.navigationItem.titleView=workaroundImageView;
    self.navigationItem.titleView.center = self.view.center;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // Build your regular UIBarButtonItem with Custom View
    UIImage *image = [UIImage imageNamed:@"ic_arrow_back_white_18dp"];
    UIButton *leftBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBarButton.frame = CGRectMake(0, 5, 25, 25);
    [leftBarButton addTarget:self action:@selector(tapBackButton:) forControlEvents:UIControlEventTouchUpInside];
    [leftBarButton setBackgroundImage:image forState:UIControlStateNormal];
    
    // Make BarButton Item
    UIBarButtonItem *navLeftButton = [[UIBarButtonItem alloc] initWithCustomView:leftBarButton];
    self.navigationItem.leftBarButtonItem = navLeftButton;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //Start Button
    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        startBtn.frame = CGRectMake(55, 420, 234, 43);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        startBtn.frame = CGRectMake(55, 500, 234, 43);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        startBtn.frame = CGRectMake(75, 550, 234, 43);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        startBtn.frame = CGRectMake(75, 570, 234, 43);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        startBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        startBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
    } else {
        startBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [startBtn setBackgroundImage:[UIImage imageNamed:@"btn_start_french"] forState:UIControlStateNormal];
    } else {
        [startBtn setBackgroundImage:[UIImage imageNamed:@"btn_start_2"] forState:UIControlStateNormal];
    }
    [startBtn addTarget:self action:@selector(startBtnPushed:) forControlEvents:UIControlEventTouchUpInside];
    startBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    [self.view addSubview:startBtn];
    
    //Exercise Name Label
    UILabel *exerciseLabel = [[UILabel alloc]init];
    exerciseLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        exerciseLabel.frame = CGRectMake(0, 60, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        exerciseLabel.frame = CGRectMake(0, 60, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        exerciseLabel.frame = CGRectMake(0, 70, self.view.frame.size.width, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        exerciseLabel.frame = CGRectMake(0, 80, self.view.frame.size.width, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        exerciseLabel.frame = CGRectMake(0, 120, self.view.frame.size.width, 28);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        exerciseLabel.frame = CGRectMake(0, 120, self.view.frame.size.width, 28);
    } else {
        exerciseLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        exerciseLabel.frame = CGRectMake(0, 120, self.view.frame.size.width, 28);
    }
    exerciseLabel.text = stopWatchParseObject[@"ExerciseName"];
    
    exerciseLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:exerciseLabel];
    
    //Muscle Group Image
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        NSLog(@"Screen too small for Muscle Group Image");
    } else {
        PFFile *imageFile = stopWatchParseObject[@"MuscleGroupImage"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!data) {
                return NSLog(@"%@", error);
            }
            self.imageView.image = [UIImage imageWithData:data];
        }];
        [self.view addSubview:imageView];
    }
    
    //Exercise For Label
    NSString *minExerciseTime = [NSString stringWithFormat:NSLocalizedString(@"Minimum Recommended Time: %d seconds", nil), ([[stopWatchParseObject[stopwatchTypeOfExercise] objectAtIndex:3] intValue]/1000 + [[stopWatchParseObject[stopwatchTypeOfExercise] objectAtIndex:4] intValue]/1000)];
    
    UILabel *exerciseForLabel = [[UILabel alloc]init];
    exerciseForLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        exerciseForLabel.frame = CGRectMake(0, 340, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        exerciseForLabel.frame = CGRectMake(0, 350, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        exerciseForLabel.frame = CGRectMake(0, 375, self.view.frame.size.width, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        exerciseForLabel.frame = CGRectMake(0, 400, self.view.frame.size.width, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        exerciseForLabel.frame = CGRectMake(0, 420, self.view.frame.size.width, 28);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        exerciseForLabel.frame = CGRectMake(0, 440, self.view.frame.size.width, 28);
    } else {
        exerciseForLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        exerciseForLabel.frame = CGRectMake(0, 420, self.view.frame.size.width, 28);
    }
    exerciseForLabel.text = minExerciseTime;
    
    exerciseForLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:exerciseForLabel];
    
    running = NO;
    count = 0;
    timerLabel.text = @"00:00";
    
    static dispatch_once_t onceToken;
    
    dispatch_once (&onceToken, ^{
        
        //WARNING ALERT!
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadSingle:self.view:NSLocalizedString(@"Disclaimer", nil):NSLocalizedString(@"Please do not use these machines if you are pregnant, have muscle or back problems, or have a pre-exisiting medical condition. Please consult your Doctor first if you wish to use them.", nil)];
        [alertVC.alertView removeFromSuperview];
        
    });
    
    PFQuery *query = [PFQuery queryWithClassName:@"Extras"];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!object) {
            NSLog(@"The getFirstObject request failed.");
            weeklyExerciseId = nil;
        } else {
            // The find succeeded.
            NSLog(@"Successfully retrieved the object.");
            weeklyExerciseId = [object[@"ExerciseWeekly"] objectId];
        }
    }];
    
    NSString *weightTitle = [stopWatchParseObject[stopwatchTypeOfExercise] objectAtIndex:2];
    if([weightTitle containsString:@"0"]) {
        NSLog(@"Contains 0");
    } else {
        //SLIDER
        mainContainer = [[UIView alloc] init];
        mainContainer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        mainContainer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [self.view addSubview:mainContainer];
        
        UIView *sliderView = [[UIView alloc] init];
        sliderView.frame = CGRectMake(40, 140, self.view.frame.size.width - 80, 290);
        sliderView.backgroundColor = [UIColor colorWithRed:0.14 green:0.14 blue:0.14 alpha:1.0];
        [mainContainer addSubview:sliderView];
        
        NSArray *split = [weightTitle componentsSeparatedByString:@"-"];
        
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, 30, sliderView.frame.size.width - 40, 20);
        label.text = NSLocalizedString(@"Set Weight", nil);
        NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
        if([language containsString:@"fr"]) {
            label.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        } else {
            label.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        }
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        [sliderView addSubview:label];
        
        UILabel *desc = [[UILabel alloc] init];
        desc.frame = CGRectMake(30, 160, sliderView.frame.size.width - 60, 60);
        desc.text = NSLocalizedString(@"Use the slider to set the value of weight you've set on the machine!", nil);
        if([language containsString:@"fr"]) {
            desc.font = [UIFont fontWithName:@"Open Sans" size:10];
        } else {
            desc.font = [UIFont fontWithName:@"Open Sans" size:12];
        }
        desc.textColor = [UIColor whiteColor];
        desc.textAlignment = NSTextAlignmentCenter;
        desc.numberOfLines = 0;
        [sliderView addSubview:desc];
        
        UILabel *firstValue = [[UILabel alloc] init];
        firstValue.frame = CGRectMake(20, 130, 40, 20);
        firstValue.text = split[0];
        firstValue.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        firstValue.textColor = [UIColor whiteColor];
        firstValue.textAlignment = NSTextAlignmentCenter;
        [sliderView addSubview:firstValue];
        
        UILabel *secondValue = [[UILabel alloc] init];
        secondValue.frame = CGRectMake(sliderView.frame.size.width - 60, 130, 40, 20);
        secondValue.text = split[1];
        secondValue.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        secondValue.textColor = [UIColor whiteColor];
        secondValue.textAlignment = NSTextAlignmentCenter;
        [sliderView addSubview:secondValue];
        
        slider = [[UISlider alloc] init];
        slider.frame = CGRectMake(20, 90, sliderView.frame.size.width - 40, 20);
        [slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
        [slider setBackgroundColor:[UIColor clearColor]];
        slider.minimumValue = 1;
        slider.maximumValue = 4;
        slider.continuous = YES;
        [slider setValue:1 animated:YES];
        [sliderView addSubview:slider];
        
        UIButton *setBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        setBtn.frame = CGRectMake(35, sliderView.frame.size.height - 50, sliderView.frame.size.width - 70, 35);
        if([language containsString:@"fr"]) {
            [setBtn setBackgroundImage:[UIImage imageNamed:@"btn_setvalue_french"] forState:UIControlStateNormal];
        } else {
            [setBtn setBackgroundImage:[UIImage imageNamed:@"btn_setvalue"] forState:UIControlStateNormal];
        }
        [setBtn addTarget:self action:@selector(submitWeight) forControlEvents:UIControlEventTouchUpInside];
        setBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        [sliderView addSubview:setBtn];
        
    }
    
    
}

-(void)submitWeight {
    [UIView animateWithDuration:0.8f animations:^{
        mainContainer.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    }];
    
}

-(void)sliderAction:(UISlider *)sender {
    // round the slider position to the nearest index of the numbers array
    NSUInteger index = (NSUInteger)(slider.value + 0.5);
    [slider setValue:index animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)startBtnPushed:(id)sender {
    NSLog(@"%@", [stopWatchParseObject objectId]);
    
    [Flurry logEvent:@"User Started An Exercise" timed:YES];
    
    if (running == NO) {
        running = YES;
        
        if (exerciseTimer == nil) {
            exerciseTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
            
            [_startBtn removeFromSuperview];
            //Tap When Done Button
            UIButton *tapWhenDoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
            {
                tapWhenDoneBtn.frame = CGRectMake(55, 420, 234, 43);//Position of the button
                
            } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
            {
                tapWhenDoneBtn.frame = CGRectMake(55, 500, 234, 43);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
            {
                tapWhenDoneBtn.frame = CGRectMake(75, 550, 234, 43);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
            {
                tapWhenDoneBtn.frame = CGRectMake(75, 570, 234, 43);//Position of the button
            } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
            {
                tapWhenDoneBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
            }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
            {
                tapWhenDoneBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
            } else {
                tapWhenDoneBtn.frame = CGRectMake(75, 600, 234, 43);//Position of the button
            }
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            if([language containsString:@"fr"]) {
                [tapWhenDoneBtn setBackgroundImage:[UIImage imageNamed:@"btn_endexercise_french"] forState:UIControlStateNormal];
            } else {
                [tapWhenDoneBtn setBackgroundImage:[UIImage imageNamed:@"btn_done"] forState:UIControlStateNormal];
            }
            [tapWhenDoneBtn addTarget:self action:@selector(tapWhenDone:) forControlEvents:UIControlEventTouchUpInside];
            tapWhenDoneBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
            [self.view addSubview:tapWhenDoneBtn];
        }
        
    } else {
        
        running = NO;
        [exerciseTimer invalidate];
        exerciseTimer = nil;
        [_startBtn setTitle:NSLocalizedString(@"START", nil) forState:UIControlStateNormal];
        
    }
}

- (IBAction)tapWhenDone:(id)sender {
    int totalHearts = 0;
    running = NO;
    
    //Complete Label
    UILabel *completeLabel = [[UILabel alloc]init];
    completeLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        completeLabel.frame = CGRectMake(16, 380, self.view.frame.size.width / 2, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        completeLabel.frame = CGRectMake(16, 380, self.view.frame.size.width / 2, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        completeLabel.frame = CGRectMake(20, 400, self.view.frame.size.width / 2, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        completeLabel.frame = CGRectMake(26, 440, self.view.frame.size.width / 2, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        completeLabel.frame = CGRectMake(26, 460, self.view.frame.size.width / 2, 30);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        completeLabel.frame = CGRectMake(26, 480, self.view.frame.size.width / 2, 30);
    } else {
        completeLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        completeLabel.frame = CGRectMake(26, 460, self.view.frame.size.width / 2, 30);
    }
    completeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Completed Task", nil)];
    
    completeLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:completeLabel];
    
    //Complete Label
    UILabel *heartsLabel = [[UILabel alloc]init];
    heartsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLabel.frame = CGRectMake(0, 380, self.view.frame.size.width - 16, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        heartsLabel.frame = CGRectMake(0, 380, self.view.frame.size.width - 16, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        heartsLabel.frame = CGRectMake(0, 400, self.view.frame.size.width - 20, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        heartsLabel.frame = CGRectMake(0, 440, self.view.frame.size.width - 25, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        heartsLabel.frame = CGRectMake(0, 440, self.view.frame.size.width - 25, 28);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        heartsLabel.frame = CGRectMake(0, 480, self.view.frame.size.width - 25, 28);
    } else {
        heartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        heartsLabel.frame = CGRectMake(0, 440, self.view.frame.size.width - 25, 28);
    }
    
    heartsLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:heartsLabel];
    
    //Complete Label
    UILabel *personalBestLabel = [[UILabel alloc]init];
    personalBestLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        personalBestLabel.frame = CGRectMake(0, 410, self.view.frame.size.width / 2, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:12];
        personalBestLabel.frame = CGRectMake(0, 410, self.view.frame.size.width / 2, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
        personalBestLabel.frame = CGRectMake(20, 430, self.view.frame.size.width / 2, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        personalBestLabel.frame = CGRectMake(26, 470, self.view.frame.size.width / 2, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        personalBestLabel.frame = CGRectMake(26, 490, self.view.frame.size.width / 2, 28);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        personalBestLabel.frame = CGRectMake(26, 510, self.view.frame.size.width / 2, 28);
    } else {
        personalBestLabel.font = [UIFont fontWithName:@"Open Sans" size:16];
        personalBestLabel.frame = CGRectMake(26, 490, self.view.frame.size.width / 2, 28);
    }
    personalBestLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Weekly Exercise", nil)];
    
    personalBestLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:personalBestLabel];
    
    //Personal Best Label
    UILabel *personalBestHeartsLabel = [[UILabel alloc]init];
    personalBestHeartsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        personalBestHeartsLabel.frame = CGRectMake(0, 410, self.view.frame.size.width - 16, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        personalBestHeartsLabel.frame = CGRectMake(0, 410, self.view.frame.size.width - 16, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        personalBestHeartsLabel.frame = CGRectMake(0, 430, self.view.frame.size.width - 20, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        personalBestHeartsLabel.frame = CGRectMake(0, 470, self.view.frame.size.width - 24, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        personalBestHeartsLabel.frame = CGRectMake(0, 470, self.view.frame.size.width - 24, 30);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone X size
    {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        personalBestHeartsLabel.frame = CGRectMake(0, 510, self.view.frame.size.width - 24, 30);
    } else {
        personalBestHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        personalBestHeartsLabel.frame = CGRectMake(0, 470, self.view.frame.size.width - 24, 30);
    }
    
    personalBestHeartsLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:personalBestHeartsLabel];
    if((min*60+sec) >= [[stopWatchParseObject[stopwatchTypeOfExercise]  objectAtIndex:3] intValue]/1000 * 2) {
        
        [self updateLocalDatabase];
        [exerciseTimer invalidate];
        [_tapWhenDoneBtn removeFromSuperview];
        
        //Tap When Done Button
        UIButton *finishExerciseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            finishExerciseBtn.frame = CGRectMake(55, 420, 234, 43);//Position of the button
            
        } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
        {
            finishExerciseBtn.frame = CGRectMake(55, 500, 234, 43);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
        {
            finishExerciseBtn.frame = CGRectMake(75, 550, 234, 43);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            finishExerciseBtn.frame = CGRectMake(75, 570, 234, 43);//Position of the button
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            finishExerciseBtn.frame = CGRectMake(75, 570, 234, 43);//Position of the button
        } else {
            finishExerciseBtn.frame = CGRectMake(75, 570, 234, 43);//Position of the button
        }
        NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
        if([language containsString:@"fr"]) {
            [finishExerciseBtn setBackgroundImage:[UIImage imageNamed:@"btn_taptofinish_french"] forState:UIControlStateNormal];
        } else {
            [finishExerciseBtn setBackgroundImage:[UIImage imageNamed:@"btn_finish2"] forState:UIControlStateNormal];
        }
        [finishExerciseBtn addTarget:self action:@selector(tapFinishExercise:) forControlEvents:UIControlEventTouchUpInside];
        finishExerciseBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        [self.view addSubview:finishExerciseBtn];
        
        heartsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"200 Hearts", nil)];
        totalHearts += 300;
        
        
        if(weeklyExerciseId != nil && [[stopWatchParseObject objectId] isEqualToString:weeklyExerciseId]) {
            personalBestHeartsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"200 Hearts", nil)];
            totalHearts += 200;
            
            PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
            [query whereKey:@"User" equalTo:[PFUser currentUser]];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                if (!error) {
                    
                    if ([userAchie[@"WeeklyWorker"]  isEqual: @NO]) {
                        userAchie[@"WeeklyWorker"] = @YES;
                        userAchie[@"User"] = [PFUser currentUser];
                        [userAchie saveInBackground];
                        
                        [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                        [Flurry logEvent:@"User Unlocked Weekly Worker Achievement" timed:YES];
                        
                        alertVC = [[CustomAlert alloc] init];
                        [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Weekly Worker' achievement! Well Done!", nil)];
                        [alertVC.alertView removeFromSuperview];
                        
                    }
                } else {
                    //
                }
            }];
            
        } else {
            personalBestHeartsLabel.text = [NSString stringWithFormat:NSLocalizedString(@"0 Hearts", nil)];
            
        }
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
                     int tmp = [object[@"Exercises"] intValue] + 1;
                     object[@"Exercises"] = @(tmp);
                     tmp = [object[@"Hearts"] intValue] + totalHearts;
                     object[@"Hearts"] = @(tmp);
                     object[@"Park"] = [PFUser currentUser][@"HomePark"];
                     NSString *objectIdToAdd = [stopWatchParseObject objectId];
                     [object addObject:objectIdToAdd forKey:@"ExercisesUsed"];
                     [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                         if (succeeded) {
                             
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
                                 }
                             } else {
                                 NSLog(@"Can not use health kit");
                             }
                             
                             
                             
                             [Flurry logEvent:@"User has Completed an Exercise" timed:YES];
                         } else {
                             // There was a problem, check error.description
                         }
                     }];
                 }
             } else {
                 
                 if(error.code == 101) {// Object not found
                     PFObject *trackedEvents = [PFObject objectWithClassName:@"TrackedEvents"];
                     [trackedEvents setObject:[PFUser currentUser] forKey:@"User"];
                     trackedEvents[@"Hearts"] = @(totalHearts);
                     trackedEvents[@"Date"] = dateString;
                     trackedEvents[@"Exercises"] = @(1);
                     trackedEvents[@"Park"] = [PFUser currentUser][@"HomePark"];
                     NSDate *date = [NSDate date];
                     NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                     [formatter setDateFormat:@"H"];
                     NSString *timeString = [formatter stringFromDate:date];
                     trackedEvents[@"Time"] = timeString;
                     NSString *objectIdToAdd = [stopWatchParseObject objectId];
                     [trackedEvents addObject:objectIdToAdd forKey:@"ExercisesUsed"];
                     [trackedEvents saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                         if (succeeded) {
                             [Flurry logEvent:@"User has Completed an Exercise" timed:YES];
                         } else {
                             // There was a problem, check error.description
                         }
                     }];
                     
                     NSLog(@"%@", error.description);
                     NSLog(@"%ld -----",(long)error.code);
                 }
                 
             }
         }];
    } else {
        running = NO;
        
        alertVC = [[CustomAlert alloc] init];
        [alertVC loadingVar:self:NSLocalizedString(@"Exercise Not Finished", nil):NSLocalizedString(@"Are you sure you want to finish the exercise? You won't be rewarded for your progress", nil):@"STRANG"];
        [alertVC.alertView removeFromSuperview];
        
    }
    
    if(totalHearts > 0){
        [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + totalHearts);
        
        [PFUser currentUser][@"TotalExercises"] = @([[PFUser currentUser][@"TotalExercises"] intValue] + 1);
        [[PFUser currentUser] saveInBackground];
        
        PFQuery *parkQuery = [PFQuery queryWithClassName:@"Locations"];
        [parkQuery whereKey:@"objectId" equalTo:[PFUser currentUser][@"HomePark"]];
        [parkQuery getFirstObjectInBackgroundWithBlock:^(PFObject *park, NSError *error) {
            if(!error) {
                park[@"TotalParkHearts"] = @([park[@"TotalParkHearts"] intValue] + totalHearts);
            } else {
                NSLog(@"%@", error.description);
            }
        }];
        
        if([stopWatchParseObject[@"Resistance"] isEqual:@"N/A"]) {
            [PFUser currentUser][@"TotalNonWeightExercises"] = @([[PFUser currentUser][@"TotalNonWeightExercises"] intValue] + 1);
            [[PFUser currentUser] saveInBackground];
            
        } else {
            int reps = [[stopWatchParseObject[stopwatchTypeOfExercise] objectAtIndex:0] intValue];
            int sets = [[stopWatchParseObject[stopwatchTypeOfExercise] objectAtIndex:1] intValue];
            int weight = sets * reps * 6;
            NSLog(@"Total Weight to Add: %d", weight);
            
            [PFUser currentUser][@"TotalWeightExercises"] = @([[PFUser currentUser][@"TotalWeightExercises"] intValue] + 1);
            [[PFUser currentUser] saveInBackground];
            
            [PFUser currentUser][@"TotalWeight"] = @([[PFUser currentUser][@"TotalWeight"] intValue] + weight);
            [[PFUser currentUser] saveInBackground];
            
            
            //Weight Achievement Check
            PFQuery *userQuery = [PFUser query];
            [userQuery whereKey:@"objectId" equalTo: [PFUser currentUser].objectId];
            [userQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userObj, NSError *error) {
                if (!error) {
                    if ([userObj[@"TotalWeight"] intValue] > 815) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"KodiakBear"]  isEqual: @NO]) {
                                    userAchie[@"KodiakBear"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 250);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Kodiak Bear Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Kodiak Bear' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 1050) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"Crocodile"]  isEqual: @NO]) {
                                    userAchie[@"Crocodile"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 300);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Crocodile Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Crocodile' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 1250) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"AsianGuar"]  isEqual: @NO]) {
                                    userAchie[@"AsianGuar"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 350);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Guar Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Asian Guar' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 1600) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"Giraffe"]  isEqual: @NO]) {
                                    userAchie[@"Giraffe"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 400);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Giraffe Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Giraffe' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 3400) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"Hippopotamus"]  isEqual: @NO]) {
                                    userAchie[@"Hippopotamus"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 450);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Hippo Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Hippopotamus' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 3900) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"WhiteRhinoceros"]  isEqual: @NO]) {
                                    userAchie[@"WhiteRhinoceros"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 500);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked White Rhino Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'White Rhino' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    if ([userObj[@"TotalWeight"] intValue] > 5000) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"AsianElephant"]  isEqual: @NO]) {
                                    userAchie[@"AsianElephant"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 550);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Asian Elephant Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Asian Elephant' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 6350) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"AfricanElephant"]  isEqual: @NO]) {
                                    userAchie[@"AfricanElephant"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 600);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked African Elephant Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'African Elephant' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                    
                    if ([userObj[@"TotalWeight"] intValue] > 18150) {
                        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
                        [query whereKey:@"User" equalTo:[PFUser currentUser]];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
                            if (!error) {
                                
                                if ([userAchie[@"WhaleShark"]  isEqual: @NO]) {
                                    userAchie[@"WhaleShark"] = @YES;
                                    userAchie[@"User"] = [PFUser currentUser];
                                    [userAchie saveInBackground];
                                    
                                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 650);
                                    [[PFUser currentUser] saveInBackground];
                                    [Flurry logEvent:@"User Unlocked Whale Shark Achievement" timed:YES];
                                    
                                    alertVC = [[CustomAlert alloc] init];
                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Whale Shark' achievement! Well Done!", nil)];
                                    [alertVC.alertView removeFromSuperview];
                                    
                                }
                                
                            } else {
                                //
                            }
                        }];
                    } else {
                        NSLog(@"Not Enough Weight Lifted");
                    }
                } else {
                    NSLog(@"ERROR: %@", error.description);
                }
            }];
        }
        
        PFQuery *query = [PFQuery queryWithClassName:@"UserAchievements"];
        [query whereKey:@"User" equalTo:[PFUser currentUser]];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject * userAchie, NSError *error)        {
            if (!error) {
                
                if ([userAchie[@"WorkingOut"]  isEqual: @NO]) {
                    userAchie[@"WorkingOut"] = @YES;
                    userAchie[@"User"] = [PFUser currentUser];
                    [userAchie saveInBackground];
                    
                    [PFUser currentUser][@"Hearts"] = @([[PFUser currentUser][@"Hearts"] intValue] + 200);
                    [[PFUser currentUser] saveInBackground];
                    [Flurry logEvent:@"User Unlocked Working Out Achievement" timed:YES];
                    
                    alertVC = [[CustomAlert alloc] init];
                    [alertVC loadSingle:self.view:NSLocalizedString(@"Achievement Unlocked", nil):NSLocalizedString(@"You've unlocked 'Working Out' achievement! Well Done!", nil)];
                    [alertVC.alertView removeFromSuperview];
                    
                }
                
            } else {
                //
            }
        }];
    }
    
    
    //Total Hearts Label
    UILabel *totalHeartsLabel = [[UILabel alloc]init];
    totalHeartsLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        totalHeartsLabel.frame = CGRectMake(0, 440, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        totalHeartsLabel.frame = CGRectMake(0, 440, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        totalHeartsLabel.frame = CGRectMake(0, 460, self.view.frame.size.width, 26);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        totalHeartsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        totalHeartsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 30);
    } else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        totalHeartsLabel.frame = CGRectMake(0, 510, self.view.frame.size.width, 30);
    }else {
        totalHeartsLabel.font = [UIFont fontWithName:@"Ethnocentric" size:20];
        totalHeartsLabel.frame = CGRectMake(0, 500, self.view.frame.size.width, 30);
    }
    totalHeartsLabel.text = [NSString stringWithFormat:@"%d", totalHearts];
    totalHeartsLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:totalHeartsLabel];
    
    //Total Hearts Image
    UIImageView *lrgHeartImage = [[UIImageView alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        lrgHeartImage.frame = CGRectMake(0, 400, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        lrgHeartImage.frame = CGRectMake(0, 400, self.view.frame.size.width, 24);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        lrgHeartImage.frame = CGRectMake(0, 420, self.view.frame.size.width, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        lrgHeartImage.frame = CGRectMake(0, 460, self.view.frame.size.width, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        lrgHeartImage.frame = CGRectMake(0, 460, self.view.frame.size.width, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        lrgHeartImage.frame = CGRectMake(0, 480, self.view.frame.size.width, 35);
    }else {
        lrgHeartImage.frame = CGRectMake(0, 460, self.view.frame.size.width, 35);
    }
    lrgHeartImage.image = [UIImage imageNamed:@"Heart"];
    lrgHeartImage.contentMode = UIViewContentModeScaleAspectFit;
    lrgHeartImage.clipsToBounds = YES;
    
    [self.view addSubview:lrgHeartImage];
    
}

-(void)alertResponse:(NSString*)result:(NSString*)varText {
    NSString *tmp = [NSString stringWithFormat:@"Bool Result %@", result];
    
    if([result isEqualToString:@"True"]) {
        
        /*alertVC = [[CustomAlert alloc] init];
         [alertVC loadSingle:self.view:NSLocalizedString(@"Exercise Incomplete", nil):NSLocalizedString(@"You have not finished the exercise! Try Again!", nil)];
         [alertVC.alertView removeFromSuperview];
         */
        [exerciseTimer invalidate];
        [_tapWhenDoneBtn removeFromSuperview];
        
        [self.navigationController popViewControllerAnimated:YES];
        
    } else {
        
        running = YES;
        [exerciseTimer fire];
    }
}

- (IBAction)tapFinishExercise:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateTimer {
    
    if(running) {
        count++;
    } else {
        
    }
    min = floor(count/100/60);
    sec = floor(count/100);
    
    if (sec >= 60) {
        sec = sec % 60;
    }
    timerLabel.text = [NSString stringWithFormat:@"%02d:%02d",min,sec];
    
}

-(void) updateLocalDatabase {
    BOOL success = NO;
    
    // Don't uncomment these line, otherwise the database will be wiped out
    /*success = [[DBManager getSharedInstance]deleteData];
     if(success) {
     NSLog(@"----------------Table rows deleted");
     } else {
     NSLog(@"----------------Failed to delete table rows");
     }
     success = NO;*/
    
    
    NSString *alertString = @"Data Insertion Failed";
    NSString *alertString2 = @"Data Update Failed";
    NSArray *data = [[DBManager getSharedInstance]findNumRepeat:[stopWatchParseObject objectId]];
    NSLog(@" @%d @%d", [data count], [[data objectAtIndex:0] intValue]);
    if(data == nil) {
        success = [[DBManager getSharedInstance]saveData:
                   [stopWatchParseObject objectId]: stopWatchParseObject[@"ExerciseName"] : 1];
        if (success == NO) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:
                                  alertString message:nil
                                                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    else {
        int numRepeat = [[data objectAtIndex:0] intValue];
        numRepeat++;
        success = [[DBManager getSharedInstance]updateData:
                   [stopWatchParseObject objectId]: numRepeat];
        if (success == NO) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:
                                  alertString2 message:nil
                                                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
}

#pragma mark - Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
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

-(IBAction)tapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState == UIApplicationStateActive) {
        // update the tab bar item
    }
    else {
        NSLog(@"Entered background mode");
    }
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

@end
