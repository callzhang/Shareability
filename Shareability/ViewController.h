//
//  ViewController.h
//  Shareability
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KASlideShow.h"

@interface ViewController : UIViewController<KASlideShowDelegate>

@property (weak, nonatomic) IBOutlet KASlideShow *slideShow;
@property (weak, nonatomic) IBOutlet UIPageControl *pager;
@property (weak, nonatomic) IBOutlet UILabel *tutorial;

@end

