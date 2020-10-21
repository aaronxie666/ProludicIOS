//
//  StopwatchViewController.h
//  Proludic
//
//  Created by Geoff Baker on 18/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "DBManager.h"

@interface StopwatchViewController : UIViewController


{
    NSTimer *exerciseTimer;
    BOOL running;
    int count;
    IBOutlet UIImageView *imageView;
}

@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *tapWhenDoneBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishExerciseBtn;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (nonatomic, retain) NSData *setImageData;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) PFObject *stopWatchParseObject;
@property (nonatomic, retain) NSString *stopwatchTypeOfExercise;


- (IBAction)startBtnPushed:(id)sender;
- (void)updateTimer;

-(void)alertResponse:(NSString*)result:(NSString*)varText;

@end

