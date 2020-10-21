//
//  InitialLoginViewController.m
//  KnowFootball
//
//  Created by Dan Meza on 16/02/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import "InitialLoginViewController.h"
#import "SWRevealViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <Parse/Parse.h>
#import "Reachability.h"
#import "MBProgressHUD.h"
#import "Flurry.h"
#import "CustomAlert.h"

@interface InitialLoginViewController ()
//Reachability
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation InitialLoginViewController{
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    IBOutlet UITextField *email;
    IBOutlet UITextField *password;
    UIAlertView *alert;
    UIScrollView *theScrollView;
    NSString *emailString;
    NSString *passwordString;
    MPMoviePlayerController *movieController;
    BOOL isPlayingVideo;
    int failedLogin;
    UIButton *forgotPasswordButton;
    
    CustomAlert *alertVC;
}

- (void)viewDidLoad {
    
    [Flurry logEvent:@"User Opened Login Page" timed:YES];
    
    //Log out from all accounts and delete cookies.
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    [FBSDKAccessToken setCurrentAccessToken:nil];
    [[FBSDKLoginManager new] logOut];
    [[PFInstallation currentInstallation] removeObjectForKey:@"user"];
    [[PFInstallation currentInstallation] removeObjectForKey:@"userId"];
    [[PFInstallation currentInstallation] saveInBackground];
    [PFUser logOut];
    theScrollView = [[UIScrollView alloc] init];
    theScrollView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the button
    theScrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
    //Reachability (Checking Internet Connection)
    //Delete local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    failedLogin = 0;
    
    [_sidebarButton setEnabled:NO];
    self.navigationController.navigationBarHidden = YES;
    
    UIImage *tmpImg = [UIImage imageNamed:@"BG"];
    UIImageView *tmpImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, tmpImg.size.width, tmpImg.size.height)];
    tmpImgView.image = tmpImg;
    
    [self.view addSubview:tmpImgView];
    
    //Icon Background
    
    UIImageView *iconBackground = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        iconBackground.frame = CGRectMake(30, 20, self.view.frame.size.width-60, 300);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        iconBackground.frame = CGRectMake(30, 30, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        iconBackground.frame = CGRectMake(30, 100 - 70, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        iconBackground.frame = CGRectMake(30, 100, self.view.frame.size.width-60, 300);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        iconBackground.frame = CGRectMake(30, 100, self.view.frame.size.width-60, 300);
    } else {
        iconBackground.frame = CGRectMake(30, 100, self.view.frame.size.width-60, 300);
    }
    iconBackground.image = [UIImage imageNamed:@"ProludicLogo.jpg"];
    iconBackground.contentMode = UIViewContentModeScaleAspectFit;
    iconBackground.clipsToBounds = YES;
    [theScrollView addSubview:iconBackground];
    
    
    //Email
    UIColor *color = [UIColor whiteColor];
    email = [ [UITextField alloc ] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        email.frame = CGRectMake(40, 245, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        email.frame = CGRectMake(40, 265, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        email.frame = CGRectMake(50, 315, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        email.frame = CGRectMake(70, 355, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        email.frame = CGRectMake(70, 355, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        email.frame = CGRectMake(70, 355, self.view.frame.size.width-140, 36); //Position of the Textfield
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
        
        email.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:16.0]}];
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
        password.frame = CGRectMake(40, 280, self.view.frame.size.width-80, 25); //Position of the Textfield
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        password.frame = CGRectMake(40, 300, self.view.frame.size.width-80, 28); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        password.frame = CGRectMake(50, 350, self.view.frame.size.width-100, 33); //Position of the Textfield
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        password.frame = CGRectMake(70, 400, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        password.frame = CGRectMake(70, 400, self.view.frame.size.width-140, 36); //Position of the Textfield
    } else {
        password.frame = CGRectMake(70, 400, self.view.frame.size.width-140, 36); //Position of the Textfield
    }
    password.textAlignment = NSTextAlignmentLeft;
    password.textColor = [UIColor blackColor];
    password.backgroundColor = [UIColor whiteColor];
    CALayer *borderPassword = [CALayer layer];
    CGFloat borderWidthPassword = 1;
    borderPassword.borderColor = [UIColor darkGrayColor].CGColor;
    borderPassword.frame = CGRectMake(0, password.frame.size.height - borderWidthPassword, password.frame.size.width, password.frame.size.height);
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
    
    

    
    
    //Facebook Login Button
    
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if([language containsString:@"fr"]) {
        [loginButton setBackgroundImage:[UIImage imageNamed:@"btn_fb_french"] forState:UIControlStateNormal];
    } else {
        [loginButton setBackgroundImage:[UIImage imageNamed:@"FBLogin"] forState:UIControlStateNormal];
    }
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+125, self.view.frame.size.width-60, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+120, self.view.frame.size.width-60, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+145, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+160, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+160, self.view.frame.size.width-60, 40);//Position of the button
    } else {
        loginButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+160, self.view.frame.size.width-60, 40);//Position of the button
    }
    [loginButton
     addTarget:self
     action:@selector(loginFBButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:loginButton];
    
    
    /*
    UIButton *loginInstaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [loginInstaButton setBackgroundImage:[UIImage imageNamed:@"btn_insta"] forState:UIControlStateNormal];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        loginInstaButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+162, self.view.frame.size.width-60, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        loginInstaButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+165, self.view.frame.size.width-60, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        loginInstaButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+199, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        loginInstaButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+220, self.view.frame.size.width-60, 40);//Position of the button
    }
    [loginInstaButton
     addTarget:self
     action:@selector(loginInstaButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:loginInstaButton];
    */
    
    //Email Registration Button
    UIButton *RegisterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+162, self.view.frame.size.width-60, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+165, self.view.frame.size.width-60, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+199, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+220, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+220, self.view.frame.size.width-60, 40);//Position of the button
    } else {
        RegisterButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+220, self.view.frame.size.width-60, 40);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [RegisterButton setBackgroundImage:[UIImage imageNamed:@"btn_register_french"] forState:UIControlStateNormal];
    } else {
        [RegisterButton setBackgroundImage:[UIImage imageNamed:@"Reg_emailButton"] forState:UIControlStateNormal];
    }
    [RegisterButton addTarget:self action:@selector(tapEmailRegisterButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [theScrollView addSubview:RegisterButton];

    
    //Email Login Button
    
    UIButton *loginEmailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+90, self.view.frame.size.width-60, 30);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+80, self.view.frame.size.width-60, 30);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+90, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+100, self.view.frame.size.width-60, 40);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+100, self.view.frame.size.width-60, 40);//Position of the button
    } else {
        loginEmailButton.frame = CGRectMake(30, (self.view.frame.size.height/2)+100, self.view.frame.size.width-60, 40);//Position of the button
    }
    if([language containsString:@"fr"]) {
        [loginEmailButton setBackgroundImage:[UIImage imageNamed:@"btn_login_french"] forState:UIControlStateNormal];
    } else {
        [loginEmailButton setBackgroundImage:[UIImage imageNamed:@"Login_emailButton"] forState:UIControlStateNormal];
    }
    
    [loginEmailButton addTarget:self action:@selector(tapEmailLoginButton:) forControlEvents:UIControlEventTouchUpInside];
    [theScrollView addSubview:loginEmailButton];
    
    forgotPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+220, 150, 15);//Position of the button
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)//iPhone 5 size
    {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+225, 150, 15);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 667)//iPhone 6 size
    {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+ 250, 150, 15);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+270, 150, 15);//Position of the button
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+270, 150, 15);//Position of the button
    } else {
        forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width-180, (self.view.frame.size.height/2)+270, 150, 15);//Position of the button
    }
    [forgotPasswordButton setTitle:NSLocalizedString(@"Forgot Password?", nil) forState:UIControlStateNormal];
    [forgotPasswordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    forgotPasswordButton.titleLabel.textAlignment = NSTextAlignmentRight;
    forgotPasswordButton.backgroundColor = [UIColor clearColor];
    forgotPasswordButton.font = [UIFont fontWithName:@"OpenSans" size:12];
    [forgotPasswordButton addTarget:self action:@selector(tapForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    [theScrollView addSubview:forgotPasswordButton];
    
    [self.view addSubview:theScrollView];
    //    self.navigationController.navigationBar.hidden = YES;
    //    self.navigationController.navigationBar.alpha = 0;
    //Database
    if([[DBManager getSharedInstance]createDB]) {
        PFQuery *videoQuery = [PFQuery queryWithClassName:@"Extras"];
        [videoQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if(!error) {
                
                NSString *URLString = [NSString stringWithFormat:@"%@", object[@"IntroductionVideo"]];

                NSURL *url = [NSURL URLWithString:URLString];
                NSLog(@"---------------------- %@", url);
                movieController = [[MPMoviePlayerController alloc] initWithContentURL:url];
                [movieController.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                movieController.view.frame = self.view.bounds;
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:movieController];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(playbackStateChanged:)
                                                             name:MPMoviePlayerPlaybackStateDidChangeNotification object:movieController];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(doneButtonClick:)
                                                             name:MPMoviePlayerDidExitFullscreenNotification
                                                           object:nil];
                //[movieController prepareToPlay];
                [movieController setFullscreen:YES animated:YES];
                movieController.view.userInteractionEnabled = YES;
                theScrollView.userInteractionEnabled = NO;
                [self.view addSubview:movieController.view];
                isPlayingVideo = TRUE;
                [movieController play];
                
            } else {
                
            }
            
        }];

    }
}
-(void)doneButtonClick:(NSNotification*)aNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerDidExitFullscreenNotification
                                                  object:nil];
    
    //NSLog(@"User pressed done");
    [movieController stop];
    [movieController.view removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void)loginInstaButtonClicked
{
    SWRevealViewController *instagramLoginControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Instagram"];

    [self.navigationController pushViewController:instagramLoginControl animated:YES];
}
-(IBAction)tapForgotPassword:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reset Password", nil)
                                                                   message:NSLocalizedString(@"Add email to reset your password", nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Send Request", nil) style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              alert.textFields[0].text;
                                                              NSLog(@"%@", alert.textFields[0].text);
                                                              NSString *email = alert.textFields[0].text;
                                                              
                                                              if ([email isEqualToString:@""]) {
                                                                  
                                                                  alertVC = [[CustomAlert alloc] init];
                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):NSLocalizedString(@"Please add your email!", nil)];
                                                                  [alertVC.alertView removeFromSuperview];
                                                                  
                                                              }
                                                              else {
                                                                  PFQuery *query = [PFUser query];
                                                                  [query whereKey:@"email" equalTo:email];
                                                                  [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                                                      if (!object || ![object[@"login"] isEqualToString:@"Email"]) {
                                                                          
                                                                          alertVC = [[CustomAlert alloc] init];
                                                                          [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):@"Error encountered while retrieving your information!"];
                                                                          [alertVC.alertView removeFromSuperview];
                                                                          
                                                                      } else {
                                                                          // The find succeeded.
                                                                          [PFUser requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
                                                                              if(succeeded) {
                                                                                  
                                                                                  alertVC = [[CustomAlert alloc] init];
                                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):NSLocalizedString(@"The reset password has been sent to your email!", nil)];
                                                                                  [alertVC.alertView removeFromSuperview];
                                                                                  
                                                                              } else {
                                                                                  
                                                                                  alertVC = [[CustomAlert alloc] init];
                                                                                  [alertVC loadSingle:self.view:NSLocalizedString(@"Error!", nil):@"Error encountered while retrieving your information!"];
                                                                                  [alertVC.alertView removeFromSuperview];
                                                                              }
                                                                          }];
                                                                      }
                                                                  }];
                                                                  
                                                                  
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
-(void)loginFBButtonClicked
{
    
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
    [self.view addSubview:activityImageView];
    
    // Add stuff to view here
    Hud.customView = activityImageView;
    
    //Facebook Login Manager
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile", @"email", @"user_friends"]
     fromViewController:self
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             NSLog(@"Process error");
             
             [Hud removeFromSuperview];
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
             
             [Hud removeFromSuperview];
         } else {
             NSLog(@"Logged in");
             [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"name, first_name, last_name, picture, email, friends, friendlists, gender"}]
              startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                  
                  if (!error) {
                      NSLog(@"fetched user:%@", result);
                      NSLog(@"fetched user:%@", result[@"name"]);
                      NSLog(@"fetched user:%@", result[@"email"]);
                      NSLog(@"fetched user:%@", result[@"first_name"]);
                      NSLog(@"fetched user:%@", result[@"gender"]);
                      NSLog(@"fetched user:%@", result[@"id"]);
                      NSLog(@"fetched user:%@", result[@"last_name"]);
                      NSLog(@"fetched user:%@", result[@"link"]);
                      NSLog(@"fetched user:%@", result[@"timezone"]);
                      NSLog(@"fetched user:%@", result[@"updated_time"]);
                      NSLog(@"fetched user:%@", result[@"verified"]);
                      
                      //Add User to Parse
                      PFUser *user = [PFUser user];
                      user.username = result[@"name"];
                      user.password = result[@"id"];
                      user.email = result[@"email"];
                      user[@"name"] = [NSString stringWithFormat:@"%@ %@",result[@"first_name"], result[@"last_name"]];
                      user[@"facebookID"] = result[@"id"];
                      NSString *gender = [NSString stringWithFormat:@"%@",result[@"gender"]];
                      if([gender isEqualToString:@"male"]) {
                          user[@"isMale"] = @(YES);
                      } else {
                          user[@"isMale"] = @(NO);
                      }
                      //user[@"profilePicture"] = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                      user[@"Hearts"] = @0;
                      user[@"HomePark"] = @"NotSelected";
                      user[@"TotalWeight"] = @0;
                      user[@"login"] = @"Facebook";
                      user[@"TotalExercises"] = @0;
                      user[@"TotalAchievements"] = @0;
                      user[@"FavouriteExercises"] = [NSMutableArray array];
                      user[@"FavouriteWorkouts"] = [NSMutableArray array];
                      user[@"LastActive"] = [NSDate date];
                      user[@"Description"] = @"This is the default profile description, change this by pressing 'Edit' in the top right corner.";
                      user[@"Friends"] = [NSMutableArray array];
                      user[@"loss"] = @0;
                      user[@"draw"] = @0;
                      user[@"wins"] = @0;
                      
                      [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                          if (!error) {
                              // Hooray! Let them use the app now.
                              NSLog(@"User Created Successfully! -----------------------------------------");
                              [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=age_range" parameters:nil]
                               startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                   
                                   if (!error) {
                                       
                                       //                                       pointsTitle =  @"You just registered via Facebook and earned yourself:";
                                       //                                       pointsNSString = @"1000";
                                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                       [defaults setObject:result[@"id"] forKey:@"userEmail"];
                                       [defaults setObject:result[@"id"] forKey:@"userPassword"];
                                       
                                       NSLog(@"fetched user age range: %@", result);
                                       NSDictionary *ageRangeDict = [result objectForKey:@"age_range"];
                                       
                                       NSString *ageRange = [NSString stringWithFormat:@"%@-%@",
                                                             [ageRangeDict objectForKey:@"min"],
                                                             [ageRangeDict objectForKey:@"max"]];
                                       NSLog(@"Age Range: %@",ageRange);
                                       
                                       int age = [[ageRangeDict objectForKey:@"min"] intValue];
                                       
                                       if (age > 17) {
                                           [[PFUser currentUser] setObject:@YES forKey:@"isOver18"];
                                           
                                       } else {
                                           [[PFUser currentUser] setObject:@NO forKey:@"isOver18"];
                                           
                                       }
                                       
                                       [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                           if (succeeded && !error) {
                                               [Hud removeFromSuperview];
                                               
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
                                               /*PFQuery *loginQuery = [PFQuery queryWithClassName:@"UserPoints"];
                                               [loginQuery whereKey:@"user" equalTo:[PFUser currentUser]];
                                               
                                               [loginQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                                                   if(error){
                                                       NSLog(@"Error!");
                                                       [Hud removeFromSuperview];
                                                   }
                                                   else {
                                                       if (objects.count == 0) {
                                                           NSLog(@"No Records found!");
                                                           
                                                           PFObject *newUser= [PFObject objectWithClassName:@"UserPoints"];
                                                           [newUser setObject:[PFUser currentUser] forKey:@"user"];
                                                           newUser[@"lastLoginDate"] = [NSDate date];
                                                           //                                                           newUser[@"accumulativePoints"] = @0;
                                                           newUser[@"weeklyPoints"] = @0;
                                                           newUser[@"weeklyDate"] = [NSDate date];
                                                           newUser[@"monthlyPoints"] = @0;
                                                           newUser[@"monthlyDate"] = [NSDate date];
                                                           
                                                           [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                               if (!error) {
                                                                   
                                                                   [Hud removeFromSuperview];
                                                                   
                                                                   SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"TeamSelection"];
                                                                   
                                                                   [self.navigationController pushViewController:profileControl animated:YES];
                                                               }
                                                               
                                                           }];
                                                           
                                                       }
                                                   }
                                               }]; */
                                           }
                                       }];
                                       
                                       
                                       
                                   }
                               }];
                          } else {
                              NSString *errorString = [error userInfo][@"error"];
                              // Show the errorString somewhere and let the user try again.
                              NSLog(@"-----------Error-------------------------- %@",errorString);
                              //NSString *username = result[@"id"];
                              //NSString *email = result[@"email"];
                              //NSString *password = result[@"id"];
                              [PFUser logInWithUsernameInBackground:result[@"name"] password:result[@"id"]
                                                              block:^(PFUser *user2, NSError *error) {
                                                                  if (user2) {
                                                                      
                                                                      // Do stuff after successful login.
                                                                      [Flurry logEvent:@"User Started Facebook Session" timed:YES];
                                                                      NSLog(@"Logged In! ---------------------------------------------");
                                                                      //                                                                      [self setPointsParse];
                                                                      //                                                                      [self addLabels];
                                                                      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                      [defaults setObject:result[@"id"] forKey:@"userEmail"];
                                                                      [defaults setObject:result[@"id"] forKey:@"userPassword"];
                                                                      
                                                                      [Hud removeFromSuperview];
                                                                      
                                                                      SWRevealViewController *storeControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                                      
                                                                      [self.navigationController pushViewController:storeControl animated:NO];
                                                                  } else {
                                                                      // The login failed. Check error to see why.
                                                                      NSLog(@"%@",[error userInfo][@"error"]);
                                                                      NSLog(@"------------------------------------");
                                                                      PFUser *user3 = user;
                                                                      user3.email = nil;
                                                                      [user3 signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                          if (!error) {
                                                                              NSLog(@"This email has already been registered manually. Thus, create a new FB account with blank email (Otherwise, try to linking using Parse Cloud Code).");
                                                                              // Hooray! Let them use the app now.
                                                                              NSLog(@"User Created Successfully!");
                                                                              [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=age_range" parameters:nil]
                                                                               startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                                                                                   
                                                                                   if (!error) {
                                                                                       
                                                                                       //                                       pointsTitle =  @"You just registered via Facebook and earned yourself:";
                                                                                       //                                       pointsNSString = @"1000";
                                                                                       NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                                       [defaults setObject:result[@"id"] forKey:@"userEmail"];
                                                                                       [defaults setObject:result[@"id"] forKey:@"userPassword"];
                                                                                       
                                                                                       NSLog(@"fetched user age range: %@", result);
                                                                                       NSDictionary *ageRangeDict = [result objectForKey:@"age_range"];
                                                                                       
                                                                                       NSString *ageRange = [NSString stringWithFormat:@"%@-%@",
                                                                                                             [ageRangeDict objectForKey:@"min"],
                                                                                                             [ageRangeDict objectForKey:@"max"]];
                                                                                       NSLog(@"Age Range: %@",ageRange);
                                                                                       
                                                                                       int age = [[ageRangeDict objectForKey:@"min"] intValue];
                                                                                       
                                                                                       if (age > 17) {
                                                                                           [[PFUser currentUser] setObject:@YES forKey:@"isOver18"];
                                                                                           
                                                                                       } else {
                                                                                           [[PFUser currentUser] setObject:@NO forKey:@"isOver18"];
                                                                                           
                                                                                       }
                                                                                       
                                                                                       [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                                                                                           if (succeeded && !error) {
                                                                                               [Hud removeFromSuperview];
                                                                                               
                                                                                               SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                                                               
                                                                                               [self.navigationController pushViewController:profileControl animated:YES];
                                                                                               /* PFQuery *loginQuery = [PFQuery queryWithClassName:@"UserPoints"];
                                                                                               [loginQuery whereKey:@"user" equalTo:[PFUser currentUser]];
                                                                                               
                                                                                               [loginQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                                                                                                   if(error){
                                                                                                       NSLog(@"Error!");
                                                                                                       [Hud removeFromSuperview];
                                                                                                   }
                                                                                                   else {
                                                                                                       if (objects.count == 0) {
                                                                                                           NSLog(@"No Records found!");
                                                                                                           
                                                                                                           PFObject *newUser= [PFObject objectWithClassName:@"UserPoints"];
                                                                                                           [newUser setObject:[PFUser currentUser] forKey:@"user"];
                                                                                                           newUser[@"lastLoginDate"] = [NSDate date];
                                                                                                           //                                                           newUser[@"accumulativePoints"] = @0;
                                                                                                           newUser[@"weeklyPoints"] = @0;
                                                                                                           newUser[@"weeklyDate"] = [NSDate date];
                                                                                                           newUser[@"monthlyPoints"] = @0;
                                                                                                           newUser[@"monthlyDate"] = [NSDate date];
                                                                                                           
                                                                                                           [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                                                                                               if (!error) {
                                                                                                                   
                                                                                                                   [Hud removeFromSuperview];
                                                                                                                   
                                                                                                                   SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"TeamSelection"];
                                                                                                                   
                                                                                                                   [self.navigationController pushViewController:profileControl animated:YES];
                                                                                                               }
                                                                                                               
                                                                                                           }];
                                                                                                           
                                                                                                       }
                                                                                                   }
                                                                                               }]; */
                                                                                           }
                                                                                       }];
                                                                                       
                                                                                       
                                                                                       
                                                                                   }
                                                                               }];
                                                                          } else {
                                                                              [Hud removeFromSuperview];
                                                                              [Flurry logError:@"Facebook Login Error" message:error.description error:error];
                                                                              NSLog(@"OH BALL");
                                                                          } }];
                                                                  }
                                                              }];
                          }
                          
                      }];
                  }
              }];
             
         }
     }];
}

-(IBAction)tapEmailRegisterButton:(id)sender
{
    SWRevealViewController *registerControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"RegisterEmail"];
    
    [self.navigationController pushViewController:registerControl animated:YES];
}

-(IBAction)tapEmailLoginButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSLog(@"Button: %ld", (long)[button tag]);
    
    long buttonTapped = (long)[button tag];
    
    if (buttonTapped == 0) {
        //Custom Spinner
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
        //    [pageScroller addSubview:activityImageView];
        
        // Add stuff to view here
        Hud.customView = activityImageView;
        
        [Flurry logEvent:@"User tapped the submit login button" timed:YES];
        
        BOOL wrongEmail = [self validateEmail:email.text];
        
        //Checks if all fields have been completed
        if ([email.text isEqualToString:@""] || [password.text isEqualToString:@""]) {
            [Hud removeFromSuperview];
            [self alertEmptyFields];
        }else {

            if (wrongEmail == false) { // Checks if the emails don't match
                [Hud removeFromSuperview];
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
    } /* else if (buttonTapped == 2) {
        //reset password popup
        
        [Flurry logEvent:@"User tapped the forgot password button" timed:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Address" message:@"Enter the email for your account:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil]; alertView.alertViewStyle = UIAlertViewStylePlainTextInput; [alertView show];
    }*/
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
                        
                        alertVC = [[CustomAlert alloc] init];
                        [alertVC loadSingle:self.view:NSLocalizedString(@"Email Password", nil):NSLocalizedString(@"The email has been sent", nil)];
                        [alertVC.alertView removeFromSuperview];
                        
                    } else {
                        
                        //the query was successful, but found 0 results
                        //email does not exist in the database, dont send the email
                        //show your alert view here
                        
                        [Flurry logEvent:@"User entered wrong email to reset password" timed:YES];
                        
                        alertVC = [[CustomAlert alloc] init];
                        [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"Email does not exist in the database.", nil)];
                        [alertVC.alertView removeFromSuperview];
                        
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
    //password = textField;
}

// Set activeTextField to nil

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //password = textField;
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
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"All fields must be completed!", nil)];
    [alertVC.alertView removeFromSuperview];
    
}

//Handles missmatched email fields
- (void) alertWrongEmail{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):NSLocalizedString(@"Not a valid email", nil)];
    [alertVC.alertView removeFromSuperview];

}

- (void) alertUserLoginSuccessfull{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Success!", nil):[NSString stringWithFormat:NSLocalizedString(@"The user: %@ has been added to the database!", nil),email.text]];
    [alertVC.alertView removeFromSuperview];
    
}

- (void) alertUserDoesNotExist{
    
    alertVC = [[CustomAlert alloc] init];
    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):[NSString stringWithFormat:NSLocalizedString(@"Email %@ or password is incorrect!", nil),email.text]];
    [alertVC.alertView removeFromSuperview];
    
}

#pragma mark - Parse Methods

-(void)CheckDetails{
    
    [PFUser logOut];
    PFQuery *query = [PFUser query];
    [query whereKey:@"email" equalTo:email.text];
    //NSLog(@"email: %@, ---- pass: %@",email.text, password.text);
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * object, NSError *  error) {
        
        if(!error) {
            // The user already exists
            
            [PFUser logInWithUsernameInBackground:object[@"username"]  password:password.text
                                            block:^(PFUser *user, NSError *error) {
                                                if (user) {
                                                    // Do stuff after successful login.
                                                    NSLog(@"Logged In!");
                                                    
                                                    [Flurry logEvent:@"User logged in via email" timed:YES];
                                                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                    
                                                    //                                                    [defaults setObject:@"No" forKey:@"ShowLogin"];
                                                    
                                                    [Hud removeFromSuperview];
                                                    
                                                    [defaults setObject:email.text forKey:@"userEmail"];
                                                    [defaults setObject:password.text forKey:@"userPassword"];
                                                    
                                                    self.navigationController.navigationBar.alpha = 1;
                                                    self.navigationController.navigationBar.hidden = NO;
                                                    [Hud removeFromSuperview];
                                                    
                                                    SWRevealViewController *offersControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                    
                                                    [self.navigationController pushViewController:offersControl animated:NO];
                                                    
                                                } else {
                                                    // The login failed. Check error to see why.
                                                    NSLog(@"%@",[error userInfo][@"error"]);
                                                    [Hud removeFromSuperview];
                                                    
                                                    alertVC = [[CustomAlert alloc] init];
                                                    [alertVC loadSingle:self.view:NSLocalizedString(@"Error", nil):[NSString stringWithFormat:NSLocalizedString(@"Email %@ or password is incorrect!", nil),email.text]];
                                                    [alertVC.alertView removeFromSuperview];

                                                    failedLogin++;
                                                    if(failedLogin >= 3) {
                                                        [theScrollView addSubview:forgotPasswordButton];
                                                        failedLogin = -99999;
                                                    }
                                                }
                                            }];
            
        } else {
            // No user exists with the email
            [Hud removeFromSuperview];
            [self alertUserDoesNotExist];
        }
    }];
}
-(void)moviePlayerDidFinish:(NSNotification*)aNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerDidExitFullscreenNotification
                                                  object:nil];
    
    //NSLog(@"User pressed done");
    [movieController stop];
    isPlayingVideo = FALSE;
    theScrollView.userInteractionEnabled = YES;
    [movieController.view removeFromSuperview];
}
-(void)playbackStateChanged:(NSNotification*)aNotification{
    if(isPlayingVideo) {
        [movieController play];
    } else {
        [movieController stop];
    }

    //NSLog(@"User pressed done");
    
}


@end
