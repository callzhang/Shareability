//
//  TypeConverterViewController.h
//  MP3ConverterSample
//
//  Created by Refaz Nabak on 3/31/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioConverter.h"

@interface TypeConverterViewController : UIViewController<AudioConverterDelegate,
UITableViewDataSource, UITableViewDelegate>

@end
