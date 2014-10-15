//
//  ShareViewController.h
//  Wechat
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "ConfigTableViewController.h"

#define selections		@[@"Wechat - Send to conversation", @"Wechat - Post to moments", @"Wechat - Add to favorite"]

@interface ShareViewController : SLComposeServiceViewController<ConfigTableViewControllerDelegate>

@end
