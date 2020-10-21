//
//  MyExercisesTableController.h
//  Proludic
//
//  Created by Geoff Baker on 29/06/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "TableViewCell.h"


@interface MyExercisesTableController : UITableViewController <UINavigationControllerDelegate> {

IBOutlet UIButton *browseAllButton;

}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (nonatomic, strong) IBOutlet UIButton *browseAllButton;
@property (nonatomic, retain) NSMutableArray *browseAllArray;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end


