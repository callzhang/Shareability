//
//  ConfigTableViewController.m
//  Shareability
//
//  Created by Lee on 10/15/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "ConfigTableViewController.h"

@interface ConfigTableViewController ()

@end

@implementation ConfigTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.alpha = .5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _OptionNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"Cell"];
	}
	NSString *selection = self.OptionNames[indexPath.row];
	NSArray *array = [selection componentsSeparatedByString:@" - "];
	cell.textLabel.text = array[0];
	cell.detailTextLabel.text = array[1];
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.delegate didSelectOptionAtIndexPath:indexPath];
}


@end
