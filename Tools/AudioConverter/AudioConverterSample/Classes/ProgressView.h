//
//  Throbber.h
//  WIRO
//
//  Created by Kemal Taskin on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProgressView : UIView

/* public methods */
- (id)init;
- (void)setText:(NSString*) text;
- (void)show:(BOOL) yesOrNo;
- (void)updateProgressWithValue:(float)val;


@end
