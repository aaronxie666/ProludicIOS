//
//  MyExercisesTableController.m
//  Proludic
//
//  Created by Geoff Baker on 29/06/2017.
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
#import "TableViewCell.h"
#import "BrowseAllTableController.h"
#import "BrowseAllDetailController.h"


@interface BrowseAllTableController ()

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@end

@implementation BrowseAllTableController

extern UIScrollView *sideScroller;
extern UIScrollView *pageScroller;
extern NSUserDefaults *defaults;
extern bool refreshView;
extern bool userIsOnOverlay;
extern bool libraryPicked;
extern bool viewHasFinishedLoading;
extern UIImageView *imageView;
extern NSMutableArray *browseAllArray;
extern NSMutableArray *arrayResults;
extern NSMutableArray *videoURL;
extern NSMutableArray *imageObjects;
extern NSArray *results;

NSData *data;

int i;
int count;

@synthesize setImageData;
@synthesize URLString;
@synthesize tableView;
@synthesize parsedImage;
@synthesize arrayResults;
@synthesize imageObjects;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView reloadData];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.frame = CGRectZero;
    
    userIsOnOverlay = NO;
    viewHasFinishedLoading = NO;
    // Do any additional setup after loading the view.
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    [Flurry logEvent:@"User Opened Exercises Page" timed:YES];
    
    //Sounds
    
    
    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];

    //Header
    [self.navigationController.navigationBar  setBarTintColor:[UIColor colorWithRed:0.93 green:0.54 blue:0.14 alpha:1.0]];
    [_sidebarButton setEnabled:NO];
    [_sidebarButton setTintColor: [UIColor clearColor]];
    
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
    } else {
        workaroundImageView.frame = CGRectMake(0, 0, 42, 42);
    }
    
    [workaroundImageView addSubview:navigationImage];
    self.navigationItem.titleView=workaroundImageView;
    self.navigationItem.titleView.center = self.view.center;
    
    // Set the gesture
    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    // Build your regular UIBarButtonItem with Custom View
    UIImage *image = [UIImage imageNamed:@"hamburger2"];
    UIButton *leftBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBarButton.frame = CGRectMake(0,10, 22, 15);
    [leftBarButton addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchDown];
    [leftBarButton setBackgroundImage:image forState:UIControlStateNormal];
    
    // Make BarButton Item
    UIBarButtonItem *navLeftButton = [[UIBarButtonItem alloc] initWithCustomView:leftBarButton];
    self.navigationItem.leftBarButtonItem = navLeftButton;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //BackgroundImage
    UIImageView *background = [[UIImageView alloc] init];
    background.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    background.image = [UIImage imageNamed:@"BG"];
    [self.view addSubview:background];
    
    //Navigational Bar
    UIView *navigationalBarImage = [[UIView alloc] init];
    navigationalBarImage.backgroundColor = [UIColor colorWithRed:0.29 green:0.28 blue:0.28 alpha:1.0];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        navigationalBarImage.frame = CGRectMake(-5, 0, self.view.frame.size.width+20, 50); //Image scaled
        
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        navigationalBarImage.frame = CGRectMake(-5, 0, self.view.frame.size.width+20, 50); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        navigationalBarImage.frame = CGRectMake(-5, 0, 400, 50); //Image scaled
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        navigationalBarImage.frame = CGRectMake(-5, 0, self.view.frame.size.width+20, 50); //Image scaled
    } else {
        navigationalBarImage.frame = CGRectMake(-5, 0, self.view.frame.size.width+20, 50); //Image scaled
    }
    
    [self.view addSubview:navigationalBarImage];
    
    // Create the UI Side Scroll View
    sideScroller = [[UIScrollView alloc] init];
    
    if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
    {
        sideScroller.frame = CGRectMake(-5, 43, self.view.frame.size.width+20, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
    {
        sideScroller.frame = CGRectMake(-5, 45, self.view.frame.size.width+20, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
    {
        sideScroller.frame = CGRectMake(-5, 45, self.view.frame.size.width+20, 50); //Position of the scroller
    }
    else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
    {
        sideScroller.frame = CGRectMake(-5, 45, self.view.frame.size.width+20, 50); //Position of the scroller
    } else {
        sideScroller.frame = CGRectMake(-5, 45, self.view.frame.size.width+20, 50); //Position of the scroller
    }
    
    // Declare the size of the content that will be inside the scroll view
    // This will let the system know how much they can scroll inside
    sideScroller.bounces = NO;
    
    NavBar *navBar = [[NavBar alloc] init];
    
    int sideScrollerSize = [navBar getSize];
    
    sideScroller.contentSize = CGSizeMake(sideScrollerSize, 50);
    [sideScroller setContentOffset:CGPointMake([defaults integerForKey:@"sideScrollerOffSet"], 0) animated:NO];
    [sideScroller setShowsHorizontalScrollIndicator:NO];
    [sideScroller setShowsVerticalScrollIndicator:NO];
    
    [self.view addSubview:sideScroller];
    
    
    
    NSLog(@"%ld",(long)[defaults integerForKey:@"sideScrollerOffSet"]);
    //[self performSelector:@selector(setsideScrollerToPlace) withObject:nil afterDelay:0.01];
    
    
    //Get the array of Nav bar objects
    
    NSArray *arrayOfNavBarTitles = [navBar getTitles];
    NSArray *arrayOfXPositions = [navBar getXPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfButtonWidths = [navBar getButtonWidth:[[UIScreen mainScreen] bounds].size.height];
    
    //Add NavBar elements
    
    for (int i = 0; i < arrayOfNavBarTitles.count; i++) {
        NSString *title = [arrayOfNavBarTitles objectAtIndex:i];
        if (i == 1) { // Exercises
            title = [title stringByAppendingString:@"_Active"];
        }
        UIButton *navBarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        navBarButton.frame = CGRectMake([[arrayOfXPositions objectAtIndex:i] integerValue], 10, [[arrayOfButtonWidths objectAtIndex:i] intValue], sideScroller.frame.size.height - 20);
        navBarButton.tag = i + 1;
        [navBarButton addTarget:self action:@selector(tapNavButton:) forControlEvents:UIControlEventTouchUpInside];
        [navBarButton setBackgroundImage:[UIImage imageNamed:title] forState:UIControlStateNormal];
        navBarButton.titleLabel.font = [UIFont fontWithName:@"Bebas Neue" size:25];
        [navBarButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [sideScroller addSubview:navBarButton];
    }
    
   
    //RECTANGLES
    CGRect frame1 = CGRectMake( 0, 50.0, 125.0, 50.0);
    CGRect frame2 = CGRectMake( 125, 50.0, 125.0, 50.0);
    CGRect frame3 = CGRectMake( 250, 50.0, 125.0, 50.0);
    
    UIButton *view1 = [[UIButton alloc] initWithFrame:frame1];
    UIButton *view2 = [[UIButton alloc] initWithFrame:frame2];
    UIButton *view3 = [[UIButton alloc] initWithFrame:frame3];
    
    [view1 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view2 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    [view3 setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    
    [view1 setTitle:@"Browse All" forState:UIControlStateNormal];
    [view2 setTitle:@"Most Used" forState:UIControlStateNormal];
    [view3 setTitle:@"My Exercises" forState:UIControlStateNormal];
    
    [view1 addTarget:self action:@selector(tapExerciseBar:) forControlEvents:UIControlEventTouchUpInside];
    [view2 addTarget:self action:@selector(tapMostUsedBar:) forControlEvents:UIControlEventTouchUpInside];
    [view3 addTarget:self action:@selector(tapMyExercisesBar:) forControlEvents:UIControlEventTouchUpInside];
    
    [view1 setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [view2 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [view3 setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    
    [view1.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    [view2.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    [view3.titleLabel setFont:[UIFont fontWithName:@"Bebas Neue" size:16]];
    
    
    [self.view addSubview:view1];
    [self.view addSubview:view2];
    [self.view addSubview:view3];
    
    
    //Parse
    [self performSelector:@selector(retrieveFromParse)];
    [tableView reloadData];
    

}


-(void)retrieveFromParse {
    //QUERY FOR GETTING ALL EXERCISES
    PFQuery * browseAllQuery = [PFQuery queryWithClassName:@"Exercises"];
    [browseAllQuery orderByAscending:@"ExerciseName"];
    [browseAllQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            browseAllArray = [[NSMutableArray alloc]initWithArray:objects];
            [self.tableView reloadData];
        }
    }];
    
    //QUERY FOR GETTING ENDURANCE STATS
    PFQuery *arrayQuery = [PFQuery queryWithClassName:@"Exercises"];
    [arrayQuery selectKeys:@[@"Endurance"]];
    [arrayQuery orderByAscending:@"ExerciseName"];
    [arrayQuery findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        
        if (!error) {
            self.arrayResults = [results valueForKey:@"Endurance"];
            NSLog(@"Test: %@", self.arrayResults);
            [tableView reloadData];
            
            for (i = 0; i <= self.arrayResults.count; i++) {
                NSLog(@"Result: %d: %@", i, [[[results valueForKey:@"Endurance"] objectAtIndex:0]objectAtIndex:i]);
            }
        }
    }];
    
    //QUERY FOR GETTING VIDEO URL
    PFQuery *videoQuery = [PFQuery queryWithClassName:@"Exercises"];
    [videoQuery selectKeys:@[@"VideoURL"]];
    [videoQuery orderByAscending:@"ExerciseName"];
    [videoQuery findObjectsInBackgroundWithBlock:^(NSArray *objects2, NSError *error) {
        
        if (!error) {
            videoURL = [[NSMutableArray alloc] initWithArray:objects2];
        }
        
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return browseAllArray.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(TableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell setBackgroundColor:[UIColor colorWithRed:235.0f/255.0f green:174.0f/255.0f blue:116.0f/255.0f alpha:1.0]];
    
}

//CLICK EVENTS
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    
    BrowseAllDetailController *browseDetail = [self.storyboard instantiateViewControllerWithIdentifier:@"ExerciseDetailClicked"];
    NSString *details = [[browseAllArray objectAtIndex:indexPath.row] objectForKey:@"ExerciseName"];

    //EXERCISE INFORMATION LABELS
    NSString *setsString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:0];
    NSString *repsString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:1];
    NSString *weightString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:2];
    NSString *avgTimeString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:3];
    NSString *restTimeString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:4];
    NSString *setAltString = [[arrayResults objectAtIndex:indexPath.row] objectAtIndex:6];
    
    browseDetail.setSetsLabelString = setsString;
    browseDetail.setRepsLabelString = repsString;
    browseDetail.weightLabelString = weightString;
    browseDetail.restTimeLabelString = restTimeString;
    browseDetail.setTimeLabelString = avgTimeString;
    browseDetail.setAltLabelString = setAltString;
    
    browseDetail.exerciseLabelString = [[NSString alloc] initWithString:[[browseAllArray objectAtIndex:indexPath.row] objectForKey:@"ExerciseName"]];
    browseDetail.descLabelString = [[NSString alloc] initWithString:[[browseAllArray objectAtIndex:indexPath.row] objectForKey:@"Description"]];

    NSString *URLCreator = [[videoURL objectAtIndex:indexPath.row] objectForKey:@"VideoURL"];
    browseDetail.URLString = URLCreator;
    
    //QUERY FOR GETTING THUMBNAIL IMAGE
    PFQuery *imageQuery = [PFQuery queryWithClassName:@"Exercises"];
    [imageQuery orderByAscending:@"ExerciseName"];
    [imageQuery findObjectsInBackgroundWithBlock:^(NSArray *imageObjects, NSError *error) {
        if (!error) {
            PFFile *imageFile = [[imageObjects objectAtIndex:indexPath.row] objectForKey:@"ExerciseImage"];
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                
                NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"%@", imageFile.url]]];
                if ( data == nil )
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[activityView1 stopAnimating];
                    //[activityView1 removeFromSuperview];
                    browseDetail.imageView.image =  [UIImage imageWithData:data];
                    
                });
            });
        }
    }];
    

    [self.navigationController pushViewController:browseDetail animated:YES];
    [self.tableView reloadData];

}

- (TableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"list";
    TableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    UILabel *cellTitle;
    cell.cellTitle.text = [[browseAllArray objectAtIndex: indexPath.row] objectForKey:@"ExerciseName"];

    if (cell == nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell = [[TableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        //Exercise Bar Label
        cellTitle = [[UILabel alloc] initWithFrame:CGRectMake(80, 20, 220, 60)];
        cellTitle.font = [UIFont fontWithName:@"ethnocentric" size:14];
        cellTitle.textColor = [UIColor blackColor];
        cellTitle.numberOfLines = 2;
        cellTitle.textAlignment = NSTextAlignmentCenter;
        [cell.contentView addSubview:cellTitle];
        
        //Exercise Bar Button Star
        
        UIButton *starBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        [starBtn setFrame:CGRectMake(320, 38, 20, 20)];
        [starBtn addTarget:self action:@selector(selector) forControlEvents:UIControlEventTouchUpInside];
        [starBtn setBackgroundImage:[UIImage imageNamed:@"star_2"] forState: UIControlStateHighlighted];
        [starBtn setBackgroundImage:[UIImage imageNamed:@"star_2"] forState: UIControlStateSelected];
        [starBtn setImage:[UIImage imageNamed:@"star_2"] forState:UIControlStateNormal];
        [cell addSubview:starBtn];
        
        //Exercise Bar Arrows Image
        UIImageView *goldCoinImage = [[UIImageView alloc]init];
        if ([[UIScreen mainScreen] bounds].size.height == 480) //iPhone 4S size
        {
            goldCoinImage.frame = CGRectMake(25, 25, 35, 35);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 568) //iPhone 5 size
        {
            goldCoinImage.frame = CGRectMake(25, 25, 35, 35);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 667) //iPhone 6 size
        {
            goldCoinImage.frame = CGRectMake(30, 30, 41, 41);
        }
        else if ([[UIScreen mainScreen] bounds].size.height == 736) //iPhone 6+ size
        {
            goldCoinImage.frame = CGRectMake(35, 35, 45, 45);
        } else {
            goldCoinImage.frame = CGRectMake(35, 35, 45, 45);
        }
        goldCoinImage.image = [UIImage imageNamed:@"arrows"];
        goldCoinImage.contentMode = UIViewContentModeScaleAspectFit;
        goldCoinImage.clipsToBounds = YES;
        [cell.contentView addSubview:goldCoinImage];
        
        cell.cellTitle.text = [[browseAllArray objectAtIndex: indexPath.row] objectForKey:@"ExerciseName"];
        [self.tableView reloadData];
    }
    cellTitle.text = [[browseAllArray objectAtIndex:indexPath.row]objectForKey:@"ExerciseName"];
    return cell;

    
}


-(IBAction)tapExercisesDetail:(id)sender
{
    
    SWRevealViewController *exerciseDetailClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ExerciseDetailClicked"];
    
    [self.navigationController pushViewController:exerciseDetailClickControl animated:NO];
}
-(IBAction)tapExerciseActivity:(id)sender
{
    
    SWRevealViewController *exerciseClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"ExerciseClicked"];
    
    [self.navigationController pushViewController:exerciseClickControl animated:YES];
}
-(IBAction)tapExerciseBar:(id)sender
{
    
    SWRevealViewController *exerciseClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"BrowseAllTableClicked"];
    
    [self.navigationController pushViewController:exerciseClickControl animated:NO];
}
-(IBAction)tapMyExercisesBar:(id)sender
{
    
    SWRevealViewController *exerciseClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MyExercisesTableClicked"];
    
    [self.navigationController pushViewController:exerciseClickControl animated:NO];
}
-(IBAction)tapMostUsedBar:(id)sender
{
    
    SWRevealViewController *exerciseClickControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MostUsedTableClicked"];
    
    [self.navigationController pushViewController:exerciseClickControl animated:NO];
}

-(IBAction)tapNavButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSLog(@"Button: %ld", (long)[button tag]);
    
    NavBar *navBar = [[NavBar alloc] init];
    NSArray *arrayOfNavBarLinks = [navBar getControllerLinks];
    NSArray *arrayOfActiveViews = [navBar getActiveViewsPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfOffSetContents = [navBar getContentOffset:[[UIScreen mainScreen] bounds].size.height];
    NSInteger selectecItem = [button tag] - 1;
    
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Home"];
    
    if (selectecItem == anIndex) {
        //[sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
        
        UIButton *navBarButton = [sideScroller subviews][selectecItem];
        NSArray *arrayOfNavBarTitles = [navBar getTitles];
        //Add NavBar elements
        
        NSString *title = [[arrayOfNavBarTitles objectAtIndex:selectecItem] stringByAppendingString:@"_Active"];
        
        [navBarButton setBackgroundImage:[UIImage imageNamed:title] forState:UIControlStateNormal];
        
    } else {
        NSLog(@"%f", sideScroller.contentOffset.x);
        int sideScrollerOffSet = sideScroller.contentOffset.x;
        
        [defaults setInteger:sideScrollerOffSet forKey:@"sideScrollerOffSet"];
        
        [Flurry logEvent:@"User Pressed Navigation Bar Button" timed:YES];
        NSLog(@"%@",[arrayOfNavBarLinks objectAtIndex:selectecItem]);
        SWRevealViewController *pageControl = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:[arrayOfNavBarLinks objectAtIndex:selectecItem]];
        
        [self.navigationController pushViewController:pageControl animated:NO];
        
    }
    
}


- (void)setsideScrollerToPlace{
    
    NavBar *navBar = [[NavBar alloc] init];
    NSArray *arrayOfNavBarLinks = [navBar getControllerLinks];
    NSArray *arrayOfActiveViews = [navBar getActiveViewsPositions:[[UIScreen mainScreen] bounds].size.height];
    NSArray *arrayOfOffSetContents = [navBar getContentOffset:[[UIScreen mainScreen] bounds].size.height];
    NSInteger anIndex=[arrayOfNavBarLinks indexOfObject:@"Home"];
    
    [sideScroller setContentOffset:CGPointMake([[arrayOfOffSetContents objectAtIndex:anIndex] intValue], 0) animated:YES];
    
    [defaults setInteger:[[arrayOfActiveViews objectAtIndex:anIndex] intValue] forKey:@"sideScrollerOffSet"];
}

#pragma mark - Status Bar State
-(BOOL)prefersStatusBarHidden{
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
