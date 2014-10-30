//
//  ViewController.m
//  Shareability
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "ViewController.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "SendMsgToWechatMgr.h"
#import "CargoManager.h"
#import "UnlockViewController.h"

@interface ViewController ()
@property (nonatomic) UnlockViewController *unlockViewController;
@property (nonatomic) SendMsgToWechatMgr *WXManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.unlockViewController = [[UnlockViewController alloc] initWithNibName:nil bundle:nil];
    [CargoManager sharedManager].contentDelegate = self.unlockViewController;
    [[CargoManager sharedManager] loadStore];
	
	//slideshow
	self.slideShow.delay = 3.0;
	self.slideShow.transitionDuration = 1;
	self.slideShow.transitionType = KASlideShowTransitionFade;
	self.slideShow.imagesContentMode = UIViewContentModeScaleAspectFill;
	[self.slideShow addImagesFromResources:@[@"1.png", @"2.png", @"3.png"]];
	[self.slideShow start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
