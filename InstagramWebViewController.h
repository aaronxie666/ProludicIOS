//
//  WebViewController.h
//  KnowFootball
//
//  Created by Luke on 02/09/2015.
//  Copyright (c) 2015 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InstagramWebViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain) UIWebView *loginWebView;

@property (nonatomic, retain) UIButton *cancelButton;

@property (nonatomic, retain) UITextField *emailTextField;

@end
