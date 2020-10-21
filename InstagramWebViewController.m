//
//  WebViewController.m
//  KnowFootball
//
//  Created by Luke on 02/09/2015.
//  Copyright (c) 2015 ICN. All rights reserved.
//

#import "InstagramWebViewController.h"
#import "SWRevealViewController.h"
#define kCLIENTID @"da5d2344e45549a7aa1449bce3777349"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"
#import "Flurry.h"

@interface InstagramWebViewController () <UIWebViewDelegate>
@end

@implementation InstagramWebViewController{
    UIView *instagramView;
    UIScrollView *popScroller;
    UIImageView *instagramImageView;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];;
    
    [Flurry logEvent:@"User Opened Login Instagram Page" timed:YES];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self buildWebView];
}

#pragma mark Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)buildWebView
{
    
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = @"Loading";
    
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
    
    
    // Initialise Web View
    self.loginWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 40)];
    self.loginWebView.delegate = self;
    self.loginWebView.backgroundColor = [UIColor whiteColor];
    self.loginWebView.scalesPageToFit = YES;
    self.loginWebView.scrollView.scrollEnabled = YES;
    self.loginWebView.scrollView.bounces = YES;
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    [self.cancelButton setImage:[UIImage imageNamed:@"Back_arrowButton"] forState:UIControlStateNormal];
    [self.cancelButton setCenter:CGPointMake(40, 20)];
    [self.cancelButton addTarget:self action:@selector(cancelButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    // Make request
    NSString *requestUrl = [NSString stringWithFormat:@"https://instagram.com/oauth/authorize/?client_id=%@&redirect_uri=http://localhost&response_type=token", kCLIENTID];
    
    requestUrl = [requestUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *websiteUrl = [NSURL URLWithString:requestUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
    
    //[self.loginWebView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)];
    [self.view addSubview:self.loginWebView];
    [self.view addSubview:self.cancelButton];
    [self.loginWebView loadRequest:urlRequest];
}

-(void)cancelButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString* urlString = [[request URL] absoluteString];
    NSURL *Url = [request URL];
    NSArray *UrlParts = [Url pathComponents];
    
    // runs a loop till the user logs in with Instagram and after login yields a token for that Instagram user
    // do any of the following here
    if ([UrlParts count] == 1)
    {
        NSRange tokenParam = [urlString rangeOfString: @"access_token="];
        if (tokenParam.location != NSNotFound)
        {
            NSString* token = [urlString substringFromIndex: NSMaxRange(tokenParam)];
            // If there are more args, don't include them in the token:
            NSRange endRange = [token rangeOfString: @"&"];
            NSLog(@"%@",token);
            if (endRange.location != NSNotFound)
                token = [token substringToIndex: endRange.location];
                [Hud removeFromSuperview];
            if ([token length] > 0 )
            {
                // call the method to fetch the user's Instagram info using access token
                NSLog(@"token %@", token);
                
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/users/self?access_token=%@", token]];
                
                
//                NSMutableArray *arrayData = [[NSMutableArray alloc]init];
                NSData *allInfoData = [[NSData alloc] initWithContentsOfURL:url];
                NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:allInfoData options:kNilOptions error:nil];
                NSLog(@"json = %@",json);
                
//                for (NSDictionary* dic in [json objectForKey:@"data"]) {
//                    [arrayData addObject:dic];
//                }
//                
//                NSLog(@"%@",arrayData);
//                
//                NSLog(@"array data = %@",arrayData);
                NSLog(@"ID: %@",[[json valueForKey:@"data"] valueForKey:@"id"]);
                NSString *instagramID = [[json valueForKey:@"data"] valueForKey:@"id"];
                NSLog(@"Full Name: %@",[[json valueForKey:@"data"] valueForKey:@"full_name"]);
                NSString *instagramName = [[json valueForKey:@"data"] valueForKey:@"full_name"];
                NSLog(@"Profile Picture: %@",[[json valueForKey:@"data"] valueForKey:@"profile_picture"]);
                NSString *instagramPicture= [[json valueForKey:@"data"] valueForKey:@"profile_picture"];
                //NSString *instagramUsername= [[json valueForKey:@"data"] valueForKey:@"username"];
//                NSLog(@"meta code = %@",[[json valueForKey:@"meta"] valueForKey:@"code"]);
//                NSLog(@"pagination deprecation_warning = %@",[[json valueForKey:@"pagination"] valueForKey:@"deprecation_warning"]);
//                NSLog(@"pagination min_tag_id = %@",[[json valueForKey:@"pagination"] valueForKey:@"min_tag_id"]);
//                NSLog(@"pagination next_min_id = %@",[[json valueForKey:@"pagination"] valueForKey:@"next_min_id"]);
                
                
//                NSString *content = [[NSString alloc] initWithData:allInfoData encoding:NSUTF8StringEncoding];
//                NSLog(@"%@",content);
//                NSArray* foo = [content componentsSeparatedByString: @"\""];
//                
//                NSString* full_name;
//                NSString* profile_picture;
//                NSString* id;
//                for (int i = 0; i < [foo count]; i++) {
//                    // 21 = profile_picture
//                    // 25 = full_name
//                    // 37 = id
//                    NSLog(@"%d == %@", i, foo[i]);
//                    profile_picture = foo[21];
//                    full_name = foo[25];
//                    id = foo[37];
//                    
//                }
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                NSString *stringWithoutForwardSlashes = [profile_picture
//                                                         stringByReplacingOccurrencesOfString:@"\\" withString:@""];
//                
                
                
                PFUser *user = [PFUser user];
                user.username = instagramName;
                user.password = instagramID;
                user.email = instagramID;
                user[@"name"] = instagramName;
                [user setObject:instagramPicture forKey:@"profilePicture"];
                //user[@"profilePicture"] = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                user[@"Hearts"] = @0;
                user[@"HomePark"] = @"NotSelected";
                user[@"TotalWeight"] = @0;
                user[@"login"] = @"Instagram";
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
                [user setObject:@YES forKey:@"isOver18"];
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        [Hud removeFromSuperview];
                        
                        SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                        
                        [self.navigationController pushViewController:profileControl animated:YES];
                    } else {
                        NSString *errorString = [error userInfo][@"error"];
                        // Show the errorString somewhere and let the user try again.
                        NSLog(@"-----------Error-------------------------- %@",errorString);
                        //NSString *username = result[@"id"];
                        //NSString *email = result[@"email"];
                        //NSString *password = result[@"id"];
                        [PFUser logInWithUsernameInBackground:instagramName password:instagramID
                                                        block:^(PFUser *user2, NSError *error) {
                                                            if (user2) {
                                                                
                                                                // Do stuff after successful login.
                                                                [Flurry logEvent:@"User Started Instagram Session" timed:YES];
                                                                NSLog(@"Logged In! ---------------------------------------------");
                                                                //                                                                      [self setPointsParse];
                                                                //                                                                      [self addLabels];
                                                                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                                [defaults setObject:instagramID forKey:@"userEmail"];
                                                                [defaults setObject:instagramID forKey:@"userPassword"];
                                                                
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
                                                                        NSLog(@"This email has already been registered manually. Thus, create a new account with blank email (Otherwise, try to linking using Parse Cloud Code).");
                                                                        // Hooray! Let them use the app now.
                                                                        NSLog(@"User Created Successfully!");
                                                                        [Hud removeFromSuperview];
                                                                        
                                                                        SWRevealViewController *profileControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                                        
                                                                        [self.navigationController pushViewController:profileControl animated:YES];
                                                                
                                                                    } else {
                                                                        [Hud removeFromSuperview];
                                                                        [Flurry logError:@"Facebook Login Error" message:error.description error:error];
                                                                    } }];
                                                            }
                                                        }];
                    }
                    
                }];
                
                
                
            }
        }
        else
        {
            NSLog(@"rejected case, user denied request");
        }
        return NO;
    }
    return YES;
}

-(void)instagramPoints {
    [self.loginWebView removeFromSuperview];
    
    UIImageView *skyBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        [skyBackgroundImageView setImage:[UIImage imageNamed:@"loginInstagramBackground4s"]];
        
    } else {
        [skyBackgroundImageView setImage:[UIImage imageNamed:@"loginInstagramBackground"]];
        
    }
    
//    UIImageView *grassImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 160, self.view.frame.size.width, 160)];
//    [grassImageView setImage:[UIImage imageNamed:@"grass_detail1.png"]];
//
//    UIImageView *healLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 220, 220)];
//    [healLogoImageView setImage:[UIImage imageNamed:@"heal_logo.png"]];
//    [healLogoImageView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 - 110)];
//
//    UIImageView *firstSentenceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 270, 15)];
//    [firstSentenceImageView setImage:[UIImage imageNamed:@"text.png"]];
//    [firstSentenceImageView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 + 40)];
//
//    UIImageView *clamsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
//    [clamsImageView setImage:[UIImage imageNamed:@"500clams.png"]];
//    [clamsImageView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 + 70)];
//
//    UIImageView *secondSentenceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 270, 45)];
//    [secondSentenceImageView setImage:[UIImage imageNamed:@"text_2.png"]];
//    [secondSentenceImageView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 + 115)];
//    
//    UIImageView *clams2ImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
//    [clams2ImageView setImage:[UIImage imageNamed:@"500clams.png"]];
//    [clams2ImageView setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 + 165)];
    
    self.emailTextField = [[UITextField alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        _emailTextField.frame = CGRectMake((self.view.frame.size.width/2)-120, self.view.frame.size.height/2 + 130, 240, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        _emailTextField.frame = CGRectMake((self.view.frame.size.width/2)-120, self.view.frame.size.height/2 + 180, 240, 30);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        _emailTextField.frame = CGRectMake((self.view.frame.size.width/2)-140, self.view.frame.size.height/2 + 215, 280, 30);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        _emailTextField.frame = CGRectMake((self.view.frame.size.width/2)-140, self.view.frame.size.height/2 + 235, 280, 30);
    }
    self.emailTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.emailTextField.delegate = self;
    self.emailTextField.placeholder = @"Email Address";
    [self.emailTextField setKeyboardType:UIKeyboardTypeEmailAddress];
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
//    [self.emailTextField setCenter:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 + 205)];
    
    
    UIButton *skipButton = [[UIButton alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        skipButton.frame = CGRectMake(25, self.view.frame.size.height/2 + 165, 120, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        skipButton.frame = CGRectMake(25, self.view.frame.size.height/2 + 215, 120, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        skipButton.frame = CGRectMake(45, self.view.frame.size.height/2 + 255, 130, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        skipButton.frame = CGRectMake(65, self.view.frame.size.height/2 + 280, 130, 40);
    } else {
        skipButton.frame = CGRectMake(65, self.view.frame.size.height/2 + 280, 130, 40);
    }
    
    [skipButton setBackgroundImage:[UIImage imageNamed:@"btn_skip"] forState:UIControlStateNormal];
//    [skipButton setCenter:CGPointMake(85, self.view.frame.size.height/2 + 250)];
    [skipButton addTarget:self action:@selector(skipButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *submitButton = [[UIButton alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        submitButton.frame = CGRectMake(173, self.view.frame.size.height/2 + 165, 120, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        submitButton.frame = CGRectMake(173, self.view.frame.size.height/2 + 215, 120, 35);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        submitButton.frame = CGRectMake(198, self.view.frame.size.height/2 + 255, 130, 40);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        submitButton.frame = CGRectMake(218, self.view.frame.size.height/2 + 280, 130, 40);
    } else {
        submitButton.frame = CGRectMake(218, self.view.frame.size.height/2 + 280, 130, 40);
    }
    [submitButton setBackgroundImage:[UIImage imageNamed:@"btn_submit1"] forState:UIControlStateNormal];
//    [submitButton setCenter:CGPointMake(self.view.frame.size.width/2 + 78, self.view.frame.size.height/2 + 250)];
    [submitButton addTarget:self action:@selector(submitButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:skyBackgroundImageView];
//    [self.view addSubview:grassImageView];
//    [self.view addSubview:healLogoImageView];
//    [self.view addSubview:firstSentenceImageView];
//    [self.view addSubview:clamsImageView];
//    [self.view addSubview:secondSentenceImageView];
//    [self.view addSubview:clams2ImageView];
    [self.view addSubview:self.emailTextField];
    [self.view addSubview:skipButton];
    [self.view addSubview:submitButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)nameTextField
{
    [nameTextField resignFirstResponder];
    
    return YES;
}


-(void)keyboardDidShow
{
    [self.view setFrame:CGRectMake(0,-178,320,568)];
}


- (void)skipButtonClicked
{
//    HomeViewController *homeView = [[HomeViewController alloc] init];
//    [self presentViewController:homeView animated:NO completion:nil];
}

- (void)submitButtonClicked
{
    
    
    if (![self validateEmail:self.emailTextField.text])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                        message:@"This email is not valid, please try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        PFUser *user= [PFUser currentUser];
        int number = [user[@"Points"] intValue];
        number += 500;
        NSString *userPoints = [NSString stringWithFormat:@"%d",number];
        [user setObject:userPoints forKey:@"Points"];
//        [user setObject:[NSNumber numberWithInt:number]forKey:@"Points"];
        user.email = self.emailTextField.text;
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
//                HomeViewController *homeView = [[HomeViewController alloc] init];
//                [self presentViewController:homeView animated:NO completion:nil];
                
                //Points pop Up
                
                self.navigationController.navigationBar.alpha = 0.02;
                
                self.navigationController.navigationBarHidden = YES;
                
                instagramView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                [self.view addSubview:instagramView];
                
                // Create the UI Scroll View
                popScroller = [[UIScrollView alloc] init];
                
                popScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
                
                // Declare the size of the content that will be inside the scroll view
                // This will let the system know how much they can scroll inside
                popScroller.bounces = NO;
                
                [self.view addSubview:popScroller];
                popScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
                
                instagramImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                instagramImageView.image = [UIImage imageNamed:@"addEmailInstagramPoints"];
                
                [popScroller addSubview:instagramImageView];
                
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
                } else {
                    offersButton.frame = CGRectMake(40, 427, 160, 35);
                }
                //    [backButton setBackgroundImage:backImage.image forState:UIControlStateNormal];
                [offersButton setBackgroundColor:[[UIColor purpleColor] colorWithAlphaComponent:0.0f]];
//                [offersButton addTarget:self action:@selector(tapOffersButton:) forControlEvents:UIControlEventTouchUpInside];
                
                [popScroller addSubview:offersButton];
                
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
                } else {
                    doneButton.frame = CGRectMake(213, 427, 160, 35);
                }
                //    [nextButton setBackgroundImage:nextButtonImage.image forState:UIControlStateNormal];
                [doneButton setBackgroundColor:[[UIColor purpleColor] colorWithAlphaComponent:0.0f]];
                [doneButton addTarget:self action:@selector(tapDonePointsButton) forControlEvents:UIControlEventTouchUpInside];
                
                [popScroller addSubview:doneButton];
                

        } else {
            NSLog(@"error:email: %@", error.description);
        }
    }];
    }
    
    
}

-(void)tapDonePointsButton{
    
    self.navigationController.navigationBar.alpha = 1;
    
    self.navigationController.navigationBarHidden = NO;
    
    SWRevealViewController *dashboardControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"Dashboard"];

    [self.navigationController pushViewController:dashboardControl animated:NO];
    
    
}

-(BOOL) validateEmail: (NSString *) userEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTemp = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; //  return 0;
    return [emailTemp evaluateWithObject:userEmail];
}

@end
