//
//  ConfigTableViewController.h
//  Shareability
//
//  Created by Lee on 10/15/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConfigTableViewControllerDelegate <NSObject>
-(void)didSelectOptionAtIndexPath:(NSIndexPath * )indexPath;
@end

@interface ConfigTableViewController : UITableViewController
@property CGSize size;
@property (strong, nonatomic) NSArray * OptionNames;
@property (strong, nonatomic) id <ConfigTableViewControllerDelegate> delegate;
@end
