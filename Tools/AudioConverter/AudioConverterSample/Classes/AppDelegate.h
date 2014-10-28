//
//  AppDelegate.h
//  MP3ConverterSample
//
//  Created by Sudanx on 28.02.2013.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TypeConverterViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    TypeConverterViewController *_typeConverterVc;
    UINavigationController *_navBarController;
}

@property (strong, nonatomic) UIWindow *window;

@end
