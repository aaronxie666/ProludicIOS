//
//  RegisterEmailViewController.m
//  KnowFootball
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import "RegisterEmailViewController.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "Flurry.h"
#import <Parse/Parse.h>
#import "CustomAlert.h"

@interface RegisterEmailViewController ()
@property (strong, nonatomic) IBOutlet UISwitch *ageSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *genderSwitch;
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation RegisterEmailViewController{
    NSUserDefaults *defaults; //Manages global variables
    IBOutlet UITextField *nameTextField;
    IBOutlet UITextField *unameTextField;
    IBOutlet UITextField *email;
    IBOutlet UITextField *password;
    IBOutlet UITextField *confirmPassword;
    IBOutlet UITextField *lastTextField;
    UIAlertView *alert;
    UIScrollView *theScrollView;
    BOOL underage;
    NSData *profilePictureData;
    IBOutlet UITextField *heightTextField1;
    IBOutlet UITextField *heightTextField2;
    IBOutlet UITextField *weightTextField;
    BOOL isMale;
    
    
    MBProgressHUD *HUD;//Loading Screen Implementation
    UIImageView *activityImageView;
    NSString *emailString;
    NSString *passwordString;
    UIView *homeView;
    UIImageView *pictureOverlay;
    UIScrollView *popUpScroller;
    
    int currentStage;
    UIScrollView *registerScroller;
    bool userIsOnOverlay;
    bool libraryPicked;
    UIView *popUpView;
    UIImage *selectedProfileImage;
    UIButton *addProfileButton;
    UIView *tmpView;
    
    CustomAlert *alertVC;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [Flurry logEvent:@"User Opened Register Email Page" timed:YES];
    
    underage = YES;
    
    theScrollView = [[UIScrollView alloc] init];
    theScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the button
    theScrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
    defaults = [NSUserDefaults standardUserDefaults]; //Initialization of the global variable
    
    //Reachibility (Checking Internet Connection)
    
    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //Change the host name here to change the server you want to monitor.
    NSString *remoteHostName = @"www.apple.com";
    //    self.remoteHostLabel.text = [NSString stringWithFormat:remoteHostLabelFormatString, remoteHostName];
    
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    [self updateInterfaceWithReachability:self.hostReachability];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    [self updateInterfaceWithReachability:self.wifiReachability];
    
    currentStage = 0;
    
    //BackgroundImage
    UIImageView *background = [[UIImageView alloc] init];
    background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    background.image = [UIImage imageNamed:@"BG"];
    [theScrollView addSubview:background];
    
    //Implements custom back button
    UIButton *backButton = [[UIButton alloc] init];
    backButton.frame = CGRectMake(-5, 20, 60, 40); //Position of the button
    [backButton setImage:[UIImage imageNamed:@"backButtonRegister"] forState:UIControlStateNormal];
    [backButton setShowsTouchWhenHighlighted:TRUE];
    [backButton addTarget:self action:@selector(popViewControllerWithAnimation) forControlEvents:UIControlEventTouchDown];
    [theScrollView addSubview:backButton];
    
    //Icon Background
    
    UIImageView *iconBackground = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        iconBackground.frame = CGRectMake(30, 5 - 30, self.view.frame.size.width-60, 220);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        iconBackground.frame = CGRectMake(30, 25 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    } else {
        iconBackground.frame = CGRectMake(30, 50 - 30, self.view.frame.size.width-60, 300);//Position of the button
    }
    iconBackground.image = [UIImage imageNamed:@"ProludicLogo.jpg"];
    iconBackground.contentMode = UIViewContentModeScaleAspectFit;
    iconBackground.clipsToBounds = YES;
    [theScrollView addSubview:iconBackground];
    
    //Back Button
    
    UIButton *backToLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        backToLoginButton.frame = CGRectMake(0, 10, 60, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        backToLoginButton.frame = CGRectMake(0, 20, 60, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        backToLoginButton.frame = CGRectMake(0, 30, 80, 40);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        backToLoginButton.frame = CGRectMake(0, 40, 80, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        backToLoginButton.frame = CGRectMake(0, 40, 80, 40);//Position of the button
    } else {
        backToLoginButton.frame = CGRectMake(0, 40, 80, 40);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [backToLoginButton setBackgroundImage:[UIImage imageNamed:@"btn_back_french"] forState:UIControlStateNormal];
    } else {
        [backToLoginButton setBackgroundImage:[UIImage imageNamed:@"Back_arrowButton"] forState:UIControlStateNormal];
    }
    [backToLoginButton addTarget:self action:@selector(tapBackButton) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:backToLoginButton];
    
    //Submit Button
    
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        submitButton.frame = CGRectMake(40, self.view.frame.size.height-60, self.view.frame.size.width-80, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        submitButton.frame = CGRectMake(40, self.view.frame.size.height-50, self.view.frame.size.width-80, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        submitButton.frame = CGRectMake(50, self.view.frame.size.height-80, self.view.frame.size.width-100, 40);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        submitButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        submitButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    } else {
         submitButton.frame = CGRectMake(70, self.view.frame.size.height-250, self.view.frame.size.width-140, 40);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [submitButton setBackgroundImage:[UIImage imageNamed:@"btn_submit_french"] forState:UIControlStateNormal];
    } else {
        [submitButton setBackgroundImage:[UIImage imageNamed:@"Reg_email_btn"] forState:UIControlStateNormal];
    }
    [submitButton addTarget:self action:@selector(tapButtonRegisterEmail:) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:submitButton];
    
    UIColor *color = [UIColor whiteColor];
    
    
    // Create the UI Side Scroll View
    registerScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        registerScroller.frame = CGRectMake(0, 160, self.view.frame.size.width*2, 260); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        registerScroller.frame = CGRectMake(0, 220, self.view.frame.size.width*2, 280); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        registerScroller.frame = CGRectMake(0, 250, self.view.frame.size.width*2, 320); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        registerScroller.frame = CGRectMake(0, 270, self.view.frame.size.width*2, 350); //Position of the scroller
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        registerScroller.frame = CGRectMake(0, 270, self.view.frame.size.width*2, 350); //Position of the scroller
    } else {
        registerScroller.frame = CGRectMake(0, 270, self.view.frame.size.width*2, 350); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    registerScroller.bounces = YES;
    //registerScroller.backgroundColor = [UIColor colorWithRed:0.98 green:0.78 blue:0.47 alpha:1.0];
    registerScroller.delegate = self;
    registerScroller.scrollEnabled = YES;
    registerScroller.userInteractionEnabled = YES;
    [registerScroller setShowsHorizontalScrollIndicator:NO];
    [registerScroller setShowsVerticalScrollIndicator:NO];
    //registerScroller.alpha = 0.2;
    
    // Name
    // 230 310 360 370
    nameTextField = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        nameTextField.frame = CGRectMake(40, 230 - 70 - 150, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        nameTextField.frame = CGRectMake(40, 310 - 70 - 220, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        nameTextField.frame = CGRectMake(50, 360 - 70 - 250, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        nameTextField.frame = CGRectMake(70, 370 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        nameTextField.frame = CGRectMake(70, 370 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        nameTextField.frame = CGRectMake(70, 370 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    nameTextField.textAlignment = NSTextAlignmentLeft;
    nameTextField.textColor = [UIColor blackColor];
    nameTextField.backgroundColor = [UIColor whiteColor];
    CALayer *borderName = [CALayer layer];
    CGFloat borderWidthName = 1;
    borderName.borderColor = [UIColor darkGrayColor].CGColor;
    borderName.frame = CGRectMake(0,  nameTextField.frame.size.height - borderWidthName,  nameTextField.frame.size.width,  nameTextField.frame.size.height);
    borderName.borderWidth = borderWidthName;
    [nameTextField.layer addSublayer:borderName];
    nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    nameTextField.returnKeyType = UIReturnKeyDone;
    
    if ([nameTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        nameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Name", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    nameTextField.keyboardType = UIKeyboardAppearanceDark;
    nameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameTextField.clipsToBounds = YES;
    [nameTextField setDelegate:self];
    nameTextField.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0];
    [registerScroller addSubview:nameTextField];
    
    // Username
    // 265 348 403 416
    unameTextField = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        unameTextField.frame = CGRectMake(40, 265 - 70 - 150, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        unameTextField.frame = CGRectMake(40, 348 -70 - 220, self.view.frame.size.width-80, 25); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        unameTextField.frame = CGRectMake(50, 403 - 70 - 250, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        unameTextField.frame = CGRectMake(70, 416 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        unameTextField.frame = CGRectMake(70, 416 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        unameTextField.frame = CGRectMake(70, 416 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    unameTextField.textAlignment = NSTextAlignmentLeft;
    unameTextField.textColor = [UIColor blackColor];
    unameTextField.backgroundColor = [UIColor whiteColor];
    CALayer *borderuName = [CALayer layer];
    CGFloat borderWidthuName = 1;
    borderuName.borderColor = [UIColor darkGrayColor].CGColor;
    borderuName.frame = CGRectMake(0,  unameTextField.frame.size.height - borderWidthuName,  unameTextField.frame.size.width,  unameTextField.frame.size.height);
    borderuName.borderWidth = borderWidthuName;
    [unameTextField.layer addSublayer:borderuName];
    unameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    unameTextField.returnKeyType = UIReturnKeyDone;
    
    if ([unameTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        unameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Username", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    unameTextField.keyboardType = UIKeyboardAppearanceDark;
    unameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    unameTextField.clipsToBounds = YES;
    [unameTextField setDelegate:self];
    unameTextField.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0];
    [registerScroller addSubview:unameTextField];
    
    //Email
    // 300 386 446 462
    
    email = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        email.frame = CGRectMake(40, 300 - 70 - 150, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        email.frame = CGRectMake(40, 386 - 70 - 220, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        email.frame = CGRectMake(50, 446 - 70 - 250, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        email.frame = CGRectMake(70, 462 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        email.frame = CGRectMake(70, 462 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        email.frame = CGRectMake(70, 462 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    email.textAlignment = NSTextAlignmentLeft;
    email.textColor = [UIColor blackColor];
    email.backgroundColor = [UIColor whiteColor];
    CALayer *borderEmail = [CALayer layer];
    CGFloat borderWidthEmail = 1;
    borderEmail.borderColor = [UIColor darkGrayColor].CGColor;
    borderEmail.frame = CGRectMake(0, email.frame.size.height - borderWidthEmail, email.frame.size.width, email.frame.size.height);
    borderEmail.borderWidth = borderWidthEmail;
    [email.layer addSublayer:borderEmail];
    email.clearButtonMode = UITextFieldViewModeWhileEditing;
    email.returnKeyType = UIReturnKeyDone;
    email.autocorrectionType = UITextAutocorrectionTypeNo;
    if ([email respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        
        email.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Email", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0]}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    email.keyboardType = UIKeyboardAppearanceDark;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    email.clipsToBounds = YES;
    email.returnKeyType = UIReturnKeyDone;
    email.keyboardType = UIKeyboardTypeEmailAddress;
    [email setDelegate:self];
    email.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0];
    [registerScroller addSubview:email];
    
    //Password
    // 335 424 489 508
    password = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        password.frame = CGRectMake(40, 335 - 70 - 150, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        password.frame = CGRectMake(40, 424 - 70 - 220, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        password.frame = CGRectMake(50, 489 - 70 - 250, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        password.frame = CGRectMake(70, 508 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        password.frame = CGRectMake(70, 508 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        password.frame = CGRectMake(70, 508 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    password.textAlignment = NSTextAlignmentLeft;
    password.textColor = [UIColor blackColor];
    password.backgroundColor = [UIColor whiteColor];
    CALayer *borderPassword = [CALayer layer];
    CGFloat borderWidthPassword = 1;
    borderPassword.borderColor = [UIColor darkGrayColor].CGColor;
    borderPassword.frame = CGRectMake(0, email.frame.size.height - borderWidthEmail, email.frame.size.width, email.frame.size.height);
    borderPassword.borderWidth = borderWidthPassword;
    [password.layer addSublayer:borderPassword];
    password.clearButtonMode = UITextFieldViewModeWhileEditing;
    password.returnKeyType = UIReturnKeyDone;
    if ([password respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0]}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    password.keyboardType = UIKeyboardAppearanceDark;
    password.clipsToBounds = YES;
    password.secureTextEntry = YES;
    [password setDelegate:self];
    password.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0];
    [registerScroller addSubview:password];
    
    //Confirm Password
    // 370 462 533 554
    confirmPassword = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        confirmPassword.frame = CGRectMake(40, 370 - 70 - 150, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        confirmPassword.frame = CGRectMake(40, 462 - 70 - 220, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        confirmPassword.frame = CGRectMake(50, 533 - 70 - 250, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        confirmPassword.frame = CGRectMake(70, 554 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        confirmPassword.frame = CGRectMake(70, 554 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        confirmPassword.frame = CGRectMake(70, 554 - 70 - 270, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    confirmPassword.textAlignment = NSTextAlignmentLeft;
    confirmPassword.textColor = [UIColor blackColor];
    confirmPassword.backgroundColor = [UIColor whiteColor];
    CALayer *borderCPassword = [CALayer layer];
    CGFloat borderWidthCPassword = 1;
    borderCPassword.borderColor = [UIColor darkGrayColor].CGColor;
    borderCPassword.frame = CGRectMake(0, email.frame.size.height - borderWidthEmail, email.frame.size.width, email.frame.size.height);
    borderCPassword.borderWidth = borderWidthCPassword;
    [confirmPassword.layer addSublayer:borderCPassword];
    confirmPassword.clearButtonMode = UITextFieldViewModeWhileEditing;
    confirmPassword.returnKeyType = UIReturnKeyDone;
    if ([confirmPassword respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        confirmPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Confirm Password", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:14.0]}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    confirmPassword.keyboardType = UIKeyboardAppearanceDark;
    confirmPassword.clipsToBounds = YES;
    confirmPassword.secureTextEntry = YES;
    [confirmPassword setDelegate:self];
    confirmPassword.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0];
    [registerScroller addSubview:confirmPassword];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    
    
    UILabel *under18Label = [[UILabel alloc]init];
    under18Label.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        under18Label.frame = CGRectMake(70, 405 - 70 - 150, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        under18Label.frame = CGRectMake(70, 465 - 20 - 220, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        under18Label.frame = CGRectMake(100, 535 - 20 - 250, 60, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        under18Label.frame = CGRectMake(120, 575 - 20 -270, 60, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        under18Label.frame = CGRectMake(120, 575 - 20 -270, 60, 41);
    } else {
        under18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        under18Label.frame = CGRectMake(120, 575 - 20 -270, 60, 41);
    }
    under18Label.text = NSLocalizedString(@"Under\n18", nil);
    under18Label.numberOfLines = 2;
    under18Label.textAlignment = NSTextAlignmentCenter;
    [registerScroller addSubview:under18Label];
    
    // Name Label
    UILabel *over18Label = [[UILabel alloc]init];
    over18Label.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        over18Label.frame = CGRectMake(193, 405 - 70 - 150, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        over18Label.frame = CGRectMake(193, 465 - 20 - 220, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        over18Label.frame = CGRectMake(218, 535 - 20 - 250, 60, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        over18Label.frame = CGRectMake(235, 575 - 20 -270, 60, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        over18Label.frame = CGRectMake(235, 575 - 20 -270, 60, 41);
    } else {
        over18Label.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        over18Label.frame = CGRectMake(235, 575 - 20 -270, 60, 41);
    }
    over18Label.text = NSLocalizedString(@"Over\n18", nil);
    over18Label.numberOfLines = 2;
    over18Label.textAlignment = NSTextAlignmentCenter;
    [registerScroller addSubview:over18Label];
    
    
    /*
     Creation, positioning and adding of the UISwitch on the screen.
     */
    _ageSwitch = [[UISwitch alloc] init];
    
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 415 - 70 - 150, 100, 60); //Position of the UISwitch
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 470 - 20 - 220, 100, 60); //Position of the UISwitch
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 542 - 20 - 250, 100, 60); //Position of the UISwitch
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 577 - 20 -270, 100, 60); //Position of the UISwitch
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 577 - 20 -270, 100, 60); //Position of the UISwitch
    } else {
        _ageSwitch.frame = CGRectMake(CGRectGetMidX(self.view.frame)-25, 577 - 20 -270, 100, 60); //Position of the UISwitch
    }
    
    _ageSwitch.onTintColor = [UIColor colorWithRed:0.305 green:0.305 blue:0.305 alpha:1.0];
    _ageSwitch.tintColor = [UIColor colorWithRed:0.305 green:0.305 blue:0.305 alpha:1.0];
    _ageSwitch.thumbTintColor = [UIColor colorWithRed:0.97 green:0.65 blue:0.19 alpha:1.0];
    [_ageSwitch addTarget:self action:@selector(flipAge:) forControlEvents:UIControlEventValueChanged];
    [registerScroller addSubview:_ageSwitch];
    
    [self.view addSubview:theScrollView];
    [theScrollView addSubview:registerScroller];
    
    [self addHeightWeightGenderStage];
    [self addProfilePicStage];
    
}

-(void) addHeightWeightGenderStage {
    heightTextField1 = [ [UITextField alloc ] init];
    UILabel *heightLabel1 = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width+40, 335 - 70-115, self.view.frame.size.width/4, 25); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 50, 340 - 70-115, 40, 25);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width+40, 424 - 70-195, self.view.frame.size.width/4, 28); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 50, 430 - 70-195, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width + 50, 489 - 70 - 225, self.view.frame.size.width/4, 33); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 50, 495 - 70 - 225, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width+70, 508 - 70 - 245, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 70, 515 - 70 - 245, 40, 25);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width+70, 508 - 70 - 245, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 70, 515 - 70 - 245, 40, 25);
    } else {
        heightTextField1.frame = CGRectMake(self.view.frame.size.width+70, 508 - 70 - 245, self.view.frame.size.width/4, 36); //Position of the Textfield
        heightLabel1.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        heightLabel1.frame = CGRectMake(self.view.frame.size.width*1.25 + 70, 515 - 70 - 245, 40, 25);
    }
    heightLabel1.text = NSLocalizedString(@"CM", nil);
    [registerScroller addSubview:heightLabel1];
    heightTextField1.textAlignment = NSTextAlignmentLeft;
    heightTextField1.textColor = [UIColor blackColor];
    heightTextField1.backgroundColor = [UIColor whiteColor];
    heightTextField2.textAlignment = NSTextAlignmentLeft;
    heightTextField2.textColor = [UIColor blackColor];
    heightTextField2.backgroundColor = [UIColor whiteColor];
    CALayer *borderName2 = [CALayer layer];
    CGFloat borderWidthName2 = 1;
    borderName2.borderColor = [UIColor darkGrayColor].CGColor;
    borderName2.frame = CGRectMake(0,  heightTextField1.frame.size.height - borderWidthName2,  heightTextField1.frame.size.width,  heightTextField1.frame.size.height);
    borderName2.borderWidth = borderWidthName2;
    [heightTextField1.layer addSublayer:borderName2];
    heightTextField1.clearButtonMode = UITextFieldViewModeWhileEditing;
    heightTextField1.returnKeyType = UIReturnKeyDone;
    
    if ([heightTextField1 respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        heightTextField1.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"HEIGHT", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"Bebas Neue" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    heightTextField1.keyboardType = UIKeyboardAppearanceDark;
    heightTextField1.autocapitalizationType = UITextAutocapitalizationTypeWords;
    heightTextField1.clipsToBounds = YES;
    [heightTextField1 setDelegate:self];
    heightTextField1.font = [UIFont fontWithName:@"Bebas Neue" size:14.0];
    [registerScroller addSubview:heightTextField1];
    
    weightTextField = [ [UITextField alloc ] init];
    UILabel *weightLabel = [[UILabel alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5, 335 - 70-115, self.view.frame.size.width/4, 25);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75 + 10, 340 - 70-115, 40, 25);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5, 424 - 70-195, self.view.frame.size.width/4, 28);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:12];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75 + 10, 430 - 70-195, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5, 489 - 70 - 225, self.view.frame.size.width/4, 33); //Position of the Textfield
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75, 495 - 70 - 225, 40, 25);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5 + 30, 508 - 70 - 245, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75 + 30, 515 - 70 - 245, 40, 25);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5 + 30, 508 - 70 - 245, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75 + 30, 515 - 70 - 245, 40, 25);
    } else {
        weightTextField.frame = CGRectMake(self.view.frame.size.width*1.5 + 30, 508 - 70 - 245, self.view.frame.size.width/4, 36);
        weightLabel.font = [UIFont fontWithName:@"Bebas Neue" size:14];
        weightLabel.frame = CGRectMake(self.view.frame.size.width*1.75 + 30, 515 - 70 - 245, 40, 25);
    }
    weightLabel.text = NSLocalizedString(@"kg", nil);
    [registerScroller addSubview:weightLabel];
    weightTextField.textAlignment = NSTextAlignmentLeft;
    weightTextField.textColor = [UIColor blackColor];
    weightTextField.backgroundColor = [UIColor whiteColor];
    CALayer *borderuName = [CALayer layer];
    CGFloat borderWidthuName = 1;
    borderuName.borderColor = [UIColor darkGrayColor].CGColor;
    borderuName.frame = CGRectMake(0,  weightTextField.frame.size.height - borderWidthuName,  weightTextField.frame.size.width,  weightTextField.frame.size.height);
    borderuName.borderWidth = borderWidthuName;
    [weightTextField.layer addSublayer:borderuName];
    weightTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    weightTextField.returnKeyType = UIReturnKeyDone;
    
    if ([weightTextField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        weightTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Weight", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor] , NSFontAttributeName : [UIFont fontWithName:@"Bebas Neue" size:14.0]}];
        
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    weightTextField.keyboardType = UIKeyboardAppearanceDark;
    weightTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    weightTextField.clipsToBounds = YES;
    [weightTextField setDelegate:self];
    weightTextField.font = [UIFont fontWithName:@"Bebas Neue" size:14.0];
    [registerScroller addSubview:weightTextField];
    
    // Name Label
    UILabel *maleLabel = [[UILabel alloc]init];
    maleLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        maleLabel.frame = CGRectMake(self.view.frame.size.width+70, 325 - 20 -130, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        maleLabel.frame = CGRectMake(self.view.frame.size.width+70, 425 - 20 - 220, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        maleLabel.frame = CGRectMake(self.view.frame.size.width + 100, 495 - 20 - 235, 60, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        maleLabel.frame = CGRectMake(self.view.frame.size.width+120, 535 - 20 - 255, 60, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        maleLabel.frame = CGRectMake(self.view.frame.size.width+120, 535 - 20 - 255, 60, 41);
    } else {
        maleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        maleLabel.frame = CGRectMake(self.view.frame.size.width+120, 535 - 20 - 255, 60, 41);
    }
    maleLabel.text = NSLocalizedString(@"Male", nil);
    maleLabel.numberOfLines = 2;
    maleLabel.textAlignment = NSTextAlignmentCenter;
    [registerScroller addSubview:maleLabel];
    
    // Name Label
    UILabel *femaleLabel = [[UILabel alloc]init];
    femaleLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width+193, 325 - 20 - 130, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:8];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width+193, 425 - 20 - 220, 60, 41);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width + 218, 495 - 20 - 235, 60, 41);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width+235, 535 - 20 - 255, 60, 41);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width+235, 535 - 20 - 255, 60, 41);
    } else {
        femaleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:10];
        femaleLabel.frame = CGRectMake(self.view.frame.size.width+235, 535 - 20 - 255, 60, 41);
    }
    femaleLabel.text = NSLocalizedString(@"Female", nil);
    femaleLabel.numberOfLines = 2;
    femaleLabel.textAlignment = NSTextAlignmentCenter;
    [registerScroller addSubview:femaleLabel];
    
    
    /*
     Creation, positioning and adding of the UISwitch on the screen.
     */
    UISwitch *genderSwitch = [[UISwitch alloc] init];
    
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width + CGRectGetMidX(self.view.frame)-25, 331 - 20-130, 100, 60); //Position of the UISwitch
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width + CGRectGetMidX(self.view.frame)-25, 430 - 20 -220, 100, 60); //Position of the UISwitch
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width + CGRectGetMidX(self.view.frame)-25, 500 - 20 - 235, 100, 60); //Position of the UISwitch
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width+CGRectGetMidX(self.view.frame)-25, 537 - 20-255 , 100, 60); //Position of the UISwitch
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width+CGRectGetMidX(self.view.frame)-25, 537 - 20-255 , 100, 60); //Position of the UISwitch
    } else {
        genderSwitch.frame = CGRectMake(self.view.frame.size.width+CGRectGetMidX(self.view.frame)-25, 537 - 20-255 , 100, 60); //Position of the UISwitch
    }
    
    genderSwitch.onTintColor = [UIColor colorWithRed:0.305 green:0.305 blue:0.305 alpha:1.0];
    genderSwitch.tintColor = [UIColor colorWithRed:0.305 green:0.305 blue:0.305 alpha:1.0];
    genderSwitch.thumbTintColor = [UIColor colorWithRed:0.97 green:0.65 blue:0.19 alpha:1.0];
    [genderSwitch addTarget:self action:@selector(flipGender:) forControlEvents:UIControlEventValueChanged];
    [registerScroller addSubview:genderSwitch];
    isMale = TRUE;
    
    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        skipButton.frame = CGRectMake(40, self.view.frame.size.height-60, self.view.frame.size.width-80, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        skipButton.frame = CGRectMake(40, self.view.frame.size.height-50, self.view.frame.size.width-80, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        skipButton.frame = CGRectMake(self.view.frame.size.width + 90, 545 - 20 - 235, self.view.frame.size.width - 180, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        skipButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        skipButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    } else {
        skipButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    }
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [skipButton setBackgroundImage:[UIImage imageNamed:@"btn_skip_french"] forState:UIControlStateNormal];
    } else {
        [skipButton setBackgroundImage:[UIImage imageNamed:@"btn_skip"] forState:UIControlStateNormal];
    }
    [skipButton addTarget:self action:@selector(tapButtonSkipRegisterEmail:) forControlEvents:UIControlEventTouchUpInside];
    
    [registerScroller addSubview:skipButton];
}

-(void) addProfilePicStage {
    UILabel *addProfileLabel = [[UILabel alloc]init];
    addProfileLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:10];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:10];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:12];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
    } else {
        addProfileLabel.font = [UIFont fontWithName:@"Ethnocentric" size:15];
        addProfileLabel.frame = CGRectMake(self.view.frame.size.width, 10, self.view.frame.size.width, 20);
    }
    addProfileLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Personal Information", nil)];
    
    addProfileLabel.textAlignment = NSTextAlignmentCenter;
    [registerScroller addSubview:addProfileLabel];
    
    addProfileButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 50, 40, 100, 100);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 50, 40, 100, 100);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 60, 50, 120, 120);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 60, 50, 120, 120);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 60, 50, 120, 120);//Position of the button
    } else {
        addProfileButton.frame = CGRectMake(self.view.frame.size.width*1.5 - 60, 50, 120, 120);//Position of the button
    }
    [addProfileButton setBackgroundImage:[UIImage imageNamed:@"btn_add_2"] forState:UIControlStateNormal];
    
    [addProfileButton addTarget:self action:@selector(tapAddProfile:) forControlEvents:UIControlEventTouchUpInside];
    
    [registerScroller addSubview:addProfileButton];
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

#pragma mark Status Bar State
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
            HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            HUD.mode = MBProgressHUDModeCustomView;
            HUD.labelText = NSLocalizedString(@"No internet connection found", nil);
            HUD.labelFont = [UIFont fontWithName:@"ArialMT" size:14];
            HUD.detailsLabelText = NSLocalizedString(@"Please connect to Wi-Fi or your mobile internet.", nil);
            HUD.detailsLabelFont = [UIFont fontWithName:@"ArialMT" size:14];
            
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
            HUD.customView = activityImageView;
            
            [HUD hide:YES afterDelay:5];
            
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

#pragma mark  - Handling touches

-(void)popViewControllerWithAnimation{
    NSLog(@"Back");
    
    [Flurry logEvent:@"User Pressed Back Button to Login Page" timed:YES];
    
    SWRevealViewController *sideBar = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
    
    [self.navigationController popViewControllerAnimated:sideBar ];
}
-(IBAction)tapButtonSkipRegisterEmail:(id)sender
{
    /*UIButton *button = (UIButton *)sender;
     NSLog(@"Button: %ld", (long)[button tag]);
     
     //long pressedButton = (long)[button tag];
     
     //Custom Spinner
     HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
     HUD.mode = MBProgressHUDModeCustomView;
     HUD.labelText = @"Loading";//NSLocalizedString(@"Loading", nil);
     
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
     //    [pageScroller addSubview:activityImageView];
     
     // Add stuff to view here
     HUD.customView = activityImageView;
     
     if(currentStage == 0) {
     BOOL wrongEmail = [self validateEmail:email.text];
     
     //Checks if all fields have been completed
     if ([nameTextField.text isEqualToString:@""] || [email.text isEqualToString:@""] || [password.text isEqualToString:@""] || [confirmPassword.text isEqualToString:@""]) {
     [HUD removeFromSuperview];
     [self alertEmptyFields];
     }else {
     if (wrongEmail == false) { // Checks if the emails don't match
     [HUD removeFromSuperview];
     [self alertWrongEmail];
     } else {
     if (![password.text isEqualToString:confirmPassword.text]) {
     [HUD removeFromSuperview];
     [self alertWrongPassword];
     } else {
     emailString = email.text;
     passwordString = password.text;
     
     emailString = [emailString lowercaseString];
     email.text = emailString;
     
     [self CheckEmail];
     }
     }
     }
     } else {
     [self addUserToParse];
     }*/
    [self addUserToParse];
}
-(IBAction)tapButtonRegisterEmail:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSLog(@"Button: %ld", (long)[button tag]);
    
    //long pressedButton = (long)[button tag];
    
    //Custom Spinner
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = NSLocalizedString(@"Loading", nil);
    
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
    //    [pageScroller addSubview:activityImageView];
    
    // Add stuff to view here
    HUD.customView = activityImageView;
    
    if(currentStage == 0) {
        BOOL wrongEmail = [self validateEmail:email.text];
        
        //Checks if all fields have been completed
        if ([nameTextField.text isEqualToString:@""] || [email.text isEqualToString:@""] || [password.text isEqualToString:@""] || [confirmPassword.text isEqualToString:@""]) {
            [HUD removeFromSuperview];
            [self alertEmptyFields];
        }else {
            if (wrongEmail == false) { // Checks if the emails don't match
                [HUD removeFromSuperview];
                [self alertWrongEmail];
            } else {
                if (![password.text isEqualToString:confirmPassword.text]) {
                    [HUD removeFromSuperview];
                    [self alertWrongPassword];
                } else {
                    emailString = email.text;
                    passwordString = password.text;
                    
                    emailString = [emailString lowercaseString];
                    email.text = emailString;
                    
                    [self CheckEmail];
                }
            }
        }
    } else {
        if ([heightTextField1.text isEqualToString:@""] || [weightTextField.text isEqualToString:@""]) {
            [HUD removeFromSuperview];
            [self alertEmptyFields];
        } else {
            [self addUserToParse];
        }
        
    }
}
-(void)showLoading
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.labelText = NSLocalizedString(@"Loading", nil);;
    //Start the animation
    [activityImageView startAnimating];
    
    
    //Add your custom activity indicator to your current view
    // [theScrollView addSubview:activityImageView];
    HUD.customView = activityImageView;
}
/*-(IBAction)tapPopUpButton:(id)sender
 {
 UIButton *button = (UIButton *)sender;
 NSLog(@"Video: %ld", (long)[button tag]);
 if ([button tag] == 1) {
 
 SWRevealViewController *offersControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];
 
 [self.navigationController pushViewController:offersControl animated:NO];
 } else if ([button tag] == 2) {
 
 
 [Flurry logEvent:@"User Pressed My Offers Button" timed:YES];
 
 SWRevealViewController *offersControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MyOffers"];
 
 [self.navigationController pushViewController:offersControl animated:NO];
 } else if ([button tag] == 3) {
 
 SWRevealViewController *offersControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];
 
 [self.navigationController pushViewController:offersControl animated:NO];
 }
 }*/

-(void)tapBackButton{
    if(currentStage == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        currentStage--;
        [self moveStage:0];
    }
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
    
    //Get the size of the keyboard.
    //CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //Adjust the bottom content inset of the scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    theScrollView.contentInset = contentInsets;
    theScrollView.scrollIndicatorInsets = contentInsets;
    
    int distanceMovedScroll;
    if ([[UIScreen mainScreen] bounds].size.height == 480 || [[UIScreen mainScreen] bounds].size.height == 568)
    {
        distanceMovedScroll = keyboardSize.height - 100;
        
    } else {
        distanceMovedScroll = keyboardSize.height - 150;
    }
    //NSLog(@"---------%f------%f-------%f", self.view.frame.size.height,keyboardSize.height,lastTextField.frame.origin.y);
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        theScrollView.contentOffset = CGPointMake(0, distanceMovedScroll);
    } completion:NULL];
    /*//Scrolls the target text field into view.
     NSLog(@"---------%f------%f-------%f", self.view.frame.size.height,keyboardSize.height,lastTextField.frame.origin.y);
     if(self.view.frame.size.height - keyboardSize.height < lastTextField.frame.origin.y) {
     
     }
     /*NSLog(@"----------------123123123");
     CGRect aRect = self.view.frame;
     aRect.size.height -= (keyboardSize.height);
     if (!CGRectContainsPoint(aRect, lastTextField.frame.origin) ) {
     CGPoint scrollPoint = CGPointMake(0.0, lastTextField.frame.origin.y - (keyboardSize.height-15));
     //        background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/1.14, self.view.frame.size.width, self.view.frame.size.height);
     [[UIApplication sharedApplication] setStatusBarHidden:YES];
     [theScrollView setContentOffset:scrollPoint animated:YES];
     //[UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
     
     //} completion:NULL];
     NSLog(@"----------------123123123");
     
     }*/
}

//Handles how to hide the keyboard
- (void) keyboardWillHide:(NSNotification *)notification {
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    theScrollView.contentInset = contentInsets;
    theScrollView.scrollIndicatorInsets = contentInsets;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //    background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height);
}

// Set activeTextField to the current active textfield

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    lastTextField = textField;
}

// Set activeTextField to nil

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    lastTextField = textField;
}


// Dismiss the keyboard

- (IBAction)dismissKeyboard:(id)sender
{
    [lastTextField resignFirstResponder];
}

//validates the email with a regular expression
-(BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; //  return 0;
    return [emailTest evaluateWithObject:candidate];
}

- (void) alertWrongPassword{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"Password does not match!", nil)];
    [alertVC.alertView removeFromSuperview];

}

//Handles the alerts on empty fields
- (void) alertEmptyFields{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"All fields must be completed!", nil)];
    [alertVC.alertView removeFromSuperview];

}

//Handles missmatched email fields
- (void) alertWrongEmail{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"Not a valid email!", nil)];
    [alertVC.alertView removeFromSuperview];

}

- (void) alertUserExists{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):[NSString stringWithFormat:NSLocalizedString(@"The user: %@ already exists in the database!", nil),email.text]];
    [alertVC.alertView removeFromSuperview];
    
}

- (void)alertUserRegistrationSuccessfull{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        SWRevealViewController *registerControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];
        
        [self.navigationController pushViewController:registerControl animated:YES];
        
        //            LoginViewController *viewController = [[LoginViewController alloc] init];
        //            viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        //            [self presentViewController:viewController animated:YES completion:nil];
    });
    
    
}


#pragma mark - Actions
//Method that handles the age switch
-(IBAction)flipAge:(id)sender{
    
    if (_ageSwitch.on) {
        underage = NO;
        
    } else {
        underage = YES;
    }
}

-(IBAction)flipGender:(id)sender{
    
    if (_genderSwitch.on) {
        isMale = NO;
        
    } else {
        isMale = YES;
    }
}


#pragma mark - Parse Methods

-(void)CheckEmail{
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"email" equalTo:email.text];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        
        if (!error) {
            if(number > 0) {
                // The user already exists
                [HUD removeFromSuperview];
                [self alertUserExists];
            } else {
                [HUD removeFromSuperview];
                currentStage++;
                [self moveStage:self.view.frame.size.width];
                // No user exists with the email
                
                //Add User to Parse
            }
        } else {
            NSLog(@"%@",error.description);
        }
        
    }];
}
-(void) moveStage:(int) distance {
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        registerScroller.contentOffset = CGPointMake(distance, 0);
    } completion:NULL];
}
-(void) addUserToParse {
    // No user exists with the email
    [self showLoading];
    //Add User to Parse
    PFUser *user = [PFUser user];
    user.username = unameTextField.text;
    user.password = password.text;
    user.email = email.text;
    user[@"name"] = nameTextField.text;
    user[@"Hearts"] = @0;
    user[@"HomePark"] = @"NotSelected";
    user[@"TotalWeight"] = @0;
    user[@"height"] = [NSString stringWithFormat:@"%@ CMs",heightTextField1.text];
    user[@"bodyWeight"] = [NSString stringWithFormat:@"%@ kg", weightTextField.text];
    user[@"login"] = @"Email";
    user[@"TotalExercises"] = @0;
    user[@"TotalAchievements"] = @0;
    user[@"loss"] = @0;
    user[@"draw"] = @0;
    user[@"wins"] = @0;
    user[@"FavouriteExercises"] = [NSMutableArray array];
    user[@"FavouriteWorkouts"] = [NSMutableArray array];
    user[@"LastActive"] = [NSDate date];
    user[@"Description"] = NSLocalizedString(@"This is the default profile description, change this by pressing 'Edit' in the top right corner.", nil);
    user[@"Friends"] = [NSMutableArray array];
    user[@"notReferred"] = @YES;
    if(profilePictureData == nil) {
        user[@"profilePicture"] = @"NoPicture";
    } else {
        PFFile* tmp = [PFFile fileWithName:[NSString stringWithFormat:@"%@.jpg",unameTextField.text] data:profilePictureData];
        [user setObject:tmp forKey:@"uploadedProfilePicture"];
    }
    if (underage) {
        user[@"isOver18"] = @NO;
    } else {
        user[@"isOver18"] = @YES;
    }
    if(isMale) {
        user[@"isMale"] = @YES;
    } else {
        user[@"isMale"] = @NO;
    }
    
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Hooray! Let them use the app now.
            
            NSLog(@"User Created Successfully!");
            NSLog(@"Email: %@, --- Password: %@", email.text, password.text);
            [Flurry logEvent:@"User Registered a new email account" timed:YES];
            defaults = [NSUserDefaults standardUserDefaults];
            
            //                                            [defaults setObject:@"No" forKey:@"ShowLogin"];
            if(profilePictureData != nil) {
                PFFile *imageFile = [PFUser currentUser][@"uploadedProfilePicture"];
                
                [PFUser currentUser][@"profilePicture"] = imageFile.url;
            }
            [[PFUser currentUser]saveInBackground];
            
            PFObject *userAchie = [PFObject objectWithClassName:@"UserAchievements"];
            userAchie[@"AsianGuar"] = @NO;
            userAchie[@"AfricanElephant"] = @NO;
            userAchie[@"KodiakBear"] = @NO;
            userAchie[@"WhiteRhinoceros"] = @NO;
            userAchie[@"Crocodile"] = @NO;
            userAchie[@"Hippopotamus"] = @NO;
            userAchie[@"Giraffe"] = @NO;
            userAchie[@"AsianElephant"] = @NO;
            userAchie[@"WhaleShark"] = @NO;
            userAchie[@"LondonEye"] = @NO;
            userAchie[@"GreatWallOfChina"] = @NO;
            userAchie[@"EmpireStateBuilding"] = @NO;
            userAchie[@"BurjKhalifa"] = @NO;
            userAchie[@"GettingStarted"] = @NO;
            userAchie[@"GoldenGateBridge"] = @NO;
            userAchie[@"EiffelTower"] = @NO;
            userAchie[@"WorkingOut"] = @NO;
            userAchie[@"ProfilePerfect"] = @NO;
            userAchie[@"Socialize"] = @NO;
            userAchie[@"SocialBuzz"] = @NO;
            userAchie[@"ChallengeBegin"] = @NO;
            userAchie[@"Victorious"] = @NO;
            userAchie[@"WeeklyWorker"] = @NO;
            userAchie[@"Registration"] = @YES;
            userAchie[@"KeepingThePeace"] = @NO;
            userAchie[@"ProludicCopper"] = @NO;
            userAchie[@"ProludicBronze"] = @NO;
            userAchie[@"ProludicSilver"] = @NO;
            userAchie[@"ProludicGold"] = @NO;
            userAchie[@"ProludicPlatinum"] = @NO;
            userAchie[@"ProludicDiamond"] = @NO;
            userAchie[@"BodyweightCopper"] = @NO;
            userAchie[@"BodyweightBronze"] = @NO;
            userAchie[@"BodyweightSilver"] = @NO;
            userAchie[@"BodyweightGold"] = @NO;
            userAchie[@"BodyweightPlatinum"] = @NO;
            userAchie[@"BodyweightDiamond"] = @NO;
            userAchie[@"User"] = [PFUser currentUser];
            [userAchie saveInBackground];
            
            SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
            [self.navigationController pushViewController:profileControl animated:YES];
            [HUD removeFromSuperview];
        } else {
            NSString *errorString = [error userInfo][@"error"];
            // Show the errorString somewhere and let the user try again.
            NSLog(@"%@",errorString);
            
            [Flurry logError:@"Email Account Creation Error" message:errorString error:error];
            
            [HUD removeFromSuperview];
            
            alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                               message:errorString
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            [alert show];
        }
    }];
}
#pragma mark - Pop Up Handler

-(void)showPopUpPoints{
    
    //    [Flurry logEvent:@"User Got 1000 Points Registering by Facebook" timed:YES];
    
    
    homeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:homeView];
    
    // Create the UI Scroll View
    popUpScroller = [[UIScrollView alloc] init];
    
    popUpScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    popUpScroller.bounces = NO;
    
    [self.view addSubview:popUpScroller];
    popUpScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    
    pictureOverlay = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    pictureOverlay.image = [UIImage imageNamed:@"emailRegisterPointsBackground"];
    
    [popUpScroller addSubview:pictureOverlay];
    
    //Offers Button
    
    UIButton *offersButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        offersButton.frame = CGRectMake(30, 278, 125, 23);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        offersButton.frame = CGRectMake(30, 329, 125, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        offersButton.frame = CGRectMake(35, 387, 146, 32);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        offersButton.frame = CGRectMake(40, 427, 160, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        offersButton.frame = CGRectMake(40, 427, 160, 35);
    } else {
        offersButton.frame = CGRectMake(40, 427, 160, 35);
    }
    offersButton.tag = 2;
    //    [backButton setBackgroundImage:backImage.image forState:UIControlStateNormal];
    [offersButton setBackgroundColor:[[UIColor purpleColor] colorWithAlphaComponent:0.0f]];
    //    [offersButton addTarget:self action:@selector(tapPopUpButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [popUpScroller addSubview:offersButton];
    
    //Done Button
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        doneButton.frame = CGRectMake(165, 278, 125, 23);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        doneButton.frame = CGRectMake(165, 329, 125, 28);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        doneButton.frame = CGRectMake(194, 387, 146, 32);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        doneButton.frame = CGRectMake(213, 427, 160, 35);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        doneButton.frame = CGRectMake(213, 427, 160, 35);
    } else {
        doneButton.frame = CGRectMake(213, 427, 160, 35);
    }
    doneButton.tag = 1;
    //    [nextButton setBackgroundImage:nextButtonImage.image forState:UIControlStateNormal];
    [doneButton setBackgroundColor:[[UIColor purpleColor] colorWithAlphaComponent:0.0f]];
    [doneButton addTarget:self action:@selector(alertUserRegistrationSuccessfull) forControlEvents:UIControlEventTouchUpInside];
    
    [popUpScroller addSubview:doneButton];
    
    
}

-(void)showViewAnimation:(UIView *)aView {
    
    CATransition *transition = [CATransition animation];
    transition.type =kCATransitionFade;
    transition.duration = 0.2f;
    transition.delegate = self;
    [aView.layer addAnimation:transition forKey:nil];
}
-(IBAction)tapAddProfile: (id)sender{
    
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Change profile", nil)
                                 message:NSLocalizedString(@"Upload your Profile Picture", nil)
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
    
    //Picture Overlay
    
    UIImageView *settingsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    settingsImageView.image = [UIImage imageNamed:@"changeProfilePictureBG"];
    settingsImageView.contentMode = UIViewContentModeScaleAspectFit;
    settingsImageView.clipsToBounds = YES;
    settingsImageView.center = self.view.center;
    
    [popUpView addSubview:settingsImageView];
    
    //Title Label
    UILabel *titleLabel = [[UILabel alloc]init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 120, 135, 240, 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 120, 180, 240, 40);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 215, 320, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 240, 320, 40);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:32];
        titleLabel.frame = CGRectMake((popUpView.frame.size.width / 2) - 160, 240, 320, 40);
    } else {
        titleLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:32];
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
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"btn_cancel"] forState:UIControlStateNormal];
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
    [retakePictureButton setBackgroundImage:[UIImage imageNamed:@"btn_retake"] forState:UIControlStateNormal];
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
    [confirmPictureButton setBackgroundImage:[UIImage imageNamed:@"btn_confirm"] forState:UIControlStateNormal];
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
    
    
    NSData *imageData = UIImageJPEGRepresentation(selectedProfileImage, 0.0);
    UIImage *compressedJPGImage = [UIImage imageWithData:imageData];
    
    NSData* data = UIImageJPEGRepresentation(compressedJPGImage,0.0);
    imageData = UIImageJPEGRepresentation(compressedJPGImage,0.0);
    
    profilePictureData = data;
    [addProfileButton setBackgroundImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
    [popUpView removeFromSuperview];
    
    /*[[PFUser currentUser] setObject:imageFile forKey:@"uploadedProfilePicture"];
     
     [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
     if (!error) {
     NSLog(@"Picture Changed!");
     
     PFFile *imageFile = [PFUser currentUser][@"uploadedProfilePicture"];
     
     [PFUser currentUser][@"profilePicture"] = imageFile.url;
     
     [[PFUser currentUser]saveInBackground];
     
     self.navigationController.navigationBar.alpha = 1;
     
     self.navigationController.navigationBarHidden = NO;
     [popUpView removeFromSuperview];
     
     
     
     userIsOnOverlay = NO;
     
     } else {
     NSLog(@"%@",error.description);
     
     self.navigationController.navigationBar.alpha = 1;
     
     self.navigationController.navigationBarHidden = NO;
     
     
     }
     }];*/
    
}

-(void)tapcloseProfilePicButton{
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.navigationBarHidden = NO;
    userIsOnOverlay = NO;
    
    [popUpView removeFromSuperview];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(textField == weightTextField || textField == heightTextField1 || textField == heightTextField2)
    {
        NSCharacterSet* numberCharSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        for (int i = 0; i < [string length]; ++i)
        {
            unichar c = [string characterAtIndex:i];
            if (![numberCharSet characterIsMember:c])
            {
                return NO;
            }
        }
        return YES;
    } else {
        return YES;
    }
}
-(void) viewWillAppear:(BOOL)animated {
    if(currentStage == 1) {
        [self moveStage:self.view.frame.size.width];
    }
}

@end
