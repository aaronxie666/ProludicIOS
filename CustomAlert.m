//
//  CustomAlert.m
//  Proludic
//
//  Created by Geoff Baker on 29/11/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "CustomAlert.h"
#import "DashboardViewController.h"
#import "CommunityViewController.h"
#import "StopwatchViewController.h"

@implementation CustomAlert {
    
    UIImageView *background;
    
    UIView *totalView;
    UIView *alertView;
    NSString *alertText;
    NSString *alertBodyText;
    NSString *storeText;
    
    int alertIdentifier;
    
    UITextField *textField;
    UITextField *textField2;
    
    DashboardViewController *DashVC;
    CommunityViewController *CommVC;
    StopwatchViewController *StopVC;
}

-(void) loading: (UIView*)view:(NSString*)text:(NSString*)bodyText  {
    totalView = view;
    alertText = text;
    alertBodyText = bodyText;
    [self wakeAlert];
}

-(void) loadingVar:(UIViewController*)dash :(NSString *)text :(NSString *)bodyText :(NSString *)varText {
    totalView = dash.view;
    alertText = text;
    alertBodyText = bodyText;
    storeText = varText;
    DashVC = dash;
    [self wakeAlert];
}

-(void) loadDeletePost:(UIViewController*)dash :(NSString *)text :(NSString *)bodyText :(NSString *)varText :(int)identifier {
    totalView = dash.view;
    alertText = text;
    alertBodyText = bodyText;
    storeText = varText;
    CommVC = dash;
    alertIdentifier = identifier;
    [self wakeDeleteAlert];
}

-(void) loadSingle: (UIView*)view :(NSString*)text :(NSString*)bodyText  {
    totalView = view;
    alertText = text;
    alertBodyText = bodyText;
    [self wakeAlertSingle];
}

-(void) loadTextLine:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText {
    totalView = dash.view;
    alertText = text;
    alertBodyText = bodyText;
    NSString *string = [NSString stringWithFormat:@"%@", dash];
    if ([string containsString:@"Community"]) {
        CommVC = dash;
    } else {
        DashVC = dash;
    }
    [self wakeAlertTextLine];
}

-(void) loadDoubleTextLineVar:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText:(int)selector {
    totalView = dash.view;
    alertText = text;
    alertBodyText = bodyText;
    NSString *string = [NSString stringWithFormat:@"%@", dash];
    if ([string containsString:@"Community"]) {
        CommVC = dash;
        NSLog(@"IT WORKED");
    } else {
        DashVC = dash;
        NSLog(@"IT WORKED LOL JK");
    }
    alertIdentifier = selector;
    [self wakeAlertDoubleTextLine];
}

-(void) removeFocus {
    [textField resignFirstResponder];
    [textField2 resignFirstResponder];
}

-(void) loadTextLineVar:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText:(int)selector {
    totalView = dash.view;
    alertText = text;
    alertBodyText = bodyText;
    NSString *string = [NSString stringWithFormat:@"%@", dash];
    if ([string containsString:@"Community"]) {
        CommVC = dash;
        NSLog(@"IT WORKED");
    } else {
        DashVC = dash;
        NSLog(@"IT WORKED LOL JK");
    }
    alertIdentifier = selector;
    [self wakeAlertTextLine];
}

-(void) closing: (UIView*)view {
    [self sleepAlert];
}

-(void)wakeAlert {
    NSLog(@"%@", alertText);
    
    alertView = [[UIView alloc] init];
    alertView.frame = CGRectMake(0, 0, totalView.frame.size.width, totalView.frame.size.height);
    alertView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.4];
    alertView.alpha = 0;
    [totalView addSubview:alertView];
    
    background = [[UIImageView alloc] init];
    background.frame = CGRectMake(20, 200, totalView.frame.size.width - 40, 200);
    background.image = [UIImage imageNamed:@"alert_bg"];
    [alertView addSubview:background];
    
    [self addAlertLabel];
    [self addAlertText];
    
    UIButton *yesBtn = [[UIButton alloc] init];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
    } else {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
    }
    [yesBtn addTarget:self action:@selector(checkResponse:) forControlEvents:UIControlEventTouchUpInside];
    yesBtn.tag = 1;
    yesBtn.frame = CGRectMake(60, 340, 120, 40);
    [alertView addSubview:yesBtn];
    
    UIButton *noBtn = [[UIButton alloc] init];
    if([language containsString:@"fr"]) {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    [noBtn addTarget:self action:@selector(checkResponse:) forControlEvents:UIControlEventTouchUpInside];
    noBtn.tag = 2;
    noBtn.frame = CGRectMake(background.frame.size.width - 140, 340, 120, 40);
    [alertView addSubview:noBtn];
    
    [UIView animateWithDuration:0.4f animations:^{
        alertView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f animations:^{

            
        }];
    }];
}

-(void)wakeAlertSingle {
    NSLog(@"%@", alertText);
    
    alertView = [[UIView alloc] init];
    alertView.frame = CGRectMake(0, 0, totalView.frame.size.width, totalView.frame.size.height);
    alertView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.4];
    alertView.alpha = 0;
    [totalView addSubview:alertView];
    
    background = [[UIImageView alloc] init];
    background.frame = CGRectMake(20, 200, totalView.frame.size.width - 40, 200);
    background.image = [UIImage imageNamed:@"alert_bg"];
    [alertView addSubview:background];
    
    [self addAlertLabel];
    [self addAlertText];
    
    UIButton *yesBtn = [[UIButton alloc] init];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
    } else {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_continue"] forState:UIControlStateNormal];
    }
    [yesBtn addTarget:self action:@selector(sleepAlert) forControlEvents:UIControlEventTouchUpInside];
    yesBtn.tag = 1;
    yesBtn.frame = CGRectMake((background.frame.size.width / 2) - 40, 340, 120, 40);
    [alertView addSubview:yesBtn];
    
    [UIView animateWithDuration:0.4f animations:^{
        alertView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f animations:^{
            
            
        }];
    }];
}

-(void)wakeAlertTextLine {
    NSLog(@"%@", alertText);
    
    alertView = [[UIView alloc] init];
    alertView.frame = CGRectMake(0, 0, totalView.frame.size.width, totalView.frame.size.height);
    alertView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.4];
    alertView.alpha = 0;
    [totalView addSubview:alertView];
    
    background = [[UIImageView alloc] init];
    background.frame = CGRectMake(20, 200, totalView.frame.size.width - 40, 230);
    background.image = [UIImage imageNamed:@"alert_bg"];
    background.userInteractionEnabled = YES;
    [alertView addSubview:background];

    [self addAlertLabel];
    [self addAlertText];
    
    textField = [[UITextField alloc] init];
    textField.frame = CGRectMake(30, 115, background.frame.size.width - 60, 30);
    textField.placeholder = @"Message...";
    textField.font = [UIFont fontWithName:@"Open Sans" size:12];
    textField.textColor = [UIColor blackColor];
    textField.backgroundColor = [UIColor whiteColor];
    [textField isFirstResponder];
    [background addSubview:textField];
    
    UIButton *yesBtn = [[UIButton alloc] init];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
    } else {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
    }
    [yesBtn addTarget:self action:@selector(readText:) forControlEvents:UIControlEventTouchUpInside];
    yesBtn.tag = 1;
    yesBtn.frame = CGRectMake(60, 365, 120, 40);
    [alertView addSubview:yesBtn];
    
    UIButton *noBtn = [[UIButton alloc] init];
    if([language containsString:@"fr"]) {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    [noBtn addTarget:self action:@selector(readText:) forControlEvents:UIControlEventTouchUpInside];
    noBtn.tag = 2;
    noBtn.frame = CGRectMake(background.frame.size.width - 140, 365, 120, 40);
    [alertView addSubview:noBtn];
    
    [UIView animateWithDuration:0.4f animations:^{
        alertView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f animations:^{
            
            
        }];
    }];
}

-(void)wakeAlertDoubleTextLine {
    NSLog(@"%@", alertText);
    
    alertView = [[UIView alloc] init];
    alertView.frame = CGRectMake(0, 0, totalView.frame.size.width, totalView.frame.size.height);
    alertView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.4];
    alertView.alpha = 0;
    [totalView addSubview:alertView];
    
    background = [[UIImageView alloc] init];
    background.frame = CGRectMake(20, 100, totalView.frame.size.width - 40, 280);
    background.image = [UIImage imageNamed:@"alert_bg"];
    background.userInteractionEnabled = YES;
    [alertView addSubview:background];
    
    [self addAlertLabel];
    [self addAlertText];
    
    textField = [[UITextField alloc] init];
    textField.frame = CGRectMake(30, 115, background.frame.size.width - 60, 30);
    textField.placeholder = @"Message...";
    textField.font = [UIFont fontWithName:@"Open Sans" size:12];
    textField.textColor = [UIColor blackColor];
    textField.backgroundColor = [UIColor whiteColor];
    [textField becomeFirstResponder];
    [background addSubview:textField];
    
    textField2 = [[UITextField alloc] init];
    textField2.frame = CGRectMake(30, 160, background.frame.size.width - 60, 30);
    textField2.placeholder = @"Message...";
    textField2.font = [UIFont fontWithName:@"Open Sans" size:12];
    textField2.textColor = [UIColor blackColor];
    textField2.backgroundColor = [UIColor whiteColor];
    [background addSubview:textField2];
    
    UIButton *yesBtn = [[UIButton alloc] init];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
    } else {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
    }
    [yesBtn addTarget:self action:@selector(readText:) forControlEvents:UIControlEventTouchUpInside];
    yesBtn.tag = 1;
    yesBtn.frame = CGRectMake(60, 315, 120, 40);
    [alertView addSubview:yesBtn];
    
    UIButton *noBtn = [[UIButton alloc] init];
    if([language containsString:@"fr"]) {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    [noBtn addTarget:self action:@selector(readText:) forControlEvents:UIControlEventTouchUpInside];
    noBtn.tag = 2;
    noBtn.frame = CGRectMake(background.frame.size.width - 140, 315, 120, 40);
    [alertView addSubview:noBtn];
    
    [UIView animateWithDuration:0.4f animations:^{
        alertView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f animations:^{
            
            
        }];
    }];
}

-(void)wakeDeleteAlert {
    NSLog(@"%@", alertText);
    
    alertView = [[UIView alloc] init];
    alertView.frame = CGRectMake(0, 0, totalView.frame.size.width, totalView.frame.size.height);
    alertView.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:0.4];
    alertView.alpha = 0;
    [totalView addSubview:alertView];
    
    background = [[UIImageView alloc] init];
    background.frame = CGRectMake(20, 200, totalView.frame.size.width - 40, 200);
    background.image = [UIImage imageNamed:@"alert_bg"];
    [alertView addSubview:background];
    
    [self addAlertLabel];
    [self addAlertText];
    
    UIButton *yesBtn = [[UIButton alloc] init];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yes_french"] forState:UIControlStateNormal];
    } else {
        [yesBtn setBackgroundImage:[UIImage imageNamed:@"btn_yesChallenge"] forState:UIControlStateNormal];
    }
    [yesBtn addTarget:self action:@selector(checkDeleteResponse:) forControlEvents:UIControlEventTouchUpInside];
    yesBtn.tag = 1;
    yesBtn.frame = CGRectMake(60, 340, 120, 40);
    [alertView addSubview:yesBtn];
    
    UIButton *noBtn = [[UIButton alloc] init];
    if([language containsString:@"fr"]) {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_no_french"] forState:UIControlStateNormal];
    } else {
        [noBtn setBackgroundImage:[UIImage imageNamed:@"btn_noChallenge"] forState:UIControlStateNormal];
    }
    [noBtn addTarget:self action:@selector(checkDeleteResponse:) forControlEvents:UIControlEventTouchUpInside];
    noBtn.tag = 2;
    noBtn.frame = CGRectMake(background.frame.size.width - 140, 340, 120, 40);
    [alertView addSubview:noBtn];
    
    [UIView animateWithDuration:0.4f animations:^{
        alertView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3f animations:^{
            
            
        }];
    }];
}

-(IBAction)readText:(UIButton*)sender {
    storeText = textField.text;
    
    if([alertText isEqualToString:@"Reply To Post"]) {
        if(sender.tag == 1) {
            NSLog(@"THIS IS A TEST1");
            [CommVC readText:@"True":storeText:1];
            NSLog(@"THIS IS A TEST2");
        } else if(sender.tag == 2) {
            [CommVC readText:@"False":storeText:1];
        }
    } else if([alertText isEqualToString:@"Reply To The Reply"]) {
        if(sender.tag == 1) {
            [CommVC readText:@"True":storeText:2];
        } else if(sender.tag == 2) {
            [CommVC readText:@"False":storeText:2];
        }
    } else if([alertText isEqualToString:@"Create New Thread"]) {
        NSLog(@"------WTF");
        NSString *bodyText = textField2.text;
        if(sender.tag == 1) {
            [CommVC readThreadText:@"True":storeText:bodyText];
        } else if(sender.tag == 2) {
            [CommVC readThreadText:@"False":storeText:bodyText];
        }
    } else {
        if(sender.tag == 1) {
            [DashVC readText:@"True":storeText];
        } else if(sender.tag == 2) {
            [DashVC readText:@"False":storeText];
        }
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [background setFrame:CGRectMake(15, 195, totalView.frame.size.width - 30, 210)];
        alertView.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)sleepAlert {
    NSLog(@"SLEEPING");
    
    [UIView animateWithDuration:0.3f animations:^{
        [background setFrame:CGRectMake(15, 195, totalView.frame.size.width - 30, 210)];
        alertView.alpha = 0;
    } completion:^(BOOL finished) {

    }];
}

-(IBAction)checkResponse:(UIButton*)sender {
    if(sender.tag == 1) {
        [DashVC alertResponse:@"True":storeText];
    } else if(sender.tag == 2) {
        [DashVC alertResponse:@"False":storeText];
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [background setFrame:CGRectMake(15, 195, totalView.frame.size.width - 30, 210)];
        alertView.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

-(IBAction)checkDeleteResponse:(UIButton*)sender {
    if(sender.tag == 1) {
        [CommVC alertDeleteResponse:@"True":storeText:sender.tag];
    } else if(sender.tag == 2) {
        [CommVC alertDeleteResponse:@"False":storeText:sender.tag];
    }
    
    [UIView animateWithDuration:0.3f animations:^{
        [background setFrame:CGRectMake(15, 195, totalView.frame.size.width - 30, 210)];
        alertView.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma Reusable Parts
-(void)addAlertLabel {
    UILabel *updateLabel = [[UILabel alloc] init];
    updateLabel.frame = CGRectMake(30, 40, background.frame.size.width - 60, 30);
    updateLabel.text = alertText;
    updateLabel.font = [UIFont fontWithName:@"Open Sans" size:14];
    updateLabel.textColor = [UIColor whiteColor];
    updateLabel.textAlignment = NSTextAlignmentCenter;
    [background addSubview:updateLabel];
}

-(void)addAlertText {
    UITextView *alertTextView = [[UITextView alloc] init];
    alertTextView.frame = CGRectMake(30, 70, background.frame.size.width - 60, 60);
    alertTextView.text = alertBodyText;
    alertTextView.font = [UIFont fontWithName:@"Open Sans" size:12];
    alertTextView.textColor = [UIColor whiteColor];
    alertTextView.userInteractionEnabled = NO;
    alertTextView.backgroundColor = [UIColor clearColor];
    alertTextView.textAlignment = NSTextAlignmentCenter;
    [background addSubview:alertTextView];
}


@end
