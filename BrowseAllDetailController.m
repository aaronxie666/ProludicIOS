//
//  BrowseAllDetailController.m
//  Proludic
//
//  Created by Geoff Baker on 03/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"
#import "BrowseAllDetailController.h"
#import "BrowseAllTableController.h"
#import "StopwatchViewController.h"

@interface BrowseAllDetailController ()

@end

@implementation BrowseAllDetailController

NSMutableArray *videoURL;
NSArray *results;
UILabel *setAltString;
NSString *URLFallback;

extern NSMutableArray *browseAllArray;
extern NSString *setsString;
extern NSString *repsString;
extern NSString *restTimeString;
extern NSString *avgTimeString;
extern NSString *weightString;
extern NSString *altLabelString;
extern NSData *parsedImage;
extern UIScrollView *sideScroller;

@synthesize exerciseObject;
@synthesize imageView;
@synthesize URLString;
@synthesize exerciseLabelString;
@synthesize setRepsLabelString;
@synthesize setSetsLabelString;
@synthesize setTimeLabelString;
@synthesize setAltLabelString;
@synthesize weightLabelString;
@synthesize restTimeLabelString;
@synthesize descLabelString;
@synthesize setImageData;
@synthesize typeOfExercise;
@synthesize x;
//SOC
@synthesize socExercise;
@synthesize socChallenge;
@synthesize socLesson;

- (void)viewDidLoad {
    
    sideScroller.clipsToBounds = YES;
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
    } else {
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
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) {
        UIScrollView *pageScroller1 = [[UIScrollView alloc] init];
        
        pageScroller1.frame = CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height+2300);
        pageScroller1.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 2500);
        pageScroller1.bounces = NO;
        [pageScroller1 setShowsVerticalScrollIndicator:NO];
        [self.view addSubview:pageScroller1];
    }
    UILabel *descLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        descLabel.frame = CGRectMake(10, 380, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        descLabel.frame = CGRectMake(10, 380, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        descLabel.frame = CGRectMake(10, 440, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        descLabel.frame = CGRectMake(10, 480, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        descLabel.frame = CGRectMake(10, 520, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        descLabel.frame = CGRectMake(10, 520, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    } else {
        descLabel.frame = CGRectMake(10, 520, self.view.frame.size.width - 20, 100);
        descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    }
    descLabel.numberOfLines = 5;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.text = descLabelString;
    [self.view addSubview:descLabel];
    
    UILabel *exerciseLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        exerciseLabel.frame = CGRectMake(10, 40, self.view.frame.size.width - 20 / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        exerciseLabel.frame = CGRectMake(10, 40, self.view.frame.size.width - 20 / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        exerciseLabel.frame = CGRectMake(10, 50, self.view.frame.size.width - 20 / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        exerciseLabel.frame = CGRectMake(10, 60, self.view.frame.size.width - 20 / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        exerciseLabel.frame = CGRectMake(10, 100, self.view.frame.size.width - 20 / 2, 50);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){
        exerciseLabel.frame = CGRectMake(10, 100, self.view.frame.size.width - 20 / 2, 50);
    }
    else {
        exerciseLabel.frame = CGRectMake(10, 100, self.view.frame.size.width - 20 / 2, 50);
    }
    exerciseLabel.font = [UIFont fontWithName:@"ethnocentric" size:22];
    exerciseLabel.numberOfLines = 2;
    exerciseLabel.textAlignment = NSTextAlignmentCenter;
    exerciseLabel.text = exerciseLabelString;
    [self.view addSubview:exerciseLabel];
    
    NSString *x = [@" X " init];
    NSString *combined = [NSString stringWithFormat: @"%@%@%@", setSetsLabelString, x, setRepsLabelString];
    NSLog(@"WOOL: %@", combined);
    
    UILabel *setSetsLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        setSetsLabel.frame = CGRectMake(0, 90, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        setSetsLabel.frame = CGRectMake(0, 90, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        setSetsLabel.frame = CGRectMake(0, 100, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        setSetsLabel.frame = CGRectMake(0, 110, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        setSetsLabel.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        setSetsLabel.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
    }
    else {
        setSetsLabel.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
    }
    setSetsLabel.textAlignment = NSTextAlignmentCenter;
    setSetsLabel.font = [UIFont fontWithName:@"ethnocentric" size:18];
    setSetsLabel.numberOfLines = 0;
    setSetsLabel.text = combined;
    [self.view addSubview:setSetsLabel];
    
    UILabel *setTimeLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 90, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 90, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 100, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 110, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
    }
    else {
        setTimeLabel.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
    }
    setTimeLabel.textAlignment = NSTextAlignmentCenter;
    setTimeLabel.font = [UIFont fontWithName:@"ethnocentric" size:18];
    setTimeLabel.numberOfLines = 0;
    setTimeLabel.text = restTimeLabelString;
    [self.view addSubview:setTimeLabel];
    
    UILabel *weightLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 130, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 130, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 140, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 190, self.view.frame.size.width / 2, 50);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){  //iPhone XR/Max size
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 190, self.view.frame.size.width / 2, 50);
    }
    else {
        weightLabel.frame = CGRectMake(self.view.frame.size.width / 2, 190, self.view.frame.size.width / 2, 50);
    }
    weightLabel.textAlignment = NSTextAlignmentCenter;
    weightLabel.font = [UIFont fontWithName:@"ethnocentric" size:18];
    weightLabel.numberOfLines = 0;
    weightLabel.text = weightLabelString;
    [self.view addSubview:weightLabel];
    
    UILabel *restTimeLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        restTimeLabel.frame = CGRectMake(0, 130, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        restTimeLabel.frame = CGRectMake(0, 130, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        restTimeLabel.frame = CGRectMake(0, 140, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        restTimeLabel.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        restTimeLabel.frame = CGRectMake(0, 190, self.view.frame.size.width / 2, 50);
    }else if([[UIScreen mainScreen] bounds].size.height == 896){
        restTimeLabel.frame = CGRectMake(0, 190, self.view.frame.size.width / 2, 50);
    }
    else {
        restTimeLabel.frame = CGRectMake(0, 190, self.view.frame.size.width / 2, 50);
    }
    restTimeLabel.textAlignment = NSTextAlignmentCenter;
    restTimeLabel.font = [UIFont fontWithName:@"ethnocentric" size:18];
    restTimeLabel.numberOfLines = 0;
    restTimeLabel.text = setTimeLabelString;
    [self.view addSubview:restTimeLabel];
    
    //Static Labels
    UILabel *setsAndReps = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        setsAndReps.frame = CGRectMake(0, 110, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        setsAndReps.frame = CGRectMake(0, 110, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        setsAndReps.frame = CGRectMake(0, 120, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        setsAndReps.frame = CGRectMake(0, 130, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        setsAndReps.frame = CGRectMake(0, 170, self.view.frame.size.width / 2, 50);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        setsAndReps.frame = CGRectMake(0, 170, self.view.frame.size.width / 2, 50);
    } else {
        setsAndReps.frame = CGRectMake(0, 170, self.view.frame.size.width / 2, 50);
    }
    setsAndReps.textAlignment = NSTextAlignmentCenter;
    setsAndReps.font = [UIFont fontWithName:@"OpenSans" size:12];
    setsAndReps.numberOfLines = 0;
    setsAndReps.text = NSLocalizedString(@"SETS X REPS", nil);
    [self.view addSubview:setsAndReps];
    
    UILabel *restTime = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 110, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 110, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 120, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 130, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 170, self.view.frame.size.width / 2, 50);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 170, self.view.frame.size.width / 2, 50);
    } else {
        restTime.frame = CGRectMake(self.view.frame.size.width / 2, 170, self.view.frame.size.width / 2, 50);
    }
    restTime.textAlignment = NSTextAlignmentCenter;
    restTime.font = [UIFont fontWithName:@"OpenSans" size:12];
    restTime.numberOfLines = 0;
    restTime.text = NSLocalizedString(@"REST TIME", nil);
    [self.view addSubview:restTime];
    
    UILabel *staticWeight = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 150, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 160, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 170, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 210, self.view.frame.size.width / 2, 50);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 210, self.view.frame.size.width / 2, 50);
    } else {
        staticWeight.frame = CGRectMake(self.view.frame.size.width / 2, 210, self.view.frame.size.width / 2, 50);
    }
    staticWeight.textAlignment = NSTextAlignmentCenter;
    staticWeight.font = [UIFont fontWithName:@"OpenSans" size:12];
    staticWeight.numberOfLines = 0;
    staticWeight.text = NSLocalizedString(@"WEIGHT", nil);
    [self.view addSubview:staticWeight];
    
    UILabel *staticAvgRestTime = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        staticAvgRestTime.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        staticAvgRestTime.frame = CGRectMake(0, 150, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        staticAvgRestTime.frame = CGRectMake(0, 160, self.view.frame.size.width / 2, 50);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        staticAvgRestTime.frame = CGRectMake(0, 170, self.view.frame.size.width / 2, 50);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        staticAvgRestTime.frame = CGRectMake(0, 210, self.view.frame.size.width / 2, 50);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone X size
    {
        staticAvgRestTime.frame = CGRectMake(0, 210, self.view.frame.size.width / 2, 50);
    } else {
        staticAvgRestTime.frame = CGRectMake(0, 210, self.view.frame.size.width / 2, 50);
    }
    staticAvgRestTime.textAlignment = NSTextAlignmentCenter;
    staticAvgRestTime.font = [UIFont fontWithName:@"OpenSans" size:12];
    staticAvgRestTime.numberOfLines = 0;
    staticAvgRestTime.text = NSLocalizedString(@"AVG TIME PER SET", nil);
    [self.view addSubview:staticAvgRestTime];
    
    
    if ([weightLabelString isEqualToString:@"0"]) {
        setAltString = [[UILabel alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            setAltString.frame = CGRectMake(10, 135, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            setAltString.frame = CGRectMake(10, 135, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            setAltString.frame = CGRectMake(10, 145, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            setAltString.frame = CGRectMake(10, 155, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            setAltString.frame = CGRectMake(10, 195, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:14];
        }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
        {
            setAltString.frame = CGRectMake(10, 195, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else {
            setAltString.frame = CGRectMake(10, 195, self.view.frame.size.width - 20, 50);
            setAltString.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        setAltString.textAlignment = NSTextAlignmentCenter;
        setAltString.numberOfLines = 0;
        setAltString.text = setAltLabelString;
        [self.view addSubview:setAltString];
        
        [_verticalLine removeFromSuperview];
        [weightLabel removeFromSuperview];
        [restTimeLabel removeFromSuperview];
        [staticWeight removeFromSuperview];
        [staticAvgRestTime removeFromSuperview];
    } else {
        [setAltString removeFromSuperview];
    }
    
    
    //[self performSelector:@selector(retrieveFromParse)];
    
    UIButton *startExerciseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 450, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 500, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 600, 180, 33);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 650, 180, 33);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 650, 180, 33);
    }else if ([[UIScreen mainScreen] bounds].size.height == 896) //iPhone XR/Max size
    {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 650, 180, 33);
    }
    else {
        startExerciseBtn.frame = CGRectMake(self.view.frame.size.width/2-90, 650, 180, 33);
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [startExerciseBtn setImage:[UIImage imageNamed:@"btn_start_french"] forState:UIControlStateNormal];
    } else {
        [startExerciseBtn setImage:[UIImage imageNamed:@"btn_start"] forState:UIControlStateNormal];
    }
    [startExerciseBtn addTarget:self action:@selector(startExerciseBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:startExerciseBtn];
    
    NSLog(@"VIDEO: %@", URLString);
    if ([URLString isEqualToString: @"NO_VIDEO"]) {
        [_playButton removeFromSuperview];
    }
    
    if(socExercise) {
        NSLog(@"SCHOOL OF CALI EXERCISE");
    } else if(socChallenge) {
        NSLog(@"SCHOOL OF CALI CHAL");
        
        for (UIView *view in [self.view subviews])
        {
            [view removeFromSuperview];
        }
        
        UIView *challengeView = [[UIView alloc] init];
        if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone X size
            challengeView.frame = CGRectMake(0, 240, self.view.frame.size.width, self.view.frame.size.height);
        }else{
            challengeView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }
        [self.view addSubview:challengeView];
        
        UITextView *descLabel = [[UITextView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            descLabel.frame = CGRectMake(10, 320, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            descLabel.frame = CGRectMake(10, 320, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            descLabel.frame = CGRectMake(10, 380, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        descLabel.textAlignment = NSTextAlignmentCenter;
        descLabel.text = descLabelString;
        [challengeView addSubview:descLabel];
        
        UILabel *exerciseLabel = [[UILabel alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        } else {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        exerciseLabel.font = [UIFont fontWithName:@"ethnocentric" size:16];
        exerciseLabel.numberOfLines = 2;
        exerciseLabel.textAlignment = NSTextAlignmentCenter;
        exerciseLabel.text = exerciseLabelString;
        [challengeView addSubview:exerciseLabel];
        
        UIButton *videoBtn = [[UIButton alloc] init];
        videoBtn.frame = CGRectMake(0, 150, self.view.frame.size.width, 200);
        [videoBtn addTarget:self action:@selector(btnPlay:) forControlEvents:UIControlEventTouchUpInside];
        [challengeView addSubview:videoBtn];
        PFFile *eventImage = exerciseObject[@"ExerciseImage"];
        
        if(eventImage != NULL)
        {
            [eventImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error)
             {
                 [videoBtn setBackgroundImage:[UIImage imageWithData:imageData] forState:UIControlStateNormal];
             }];
        }
        
        UIImageView *playBtn = [[UIImageView alloc] init];
        playBtn.frame = CGRectMake((self.view.frame.size.width / 2) - 25, 150 + 72, 50, 56);
        playBtn.image = [UIImage imageNamed:@"btn_play"];
        [challengeView addSubview:playBtn];
        
    } else if(socLesson) {
        NSLog(@"SCHOOL OF CALI LESSON");
        
        for (UIView *view in [self.view subviews])
        {
            [view removeFromSuperview];
        }
        
        UIView *lessonView = [[UIView alloc] init];
        if([[UIScreen mainScreen] bounds].size.height == 812){  //iPhone X size
            lessonView.frame = CGRectMake(0, 240, self.view.frame.size.width, self.view.frame.size.height);
        }else{
            lessonView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        }
        [self.view addSubview:lessonView];
        
        UITextView *descLabel = [[UITextView alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            descLabel.frame = CGRectMake(10, 320, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            descLabel.frame = CGRectMake(10, 320, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            descLabel.frame = CGRectMake(10, 380, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        } else {
            descLabel.frame = CGRectMake(10, 420, self.view.frame.size.width - 20, 260);
            descLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        }
        descLabel.textAlignment = NSTextAlignmentCenter;
        descLabel.text = descLabelString;
        [lessonView addSubview:descLabel];
        
        UILabel *exerciseLabel = [[UILabel alloc] init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
        {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        } else {
            exerciseLabel.frame = CGRectMake(10, 70, self.view.frame.size.width - 20 / 2, 50);
        }
        exerciseLabel.font = [UIFont fontWithName:@"ethnocentric" size:16];
        exerciseLabel.numberOfLines = 2;
        exerciseLabel.textAlignment = NSTextAlignmentCenter;
        exerciseLabel.text = exerciseLabelString;
        [lessonView addSubview:exerciseLabel];
        UIButton *videoBtn = [[UIButton alloc] init];
        videoBtn.frame = CGRectMake(0, 150, self.view.frame.size.width, 200);
        
        [videoBtn addTarget:self action:@selector(btnPlay:) forControlEvents:UIControlEventTouchUpInside];
        [lessonView addSubview:videoBtn];
        PFFile *eventImage = exerciseObject[@"ExerciseImage"];
        
        if(eventImage != NULL)
        {
            [eventImage getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error)
             {
                 [videoBtn setBackgroundImage:[UIImage imageWithData:imageData] forState:UIControlStateNormal];
             }];
        }
        
        UIImageView *playBtn = [[UIImageView alloc] init];
        playBtn.frame = CGRectMake((self.view.frame.size.width / 2) - 25, 150 + 72, 50, 56);
        playBtn.image = [UIImage imageNamed:@"btn_play"];
        [lessonView addSubview:playBtn];
        
    } else {
        NSLog(@"NOT SCHOOL OF CALI");
        
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone X size
        {
            UIView *lessonView = [[UIView alloc] init];
            lessonView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:lessonView];
            
            UIButton *videoBtn = [[UIButton alloc] init];
            videoBtn.frame = CGRectMake(0, 200, self.view.frame.size.width, 200);
            [videoBtn addTarget:self action:@selector(btnPlay:) forControlEvents:UIControlEventTouchUpInside];
            [lessonView addSubview:videoBtn];
            
        } else {
            
            
        }
    }
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
}

# pragma mark Video Orientation Methods
#pragma mark MPMovieController Manager

-(IBAction)btnPlay:(id)sender
{
    
    //NSLog(@"Video LINK%@", videoLink);
    NSLog(@"owowowowowowowowowowowo");
    self.movieController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:URLString]];
    
    self.movieController.view.frame = self.view.bounds;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(doneButtonClick:)
                                                 name:MPMoviePlayerDidExitFullscreenNotification
                                               object:nil];
    
    [self.view addSubview:self.movieController.view];
    //[movieView.moviePlayer prepareToPlay];
    [self.movieController setFullscreen:YES animated:YES];
    [self.movieController play];
    
}

-(void)doneButtonClick:(NSNotification*)aNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerDidExitFullscreenNotification
                                                  object:nil];
    
    //NSLog(@"User pressed done");
    [self.movieController stop];
    [self.movieController.view removeFromSuperview];
}

- (void) buildVideo
{
    
}
-(IBAction)tapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)retrieveFromParse {
    
    //   PFQuery *videoQuery = [PFQuery queryWithClassName:@"Exercises"];
    //   [videoQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    
    //       if (!error) {
    //           videoURL = [[NSMutableArray alloc] initWithArray:objects];
    //           NSString *URLString = [[videoURL objectAtIndex:11] objectForKey:@"VideoURL"];
    //           NSLog(@"%@", URLString);
    
    //       }
    
    //   }];
    
}


- (IBAction)startExerciseBtn:(id)sender {
    StopwatchViewController *stopWatchDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"StopwatchViewController"];
    stopWatchDetail.stopWatchParseObject = exerciseObject;
    stopWatchDetail.stopwatchTypeOfExercise = typeOfExercise;
    [self.navigationController pushViewController:stopWatchDetail animated:YES];
}

@end

