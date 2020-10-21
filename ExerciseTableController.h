//
//  ExerciseTableController.h
//  Proludic
//
//  Created by Geoff Baker on 29/06/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExerciseTableController : UICollectionViewController <UITableViewDelegate, UITableViewDataSource>

@property (copy, nonatomic) NSArray *greekLetters;

@end
