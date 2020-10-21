//
//  ExerciseTableController.m
//  Proludic
//
//  Created by Geoff Baker on 29/06/2017.
//  Copyright © 2017 ICN. All rights reserved.
//

#import "ExerciseTableController.h"

@interface ExerciseTableController ()

@end

@implementation ExerciseTableController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.greekLetters = @[@"Hello",@"Bye",@"Test"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.greekLetters count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *SimpleIdentifier = @"SimpleIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SimpleIdentifier];
    }
    
    cell.textLabel.text = self.greekLetters[indexPath.row];
    
    return cell;
}

@end
