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


@interface MostUsedTableController : UITableViewController <UINavigationControllerDelegate> {
    
    
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;
@property (nonatomic, strong) IBOutlet UIButton *browseAllButton;
@property (nonatomic, retain) NSMutableArray *browseAllArray;
@property (nonatomic, retain) NSMutableArray *arrayResults;
@property (nonatomic, weak) NSString *joinedComponents;
@property (nonatomic, weak) NSString *resultsString;
@property (weak,nonatomic) IBOutlet UITableView *tableView;


@end


