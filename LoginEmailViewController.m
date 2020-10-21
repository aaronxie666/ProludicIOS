//
//  LoginEmailViewController.m
//  KnowFootball
//
//  Created by Dan Meza on 03/02/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import "LoginEmailViewController.h"
#import "SWRevealViewController.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "DashboardViewController.h"
#import <Parse/Parse.h>
#import "Flurry.h"

@interface LoginEmailViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation LoginEmailViewController{
    MBProgressHUD *HUD;//Loading Screen Implementation
    UIImageView *activityImageView;
    IBOutlet UITextField *email;
    IBOutlet UITextField *password;
    UIAlertView *alert;
    UIScrollView *theScrollView;
    NSString *emailString;
    NSString *passwordString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [Flurry logEvent:@"User Opened Login Email Page" timed:YES];
    NSLog(@"LOGIN EMAIL VC");
    theScrollView = [[UIScrollView alloc] init];
    theScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the button
    theScrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    //Reachability (Checking Internet Connection)
    
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
    
    //BackgroundImage
    UIImageView *background = [[UIImageView alloc] init];
    background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    background.image = [UIImage imageNamed:@"BG"];
    [theScrollView addSubview:background];
    
    //Implements custom back button
    UIButton *backToLoginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        backToLoginButton.frame = CGRectMake(10, 10, 80, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        backToLoginButton.frame = CGRectMake(10, 20, 80, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        backToLoginButton.frame = CGRectMake(10, 30, 100, 40);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        backToLoginButton.frame = CGRectMake(10, 40, 100, 40);//Position of the button
    } else {
        backToLoginButton.frame = CGRectMake(10, 40, 100, 40);//Position of the button
    }
    [backToLoginButton setBackgroundImage:[UIImage imageNamed:@"Back_arrowButton"] forState:UIControlStateNormal];
    [backToLoginButton addTarget:self action:@selector(tapBackButton) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:backToLoginButton];
    
    //Submit Button
    
    UIButton *resetEmailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        resetEmailButton.frame = CGRectMake(25, self.view.frame.size.height-60, 120, 30); //Position of the button
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        resetEmailButton.frame = CGRectMake(25, self.view.frame.size.height-80, 120, 30);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        resetEmailButton.frame = CGRectMake(28, self.view.frame.size.height-100, 160, 40);//Position of the button
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        resetEmailButton.frame = CGRectMake(30, self.view.frame.size.height-100, 160, 40);//Position of the button
    } else {
        resetEmailButton.frame = CGRectMake(30, self.view.frame.size.height-100, 160, 40);//Position of the button
    }
    
    resetEmailButton.tag = 2;
    [resetEmailButton setBackgroundImage:[UIImage imageNamed:@"forgotPasswordButton"] forState:UIControlStateNormal];
    [resetEmailButton addTarget:self action:@selector(tapButtonLoginEmail:) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:resetEmailButton];
    
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
    } else {
        submitButton.frame = CGRectMake(70, self.view.frame.size.height-80, self.view.frame.size.width-140, 40);//Position of the button
    }
    submitButton.tag = 1;
    [submitButton setBackgroundImage:[UIImage imageNamed:@"Login_email_button"] forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(tapButtonLoginEmail:) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:submitButton];
    
    //Icon Background
    
    UIImageView *iconBackground = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        iconBackground.frame = CGRectMake(30, 5, self.view.frame.size.width-60, 220);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        iconBackground.frame = CGRectMake(30, 25, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        iconBackground.frame = CGRectMake(30, 50, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        iconBackground.frame = CGRectMake(30, 50, self.view.frame.size.width-60, 300);//Position of the button
    } else {
        iconBackground.frame = CGRectMake(30, 50, self.view.frame.size.width-60, 300);//Position of the button
    }
    iconBackground.image = [UIImage imageNamed:@"KFlogo"];
    iconBackground.contentMode = UIViewContentModeScaleAspectFit;
    iconBackground.clipsToBounds = YES;
    [theScrollView addSubview:iconBackground];
    
    //Email
    UIColor *color = [UIColor whiteColor];
    email = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        email.frame = CGRectMake(40, 265, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        email.frame = CGRectMake(40, 348, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        email.frame = CGRectMake(50, 403, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        email.frame = CGRectMake(70, 416, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        email.frame = CGRectMake(70, 416, self.view.frame.size.width-140, 36); //Position of the Textfield
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
    email.layer.masksToBounds = YES;
    email.clearButtonMode = UITextFieldViewModeWhileEditing;
    email.returnKeyType = UIReturnKeyDone;
    email.autocorrectionType = UITextAutocorrectionTypeNo;
    if ([email respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        
        email.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"EMAIL" attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:16.0]}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    email.keyboardType = UIKeyboardAppearanceDark;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    email.clipsToBounds = YES;
    email.returnKeyType = UIReturnKeyDone;
    email.keyboardType = UIKeyboardTypeEmailAddress;
    [email setDelegate:self];
    email.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
    [theScrollView addSubview:email];
    
    //Password
    
    password = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        password.frame = CGRectMake(40, 300, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        password.frame = CGRectMake(40, 386, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        password.frame = CGRectMake(50, 446, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        password.frame = CGRectMake(70, 462, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        password.frame = CGRectMake(70, 462, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    password.textAlignment = NSTextAlignmentLeft;
    password.textColor = [UIColor blackColor];
    password.backgroundColor = [UIColor whiteColor];
    CALayer *borderPassword = [CALayer layer];
    CGFloat borderWidthPassword = 1;
    borderPassword.borderColor = [UIColor darkGrayColor].CGColor;
    borderPassword.frame = CGRectMake(0, email.frame.size.height - borderWidthPassword, email.frame.size.width, email.frame.size.height);
    borderPassword.borderWidth = borderWidthPassword;
    [password.layer addSublayer:borderPassword];
    password.layer.masksToBounds = YES;
    password.clearButtonMode = UITextFieldViewModeWhileEditing;
    password.returnKeyType = UIReturnKeyDone;
    if ([password respondsToSelector:@selector(setAttributedPlaceholder:)]) {
        password.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Password", nil) attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:16.0]}];
    } else {
        NSLog(@"Cannot set placeholder text's color, because deployment target is earlier than iOS 6.0");
    }
    password.keyboardType = UIKeyboardAppearanceDark;
    password.clipsToBounds = YES;
    password.secureTextEntry = YES;
    [password setDelegate:self];
    password.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
    [theScrollView addSubview:password];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self.view addSubview:theScrollView];
}

-(IBAction)forgetpassword:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        
        MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
        NSString *mailBody = @"your Message";
        
        
        [mailComposeViewController setMessageBody:mailBody isHTML:NO];
        mailComposeViewController.mailComposeDelegate = self;
        [self presentViewController:mailComposeViewController animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"e-Mail Sending Alert"
                                                        message:@"You can't send mail"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - MFMessage Delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        NSLog(@"\n\n Email Sent");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark Handling touches

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *textfield =  [alertView textFieldAtIndex: 0];
    
    NSLog(@"%@",textfield.text);
    
    if (buttonIndex == 0)
    {
        //Code for Cancel button
        [Flurry logEvent:@"User tapped the cancel button in reset password" timed:YES];
    }
    if (buttonIndex == 1)
    {
        
        BOOL wrongEmail = [self validateEmail:textfield.text];
        
        if (!wrongEmail) {
            [self alertWrongEmail];
        } else {
            //Code for Ok button
            PFQuery *query = [PFUser query];
            //reference the local text field here
            [query whereKey:@"email" equalTo:textfield.text];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                
                if (!error) {
                    // The find succeeded.
                    if (objects.count > 0) {
                        //the query found a user that matched the email provided in the text field, send the email
                        
                        [Flurry logEvent:@"User reset password" timed:YES];
                        
                        [PFUser requestPasswordResetForEmailInBackground:textfield.text];
                        
                        UIAlertView *alertError = [[UIAlertView alloc] initWithTitle:@"Email Password."
                                                                             message:@"The email has been sent!."
                                                                            delegate:self
                                                                   cancelButtonTitle:@"OK"
                                                                   otherButtonTitles:nil];
                        [alertError show];
                        
                    } else {
                        
                        //the query was successful, but found 0 results
                        //email does not exist in the database, dont send the email
                        //show your alert view here
                        
                        [Flurry logEvent:@"User entered wrong email to reset password" timed:YES];
                        
                        UIAlertView *alertError = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                             message:@"Email does not exist in the database."
                                                                            delegate:self
                                                                   cancelButtonTitle:@"OK"
                                                                   otherButtonTitles:nil];
                        [alertError show];
                    }
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    
                    [Flurry logError:@"Reset Password Error" message:error.description error:error];
                }
            }];
        }
    }
}

-(IBAction)tapButtonLoginEmail:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSLog(@"Button: %ld", (long)[button tag]);
    
    long buttonTapped = (long)[button tag];
    
    if (buttonTapped == 1) {
        //Custom Spinner
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.labelText = @"Loading";
        
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
        
        [Flurry logEvent:@"User tapped the submit login button" timed:YES];
        
        BOOL wrongEmail = [self validateEmail:email.text];
        
        //Checks if all fields have been completed
        if ([email.text isEqualToString:@""] || [password.text isEqualToString:@""]) {
            [HUD removeFromSuperview];
            [self alertEmptyFields];
        }else {
            if (wrongEmail == false) { // Checks if the emails don't match
                [HUD removeFromSuperview];
                [self alertWrongEmail];
            } else {
                if ([password.text isEqualToString: @""]) {
                    [self alertEmptyFields];
                } else{
                    emailString = email.text;
                    passwordString = password.text;
                    
                    emailString = [emailString lowercaseString];
                    email.text = emailString;
                    
                    [self CheckDetails];
                }
            }
        }
    } else if (buttonTapped == 2) {
        //reset password popup
        
        [Flurry logEvent:@"User tapped the forgot password button" timed:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Address" message:@"Enter the email for your account:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil]; alertView.alertViewStyle = UIAlertViewStylePlainTextInput; [alertView show];
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
    
    
    //Scrolls the target text field into view.
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(aRect, password.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, password.frame.origin.y - (keyboardSize.height-15));
        //        background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/1.14, self.view.frame.size.width, self.view.frame.size.height);
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [theScrollView setContentOffset:scrollPoint animated:YES];
        
    }
}

//Handles how to hide the keyboard
- (void) keyboardWillHide:(NSNotification *)notification {
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    theScrollView.contentInset = contentInsets;
    theScrollView.scrollIndicatorInsets = contentInsets;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    //    background.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
}

// Set activeTextField to the current active textfield

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    password = textField;
}

// Set activeTextField to nil

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    password = textField;
}


// Dismiss the keyboard

- (IBAction)dismissKeyboard:(id)sender
{
    [password resignFirstResponder];
}

//validates the email with a regular expression
-(BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; //  return 0;
    return [emailTest evaluateWithObject:candidate];
}

//Handles the alerts on empty fields
- (void) alertEmptyFields{
    
    alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                       message:@"All fields must be completed!"
                                      delegate:self
                             cancelButtonTitle:@"Ok"
                             otherButtonTitles:nil];
    [alert show];
}

//Handles missmatched email fields
- (void) alertWrongEmail{
    
    alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                       message:@"Not a valid email!"
                                      delegate:self
                             cancelButtonTitle:@"Ok"
                             otherButtonTitles:nil];
    [alert show];
}

- (void) alertUserLoginSuccessfull{
    
    alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                       message:[NSString stringWithFormat:@"The user: %@ has been added to the database!",email.text]
                                      delegate:self
                             cancelButtonTitle:@"Ok"
                             otherButtonTitles:nil];
    [alert show];
    
    
}

- (void) alertUserDoesNotExist{
    
    alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                       message:[NSString stringWithFormat:@"Email %@ or password is incorrect!",email.text]
                                      delegate:self
                             cancelButtonTitle:@"Ok"
                             otherButtonTitles:nil];
    [alert show];
    
}

#pragma mark - Parse Methods

-(void)CheckDetails{
    
    [PFUser logOut];
    PFQuery *query = [PFUser query];
    [query whereKey:@"email" equalTo:email.text];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * object, NSError *  error) {
        
        if(!error) {
            // The user already exists
            
            [PFUser logInWithUsernameInBackground:email.text password:password.text
                                            block:^(PFUser *user, NSError *error) {
                                                if (user) {
                                                    // Do stuff after successful login.
                                                    NSLog(@"Logged In!");
                                                    
                                                    [Flurry logEvent:@"User logged in via email" timed:YES];
                                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                    
                                                    //                                                    [defaults setObject:@"No" forKey:@"ShowLogin"];
                                                    
                                                    [HUD removeFromSuperview];
                                                    
                                                    [defaults setObject:email.text forKey:@"userEmail"];
                                                    [defaults setObject:password.text forKey:@"userPassword"];
                                                    
                                                    self.navigationController.navigationBar.alpha = 1;
                                                    self.navigationController.navigationBar.hidden = NO;
                                                    [HUD removeFromSuperview];
                                                    
                                                    SWRevealViewController *offersControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                    
                                                    [self.navigationController pushViewController:offersControl animated:NO];
                                                    
                                                } else {
                                                    // The login failed. Check error to see why.
                                                    NSLog(@"%@",[error userInfo][@"error"]);
                                                    [HUD removeFromSuperview];
                                                    
                                                    alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                                       message:[NSString stringWithFormat:@"Email %@ or password is incorrect!",email.text]
                                                                                      delegate:self
                                                                             cancelButtonTitle:@"Ok"
                                                                             otherButtonTitles:nil];
                                                    [alert show];
                                                }
                                            }];
            
        } else {
            // No user exists with the email
            [HUD removeFromSuperview];
            [self alertUserDoesNotExist];
        }
    }];
}

-(void)tapBackButton{
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
