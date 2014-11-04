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
    [CargoManager sharedManager].UIDelegate = self.unlockViewController;
    [[CargoManager sharedManager] loadStore];
	
	//slideshow
	self.slideShow.delay = 5.0;
	self.slideShow.transitionDuration = 1;
	self.slideShow.transitionType = KASlideShowTransitionFade;
	self.slideShow.imagesContentMode = UIViewContentModeScaleAspectFill;
	NSArray *images = @[@"0", @"1", @"2", @"3"];
	[self.slideShow addImagesFromResources:images];
	[self.slideShow start];
    self.slideShow.delegate = self;
    
    //pager
    self.pager.numberOfPages = 4;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Slideshow delegate

- (void) kaSlideShowDidNext:(KASlideShow *) slideShow{
    self.pager.currentPage = slideShow.currentIndex;
    switch (slideShow.currentIndex) {
        case 0:
            self.tutorial.text = @"Start using Shareability from the share section of your favorate apps by click the \"Share\" button";
            break;
            
        case 1:
            self.tutorial.text = @"Select the \"Wechat\" extension";
            break;
        case 2:
            self.tutorial.text = @"Add optional description";
            break;
        
        case 3:
            self.tutorial.text = @"Choose share method: Send to Chat, Post to Moments, or Save to Facvorate";
            break;
            
        default:
            break;
    }
}

- (void) kaSlideShowWillShowPrevious:(KASlideShow *) slideShow{
    self.pager.currentPage = slideShow.currentIndex;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
@end
