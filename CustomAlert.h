//
//  CustomAlert.h
//  Proludic
//
//  Created by Geoff Baker on 29/11/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CustomAlert : NSObject

@property UIView *alertView;

-(void) loading: (UIView*)view:(NSString*)text:(NSString*)bodyText;
-(void) loadingVar: (UIViewController*)dash:(NSString*)text:(NSString*)bodyText:(NSString*)varText;
-(void) loadSingle: (UIView*)view:(NSString*)text:(NSString*)bodyText;

//COMM Exclusive
-(void) loadDeletePost:(UIViewController*)dash :(NSString *)text :(NSString *)bodyText :(NSString *)varText :(int)indentifier;

//TEXT FIELD
-(void) loadTextLine:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText;
-(void) loadTextLineVar:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText:(int)selector;
-(void) loadDoubleTextLineVar:(UIViewController*)dash:(NSString*)text:(NSString*)bodyText:(int)selector;

//CLOSE
-(void) closing: (UIView*)view;

-(void) resignFocus;
@end
