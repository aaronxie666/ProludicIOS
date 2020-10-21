//
//  BrowseAllDetailController.h
//  Proludic
//
//  Created by Geoff Baker on 03/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MediaPlayer/MediaPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface BrowseAllDetailController : UIViewController {
    

    IBOutlet UIImageView *imageView;
    NSString *exerciseLabelString;
    NSString *URLFallback;
    

}
@property (nonatomic, retain) PFObject *exerciseObject;
@property (nonatomic, retain) NSString *typeOfExercise;
@property (nonatomic, strong) MPMoviePlayerController *movieController;
@property (nonatomic, retain) NSString *exerciseLabelString;
@property (nonatomic, retain) NSString *setTimeLabelString;
@property (nonatomic, retain) NSString *setRepsLabelString;
@property (nonatomic, retain) NSString *setAltLabelString;
@property (nonatomic, retain) NSString *restTimeLabelString;
@property (nonatomic, retain) NSString *weightLabelString;
@property (nonatomic, retain) NSString *descLabelString;
@property (nonatomic, retain) NSString *setSetsLabelString;
@property (nonatomic, retain) NSData *setImageData;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) NSMutableArray *videoURL;
@property (nonatomic, retain) NSMutableArray *imageDone;
@property (nonatomic, retain) NSString *URLString;
@property (nonatomic) NSInteger *x;
@property (weak, nonatomic) UIView *verticalLine;
@property (weak, nonatomic) UILabel *staticWeightLabel;
@property (weak, nonatomic) UILabel *staticTimeLabel;
@property (weak, nonatomic) UIButton *playButton;

//SOC
@property (nonatomic, retain) NSString *socLesson;
@property (nonatomic, retain) NSString *socChallenge;
@property (nonatomic, retain) NSString *socExercise;


- (IBAction)btnPlay:(id)sender;

- (IBAction)startExerciseBtn:(id)sender;

@end
