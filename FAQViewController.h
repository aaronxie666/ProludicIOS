//
//  FAQViewController.h
//  Proludic
//
//  Created by Geoff Baker on 31/07/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface FAQViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (weak, nonatomic) IBOutlet UIButton *editProfileButton;
@property (retain, nonatomic) IBOutlet UITextView *tf;

@end
