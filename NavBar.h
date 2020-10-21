//
//  NavBar.h
//  KnowFootball
//
//  Created by Dan Meza on 06/04/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NavBar : NSObject

-(NSArray *)getSideBarTitles;
-(NSArray *)getTitles;
-(NSArray *)getXPositions:(int)height;
-(int)getSize;
-(NSArray *)getControllerLinks;
-(NSMutableArray *)getActiveViewsPositions:(int)height;
-(NSArray *)getButtonWidth:(int)height;
-(NSMutableArray *)getContentOffset:(int)height;
@end
