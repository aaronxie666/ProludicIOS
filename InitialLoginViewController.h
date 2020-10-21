//
//  InitialLoginViewController.h
//  KnowFootball
//
//  Created by Dan Meza on 16/02/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MessageUI.h>

@interface InitialLoginViewController : UIViewController <MFMessageComposeViewControllerDelegate>
// Properties
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@end
