//
//  BasicViewController.m
//  MP3ConverterSample
//
//  Created by Sudanx on 08.03.2013.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "BasicViewController.h"
#import "ProgressView.h"

#import <QuartzCore/QuartzCore.h>

@interface BasicViewController () {
    
    IBOutlet UITableView *_tableView;
    NSArray *_presetTitles;
    int _selectedIndex;
    UIView *_footerView;
    ProgressView *_progressView;
}

@end

@implementation BasicViewController

@synthesize containerVc = _containerVc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _presetTitles = @[NSLocalizedString(@"Phone", @""), NSLocalizedString(@"Voice", @""), NSLocalizedString(@"FM Radio", @""),
                          NSLocalizedString(@"Tape Quality", @""), NSLocalizedString(@"CD Quality", @""), NSLocalizedString(@"Studio Quality", @""),
                          NSLocalizedString(@"Hi-fi", @"")];
        [_presetTitles retain];
        _selectedIndex = 4;
    }
    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - Table View delegate & callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_presetTitles count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Presets", @"");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellId = @"BasicTableViewCellId";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:17];
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
    cell.textLabel.text = [_presetTitles objectAtIndex:indexPath.row];

    if (indexPath.row == _selectedIndex) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}


    return cell;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    cell.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.95 alpha:1.0];
}

// specify the height of your footer section
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 54.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 54.0)];
        _footerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _footerView.backgroundColor = [UIColor clearColor];
        _footerView.opaque = YES;

        UIButton *buttonConvert = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        int hButtonConvert = 38.0;
        int wButtonConvert = 120.0;
        int xButtonConvert = (_footerView.bounds.size.width/2.0 - wButtonConvert)/2.0;
        int yButtonConvert = (_footerView.bounds.size.height - hButtonConvert)/2.0;
        buttonConvert.frame = CGRectMake(xButtonConvert, yButtonConvert, wButtonConvert, hButtonConvert);
        buttonConvert.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [buttonConvert setTitle:NSLocalizedString(@"Convert", @"") forState:UIControlStateNormal];
        [buttonConvert setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [buttonConvert.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:17]];
        [buttonConvert addTarget:self action:@selector(onButtonConvertTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_footerView addSubview:buttonConvert];

        UIButton *buttonCancel = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        int hButtonCancel = 38.0;
        int wButtonCancel = 120.0;
        int xButtonCancel = (_footerView.bounds.size.width/2.0 - wButtonCancel)/2.0 + _footerView.bounds.size.width/2.0;
        int yButtonCancel = (_footerView.bounds.size.height - hButtonCancel)/2.0;
        buttonCancel.frame = CGRectMake(xButtonCancel, yButtonCancel, wButtonCancel, hButtonCancel);
        buttonCancel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [buttonCancel setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
        [buttonCancel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [buttonCancel.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:17]];
        [buttonCancel addTarget:self action:@selector(onButtonCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_footerView addSubview:buttonCancel];

    }
    return _footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	_selectedIndex = indexPath.row;
	[tableView reloadData];
}

#pragma mark - Subviews & actions

- (void)onButtonConvertTapped:(id)sender {
    _progressView = [[ProgressView alloc] init];
    [_progressView setText:NSLocalizedString(@"% 0.0", @"")];
    [_progressView show:YES];
    [self performSelector:@selector(convert) withObject:nil afterDelay:0.3];
    
}

- (void)onButtonCancelTapped:(id)sender {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        //running on iOS 6.0 or higher
        [_containerVc dismissViewControllerAnimated:YES completion:NULL];
    } else {
        //running on iOS 5.x
        [_containerVc dismissModalViewControllerAnimated:YES];
    }
#else
    [_containerVc dismissModalViewControllerAnimated:YES];
#endif
}

#pragma mark - MP3 Converter Engine actions

- (void)convert {
	//NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_wav" ofType:@"wav"];    /* tested - OK */
    NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aac" ofType:@"m4a"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aif" ofType:@"aif"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_alac" ofType:@"m4a"]; /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_mp3" ofType:@"mp3"];  /* tested - OK */


    int *type = nil;
    if (_selectedIndex == 0) {
        type = PRESET_PHONE;
    } else if (_selectedIndex == 1){
        type = PRESET_VOICE;
    } else if (_selectedIndex == 2){
        type = PRESET_FM;
    } else if (_selectedIndex == 3){
        type = PRESET_TAPE;
    } else if (_selectedIndex == 4){
        type = PRESET_CD;
    } else if (_selectedIndex == 5){
        type = PRESET_STUDIO;
    } else if (_selectedIndex == 6){
        type = PRESET_HIFI;
    }

    NSString *outputName = @"tokyo_preset";
    outputName = [outputName stringByAppendingString:[NSString stringWithFormat:@"_%d",_selectedIndex]];
    outputName = [outputName stringByAppendingString:@".mp3"];

    MP3Converter *mp3Converter = [[MP3Converter alloc] initWithPreset:type];
    mp3Converter.delegate = self;
    [mp3Converter initializeLame];
    mp3Converter.conversionStartPoint = 2.0;
    mp3Converter.conversionLength = 35.0;
    [mp3Converter convertMP3WithFilePath:pathIn outputName:outputName];
}

#pragma mark - MP3 Converter Engine Callbacks

- (void)convertFailed:(MP3Converter *)converter {
    [_progressView show:NO];
    [_progressView release];

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"See logs written to output for more info", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];

    [converter release];
}

- (void)convertDone:(MP3Converter *)converter {
    [_progressView show:NO];
    [_progressView release];

    NSString *str = [NSString stringWithFormat:@"Conversion done in :"
                     "%ld ms. compressed filesize : %ld kb",[converter elapsedTime], [converter fileSize]/1024];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done." message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];

    [converter release];
}

- (void)onConvertionProgress:(NSNumber *)percentage {
    NSLog(@"%% %.2f", [percentage doubleValue]);
    [_progressView setText:[NSString stringWithFormat:@"%% %.2f", [percentage doubleValue]]];
    [_progressView updateProgressWithValue:(float)[percentage doubleValue]/100];
}

#pragma mark - Memory deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_presetTitles release];
    [_tableView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [_tableView release];
    _tableView = nil;
    [super viewDidUnload];
}
@end
