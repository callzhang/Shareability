//
//  Throbber.m
//  WIRO
//
//  Created by Kemal Taskin on 1/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ProgressView.h"


@interface ProgressView() {
	UILabel *_label;
    UIImageView *_imgViewBg;
    UIProgressView *_progress;
}

@end

@implementation ProgressView

- (id)init {

    CGRect bounds = [[[[UIApplication sharedApplication] delegate] window] bounds];
    if (self = [super initWithFrame:bounds]) {
        [self setBackgroundColor:[UIColor colorWithWhite:0.25 alpha:0.3]];

        int hImageBg = 178;
        int wImageBg = 246;
        int xImageBg = (bounds.size.width - wImageBg)/2.0;
        int yImageBg = (bounds.size.height - hImageBg)/2.0;
        _imgViewBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"progressBar-Bg.png"]];
        _imgViewBg.frame = CGRectMake(xImageBg, yImageBg, wImageBg, hImageBg);
        _imgViewBg.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self addSubview:_imgViewBg];

		_label = [[UILabel alloc] initWithFrame:CGRectMake(xImageBg + 20, yImageBg + 40, wImageBg - 40.0, 72)];
		[_label setBackgroundColor:[UIColor clearColor]];
		[_label setTextColor:[UIColor whiteColor]];
		[_label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:44.0]];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
		[_label setTextAlignment:NSTextAlignmentCenter];
#else 
        [_label setTextAlignment:UITextAlignmentCenter];
#endif

        _progress = [[UIProgressView alloc] initWithFrame:CGRectMake(xImageBg + 15.0, yImageBg + hImageBg - 50.0, wImageBg - 30.0, 20.0)];
        _progress.progressViewStyle = UIProgressViewStyleDefault;
        _progress.trackTintColor = [UIColor lightGrayColor];
        _progress.progressTintColor = [UIColor orangeColor];
        [self addSubview:_progress];

		[self addSubview:_label];
    }
    return self;
}

- (void) setText:(NSString*) text {
	[_label setText:text];
}

- (void) show:(BOOL) yesOrNo {
	if(yesOrNo) {
		[[[[UIApplication sharedApplication] delegate] window] addSubview:self];
	} else {
		[self removeFromSuperview];
	}
}

- (void)updateProgressWithValue:(float)val {
    [_progress setProgress:val animated:YES];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)dealloc {
    [_imgViewBg release];
    [_progress release];
	[_label release];
    [super dealloc];
}


@end
