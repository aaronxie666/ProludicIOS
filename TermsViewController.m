//
//  TermsViewController.m
//  Proludic
//
//  Created by Geoff Baker on 01/08/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "TermsViewController.h"
#import "SWRevealViewController.h"
#import "Reachability.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>
#import "NavBar.h"
#import "Flurry.h"

@interface TermsViewController ()
@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation TermsViewController {
    
    UIScrollView *pageScroller;
    NSUserDefaults *defaults;
    
    //Loading Animation
    MBProgressHUD *Hud;
    UIImageView *activityImageView;
    UIActivityIndicatorView *activityView;

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [Flurry logEvent:@"User Opened Terms & Conditions Page" timed:YES];
    defaults = [NSUserDefaults standardUserDefaults];
    
    
    pageScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 380);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 380);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 330);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 330);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 330);
    } else {
        pageScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height); //Position of the scroller
        pageScroller.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 330);
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    
    pageScroller.bounces = NO;
    [pageScroller setShowsVerticalScrollIndicator:NO];
    //[pageScroller setPagingEnabled : YES];
    [self.view addSubview:pageScroller];
    
    UILabel *faqLabel = [[UILabel alloc]init];
    faqLabel.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        faqLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:14];
        faqLabel.frame = CGRectMake(0, 50, self.view.frame.size.width, 20);
        
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:16];
        faqLabel.frame = CGRectMake(0, 60, self.view.frame.size.width, 20);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 70, self.view.frame.size.width, 20);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 70, self.view.frame.size.width, 20);
    } else {
        faqLabel.font = [UIFont fontWithName:@"Ethnocentric" size:18];
        faqLabel.frame = CGRectMake(0, 70, self.view.frame.size.width, 20);
    }
    faqLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Terms & Conditions", nil)];
    
    faqLabel.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:faqLabel];
    
    
    NSString *str1 = NSLocalizedString(@"- We recommend not to use Proludic equipment if you are injured or taking pain masking drugs as this may cause further injury.", nil);
    NSString *str2 = NSLocalizedString(@"- We recommend you do not use Proludic equipment whilst you are pregnant as our equipment has not been made with pregnancy in mind.", nil);
    NSString *str3 = NSLocalizedString(@"- We recommend consulting a doctor if you have any medical conditions prior to exercising on Proludic equipment.", nil);
    NSString *str4 = NSLocalizedString(@"- We will not be held responsible for any injuries which you may get from performing any of the exercises.", nil);
    NSString *str5 = NSLocalizedString(@"- We always recommend you stretch before and after exercising to avoid injuries.", nil);
    NSString *str6 = NSLocalizedString(@"- The forum on our app is self-managed by user who will report any misuse we are not held responsible for comments within the forum.", nil);
    NSString *linebreak = @"";

    NSString *combined = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@", str1, linebreak, str2, linebreak, str3, linebreak, str4, linebreak, str5, linebreak, str6];
    
    UILabel *terms = [[UILabel alloc]init];
    terms.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        terms.frame = CGRectMake(20, 50, self.view.frame.size.width - 40, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
        terms.frame = CGRectMake(20, 50, self.view.frame.size.width - 40, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:12];
        terms.frame = CGRectMake(20, 80, self.view.frame.size.width - 40, 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        terms.frame = CGRectMake(20, 85, self.view.frame.size.width - 40, 500);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        terms.frame = CGRectMake(20, 85, self.view.frame.size.width - 40, 500);
    } else {
        terms.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14];
        terms.frame = CGRectMake(20, 85, self.view.frame.size.width - 40, 500);
    }
    terms.text = combined;
    terms.numberOfLines = 30;
    terms.textAlignment = NSTextAlignmentJustified;
    [pageScroller addSubview:terms];
    
    
    //Logo 1
    UIImageView *termsLogo1 = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 410, 70, 67);
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 410, 70, 67);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 500, 80, 76);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 550, 80, 76);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 550, 80, 76);
    } else {
        termsLogo1.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 550, 80, 76);
    }
    termsLogo1.image = [UIImage imageNamed:@"termslogo2"];
    [pageScroller addSubview:termsLogo1];
    
    NSString *logo1str1 = NSLocalizedString(@"European (04/2015)", nil);
    NSString *logo1str2 = NSLocalizedString(@"Outdoor Fitness Standard (EN 16630)", nil);
    NSString *logo1str3 = NSLocalizedString(@"Our products have been tested by TUV RHEINLAND and meet EN16630 standard for Outdoor Fitness.", nil);
    
    NSString *logo1combined = [NSString stringWithFormat:@"%@\n%@\n%@", logo1str1, logo1str2, logo1str3];
    
    UILabel *logo1Label = [[UILabel alloc]init];
    logo1Label.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 350, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 350, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 400, self.view.frame.size.width - 80, 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 420, self.view.frame.size.width - 80, 500);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 420, self.view.frame.size.width - 80, 500);
    } else {
        logo1Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo1Label.frame = CGRectMake(40, 420, self.view.frame.size.width - 80, 500);
    }
    logo1Label.text = logo1combined;
    logo1Label.numberOfLines = 5;
    logo1Label.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:logo1Label];
    
    
    //Logo 2
    UIImageView *termsLogo2 = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 70, 600, 140, 95);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 70, 600, 140, 95);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 670, 150, 102);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 710, 150, 102);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 710, 150, 102);
    } else {
        termsLogo2.frame = CGRectMake(self.view.frame.size.width / 2 - 75, 710, 150, 102);
    }
    termsLogo2.image = [UIImage imageNamed:@"termslogo1.jpg"];
    [pageScroller addSubview:termsLogo2];
    
    NSString *logo2str1 = @"ISO 9001:2008";
    NSString *logo2str2 = NSLocalizedString(@"All contractors and associates manufacturing these product lines are certified and meet the ISO 9001: 2008 standard for management.", nil);
    
    NSString *logo2combined = [NSString stringWithFormat:@"%@\n%@", logo2str1, logo2str2];
    
    UILabel *logo2Label = [[UILabel alloc]init];
    logo2Label.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 510, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 510, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 560, self.view.frame.size.width - 80, 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 580, self.view.frame.size.width - 80, 500);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 580, self.view.frame.size.width - 80, 500);
    } else {
        logo2Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo2Label.frame = CGRectMake(40, 580, self.view.frame.size.width - 80, 500);
    }
    logo2Label.text = logo2combined;
    logo2Label.numberOfLines = 6;
    logo2Label.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:logo2Label];

    
    //Logo 3
    UIImageView *termsLogo3 = [[UIImageView alloc] init];
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 755, 70, 67);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 35, 755, 70, 67);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 825, 80, 76);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 875, 80, 76);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 875, 80, 76);
    } else {
        termsLogo3.frame = CGRectMake(self.view.frame.size.width / 2 - 40, 875, 80, 76);
    }
    termsLogo3.image = [UIImage imageNamed:@"termslogo4.jpg"];
    [pageScroller addSubview:termsLogo3];

    NSString *logo3str1 = NSLocalizedString(@"SGS and EN71", nil);
    NSString *logo3str2 = NSLocalizedString(@"Colours and materials integrated into the product lines have undergone testing and are certified according to EN71/SGS standards by Dupont and BASF.", nil);
    
    NSString *logo3combined = [NSString stringWithFormat:@"%@\n%@", logo3str1, logo3str2];
    
    UILabel *logo3Label = [[UILabel alloc]init];
    logo3Label.textColor = [UIColor blackColor];
    if ([[UIScreen mainScreen] bounds].size.height == 480)
    {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 665, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 665, self.view.frame.size.width - 80, 400);
    } else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 715, self.view.frame.size.width - 80, 450);
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 735, self.view.frame.size.width - 80, 500);
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 735, self.view.frame.size.width - 80, 500);
    } else {
        logo3Label.font = [UIFont fontWithName:@"OpenSans" size:10];
        logo3Label.frame = CGRectMake(40, 735, self.view.frame.size.width - 80, 500);
    }
    logo3Label.text = logo3combined;
    logo3Label.numberOfLines = 6;
    logo3Label.textAlignment = NSTextAlignmentCenter;
    [pageScroller addSubview:logo3Label];
    
}

-(void)showLoginView{
    
    SWRevealViewController *LoginControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"InitialLogin"];
    
    [self.navigationController pushViewController:LoginControl animated:NO];
}

-(void)checkForLoginDate{
    
    BOOL sameDay = [[NSCalendar currentCalendar] isDateInToday:[[PFUser currentUser] objectForKey:@"lastLoginDate"]];
    
    if (sameDay) {
        
        //User has already logged in today
        
        
    } else {
        
    }
    [self loadUser];
}

-(void)loadUser {
    
}
//-(void)viewDidAppear:(BOOL)animated{
//    [super viewWillAppear:YES];
//
//    self.navigationController.navigationBar.hidden = NO;
//}

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
            //    [topView addSubview:activityImageView];
            
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showLoading
{
    Hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    Hud.mode = MBProgressHUDModeCustomView;
    Hud.labelText = @"Loading";
    //Start the animation
    [activityImageView startAnimating];
    
    
    //Add your custom activity indicator to your current view
    [pageScroller addSubview:activityImageView];
    Hud.customView = activityImageView;
}

// Dismiss the keyboard
-(void)dismissKeyboard
{
    NSLog(@"Error Catcher");
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

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

@end
