//
//  NavBar.m
//  KnowFootball
//
//  Created by Dan Meza on 06/04/2016.
//  Copyright © 2016 ICN. All rights reserved.
//

#import "NavBar.h"

@implementation NavBar

-(NSArray *)getSideBarTitles{
    NSArray *titles = [[NSArray alloc]initWithObjects:@"Home", @"Exercises", @"Profile", @"Community", @"More", @"Login", nil];
    
    return titles;
}

-(NSArray *)getTitles{
    NSArray *titles = [[NSArray alloc]initWithObjects:@"Home", @"Exercises", @"Profile", @"Community", nil];
    
    return titles;
}

-(NSArray *)getXPositions:(int)height{
    
    NSArray *xPositions = [[NSArray alloc] init];
    
    if (height == 480)//iPhone 4s size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"80", @"160", @"240", nil];
    } else if (height == 568)//iPhone 5 size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"80", @"160", @"240", nil];
    } else if (height == 667) //iPhone 6 size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"96", @"192", @"288", nil];
    } else if (height == 736) //iPhone 6+ size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"110", @"220", @"330", nil];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"96", @"192", @"288", nil];
    } else if (height == 896) //iPhone XR size
    {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"96", @"192", @"288", nil];
    }
    else {
    xPositions = [[NSArray alloc]initWithObjects:@"0", @"80", @"160", @"240", nil];
    }

    
    return xPositions;
}

-(int)getSize{
    return 865;
}

-(NSArray *)getControllerLinks{
    
    NSArray *controllerLinks = [[NSArray alloc]initWithObjects:@"Home", @"Exercises", @"Profile", @"Community", nil];
    
    return controllerLinks;
}

-(NSMutableArray *)getActiveViewsPositions:(int)height{
    
    NSMutableArray *activeViews = [[NSMutableArray alloc] init];
    
    //[activeViews addObject:@"-25"];
    [activeViews addObject:@"0"];
    [activeViews addObject:@"50"];//130
    [activeViews addObject:@"150"];//280
    [activeViews addObject:@"200"];//430
    //[activeViews addObject:@"580"];
    //[activeViews addObject:@"730"];
    
    return activeViews;
}

-(NSArray *)getButtonWidth:(int)height{
    NSArray *buttonSizes = [[NSArray alloc] initWithObjects:@"35", @"35", @"35", @"35", nil];
    return buttonSizes;
}

-(NSMutableArray *)getContentOffset:(int)height{
    
    NSMutableArray *contentOffsetArray = [[NSMutableArray alloc] init];
    
    if (height == 480)//iPhone 4s size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"37"];
        [contentOffsetArray addObject:@"187"];
        [contentOffsetArray addObject:@"335"];
        //[contentOffsetArray addObject:@"487"];
        //[contentOffsetArray addObject:@"525"];
        
    } else if (height == 568)//iPhone 5 size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"37"];
        [contentOffsetArray addObject:@"187"];
        [contentOffsetArray addObject:@"335"];
        //[contentOffsetArray addObject:@"487"];
        //[contentOffsetArray addObject:@"525"];
        
    } else if (height == 667) //iPhone 6 size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"10"];
        [contentOffsetArray addObject:@"160"];
        [contentOffsetArray addObject:@"310"];
        //[contentOffsetArray addObject:@"458"];
        //[contentOffsetArray addObject:@"470"];
    }
    else if (height == 736) //iPhone 6+ size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"-7"];
        [contentOffsetArray addObject:@"144"];
        [contentOffsetArray addObject:@"295"];
        //[contentOffsetArray addObject:@"443"];
        //[contentOffsetArray addObject:@"430"];
    } else if ([[UIScreen mainScreen] bounds].size.height == 812) //iPhone X size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"-7"];
        [contentOffsetArray addObject:@"144"];
        [contentOffsetArray addObject:@"295"];
        //[contentOffsetArray addObject:@"443"];
        //[contentOffsetArray addObject:@"430"];
    } else if (height == 896) //iPhone XR size
    {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"-7"];
        [contentOffsetArray addObject:@"144"];
        [contentOffsetArray addObject:@"295"];
        //[contentOffsetArray addObject:@"443"];
        //[contentOffsetArray addObject:@"430"];
    } else {
        [contentOffsetArray addObject:@"0"];
        [contentOffsetArray addObject:@"37"];
        [contentOffsetArray addObject:@"187"];
        [contentOffsetArray addObject:@"335"];
        //[contentOffsetArray addObject:@"487"];
        //[contentOffsetArray addObject:@"525"];
    }
    
    return contentOffsetArray;
}

@end
