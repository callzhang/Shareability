//
//  UnlockViewController.h
//  Wechat Share
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CargoManager.h"

@interface UnlockViewController : UIViewController<CargoManagerContentDelegate, CargoManagerUIDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *detail;
- (IBAction)buy:(id)sender;
- (IBAction)restore:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *buy;
@property (weak, nonatomic) IBOutlet UIButton *restore;

@end
