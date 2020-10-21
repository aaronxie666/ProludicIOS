//
//  DashboardViewController.h
//  KnowFootball
//
//  Created by Dan Meza on 26/01/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBManager.h"
#import <MapKit/MapKit.h>
#import <MediaPlayer/MediaPlayer.h>
@interface DashboardViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
// Properties
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

-(void)alertResponse:(NSString*)result:(NSString*)varText;
-(void)readText:(NSString*)result:(NSString*)varText;

@end
