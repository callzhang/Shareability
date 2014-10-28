//
//  AdvancedViewController.h
//  MP3ConverterSample
//
//  Created by Sudanx on 08.03.2013.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MP3Converter.h"

@interface AdvancedViewController : UIViewController<MP3ConverterDelegate> {
    id _containerVc;
}
@property (nonatomic, assign) id containerVc;

@end
