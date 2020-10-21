//
//  CommunityViewController.h
//  Proludic
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCell.h"

@interface CommunityViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate>
// Properties

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (nonatomic, weak) UILabel *heartsLeaderboardLabel;
@property (nonatomic, weak) UILabel *achievementLeaderboardLabel;


-(void)alertDeleteResponse:(NSString*)result:(NSString*)varText:(int)selector;
-(void)readText:(NSString*)result:(NSString*)varText:(int)selector;
-(void)readThreadText:(NSString*)result:(NSString*)varText:(NSString*)varBody;

@end
