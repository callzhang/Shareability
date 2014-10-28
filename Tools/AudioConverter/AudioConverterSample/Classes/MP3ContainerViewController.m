//
//  MP3ContainerViewController.m
//  MP3ConverterSample
//
//  Created by Sudanx on 07.03.2013.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "MP3ContainerViewController.h"
#import "BasicViewController.h"
#import "AdvancedViewController.h"
#import "TypeConverterViewController.h"

#import <QuartzCore/QuartzCore.h>

#define SEGMENT_INDEX_FOR_VC_BASIC                      0
#define SEGMENT_INDEX_FOR_VC_ADVANCED                   1
#define SEGMENT_INDEX_FOR_VC_TYPE_CONVERTER             2

@interface MP3ContainerViewController () {
    UIToolbar *_toolBar;
    UIBarButtonItem *_barButtonSpaceLeft;
    UIBarButtonItem *_barButtonContainer;
    UIBarButtonItem *_barButtonSpaceRight;
    UIView *_viewCenteredOnBar;
    UISegmentedControl *_segmentBar;

    BasicViewController *_basicVc;
    AdvancedViewController *_advancedVc;
}

@end

@implementation MP3ContainerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark View life cycle

- (void)loadView
{
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];

    /* Toolbar on top: _toolBar */
    _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 44.0)];
    _toolBar.autoresizesSubviews = YES;
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolBar.barStyle = UIBarStyleBlackOpaque;
    _toolBar.tintColor = [UIColor orangeColor];
    _toolBar.layer.shadowColor = [[UIColor blackColor] CGColor];
    _toolBar.layer.shadowOffset = CGSizeMake(0.0, 0.5);
    _toolBar.layer.shadowOpacity = 1.0;
    
    [self.view addSubview:_toolBar];

    NSMutableArray *toolBarItems = [NSMutableArray array];

    /* Toolbar on top: _barButtonSpaceLeft */
    _barButtonSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBarItems addObject:_barButtonSpaceLeft];

    /* Toolbar on top: _viewCenteredOnBar */
    _viewCenteredOnBar = [[UIView alloc] initWithFrame:CGRectMake(10.0, 0.0, 300.0, 44.0)];
    _viewCenteredOnBar.autoresizesSubviews = YES;
    _viewCenteredOnBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _viewCenteredOnBar.backgroundColor = [UIColor clearColor];

    NSArray *segmentItems = [NSArray arrayWithObjects: NSLocalizedString(@"Basic", @""), NSLocalizedString(@"Advanced", @""), nil];
    _segmentBar = [[UISegmentedControl alloc] initWithItems:segmentItems];
    _segmentBar.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _segmentBar.frame = CGRectMake(0.0, 5.0, 300.0, 34.0);
    _segmentBar.backgroundColor = [UIColor clearColor];
    _segmentBar.tintColor = [UIColor lightGrayColor];
    _segmentBar.segmentedControlStyle = UISegmentedControlStyleBar;
    _segmentBar.selectedSegmentIndex = 0;
    [_segmentBar addTarget:self action:@selector(onSegmentValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_viewCenteredOnBar addSubview:_segmentBar];

    /* Toolbar on top: _barButtonContainer */
    _barButtonContainer = [[UIBarButtonItem alloc] initWithCustomView:_viewCenteredOnBar];
    [toolBarItems addObject:_barButtonContainer];

    /* Toolbar on top: _barButtonSpaceRight */
    _barButtonSpaceRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:NULL action:NULL];
    [toolBarItems addObject:_barButtonSpaceRight];
    [_toolBar setItems:toolBarItems];

    /* Creating & Adding Basic View Controller */
    _basicVc = [[BasicViewController alloc] initWithNibName:@"BasicViewController" bundle:nil];
    _basicVc.containerVc = self;
    _basicVc.view.frame = CGRectMake(0.0, _toolBar.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - _toolBar.bounds.size.height);
    [self.view insertSubview:_basicVc.view belowSubview:_toolBar];

    /* Creating Advanced View Controller */
    _advancedVc = [[AdvancedViewController alloc] initWithNibName:@"AdvancedViewController" bundle:nil];
    _advancedVc.containerVc = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)onSegmentValueChanged:(id)sender {
    if ([_segmentBar selectedSegmentIndex] == SEGMENT_INDEX_FOR_VC_BASIC) {

        if ([_advancedVc.view superview]) {
            [_advancedVc.view removeFromSuperview];
        }
        if (![_basicVc.view superview]) {
            _basicVc.view.frame = CGRectMake(0.0, _toolBar.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - _toolBar.bounds.size.height);
            [self.view insertSubview:_basicVc.view belowSubview:_toolBar];
        }
    } else if ([_segmentBar selectedSegmentIndex] == SEGMENT_INDEX_FOR_VC_ADVANCED) {

        if ([_basicVc.view superview]) {
            [_basicVc.view removeFromSuperview];
        }
        if (![_advancedVc.view superview]) {
            _advancedVc.view.frame = CGRectMake(0.0, _toolBar.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height - _toolBar.bounds.size.height);
            [self.view insertSubview:_advancedVc.view belowSubview:_toolBar];
        }
    } else if ([_segmentBar selectedSegmentIndex] == SEGMENT_INDEX_FOR_VC_TYPE_CONVERTER) {
        
        if ([_basicVc.view superview]) {
            [_basicVc.view removeFromSuperview];
        } else if ([_advancedVc.view superview]) {
            [_advancedVc.view removeFromSuperview];
        }
    }
}

#pragma mark View controller rotation methods & callbacks

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (BOOL)shouldAutorotate {
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

#pragma mark Memory deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {

    [_advancedVc release];
    [_basicVc release];
    [_barButtonSpaceLeft release];
    [_barButtonSpaceRight release];
    [_barButtonContainer release];
    [_segmentBar release];
    [_viewCenteredOnBar release];
    [_toolBar release];
    [super dealloc];
}

@end
