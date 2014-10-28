//
//  TypeConverterViewController.m
//  MP3ConverterSample
//
//  Created by Refaz Nabak on 3/31/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "TypeConverterViewController.h"
#import "ProgressView.h"
#import "AudioConverter.h"
#import "MP3ContainerViewController.h"

#import <QuartzCore/QuartzCore.h>

@interface TypeConverterViewController () {

    IBOutlet UITableView *_tableView;
    UIView *_footerView;
    ProgressView *_progressView;
    NSArray *_outputTitles;
    int _selectedIndex;
    UIButton *_buttonConvert;
}

@end

@implementation TypeConverterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _outputTitles = @[NSLocalizedString(@"wav", @""), NSLocalizedString(@"aac", @""), NSLocalizedString(@"aif", @""),
                          NSLocalizedString(@"alac", @""), NSLocalizedString(@"mp3", @"")];
        [_outputTitles retain];
        _selectedIndex = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor orangeColor];
    self.title = NSLocalizedString(@"File Conversion", @"");
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:button.currentImage style:UIBarButtonItemStylePlain target:self action:@selector(onButtonInfoTapped:)] autorelease];
}

#pragma mark - Table View delegate & callbacks

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_outputTitles count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Output Format", @"");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *cellId = @"BasicTableViewCellId";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Regular" size:17];
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
    cell.textLabel.text = [_outputTitles objectAtIndex:indexPath.row];

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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 54.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 54.0)];
        _footerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _footerView.backgroundColor = [UIColor clearColor];
        _footerView.opaque = YES;

        _buttonConvert = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        int hButton = 38.0;
        int wButton = 160.0;
        int xButton = (_footerView.bounds.size.width - wButton)/2.0;
        int yButton = (_footerView.bounds.size.height - hButton)/2.0;
        _buttonConvert.frame = CGRectMake(xButton, yButton, wButton, hButton);
        _buttonConvert.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_buttonConvert setTitle:NSLocalizedString(@"Convert", @"") forState:UIControlStateNormal];
        [_buttonConvert setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_buttonConvert.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:17]];
        [_buttonConvert addTarget:self action:@selector(onButtonConvertTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_footerView addSubview:_buttonConvert];
    }
    return _footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	_selectedIndex = indexPath.row;
	[tableView reloadData];
    if (_selectedIndex == [_outputTitles indexOfObject:_outputTitles.lastObject]) {
        [_buttonConvert setTitle:NSLocalizedString(@"Settings", @"") forState:UIControlStateNormal];
    } else {
        [_buttonConvert setTitle:NSLocalizedString(@"Convert", @"") forState:UIControlStateNormal];
    }
}

#pragma mark - Subviews & actions

- (void)onButtonConvertTapped:(id)sender {

    if (_selectedIndex == [_outputTitles indexOfObject:_outputTitles.lastObject]) {
        MP3ContainerViewController *mp3ContainerVc = [[[MP3ContainerViewController alloc] init] autorelease];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
            //running on iOS 6.0 or higher
            [self presentViewController:mp3ContainerVc animated:YES completion:NULL];
        } else {
            //running on iOS 5.x
            [self presentModalViewController:mp3ContainerVc animated:YES];
        }
#else
        [self.navigationController presentModalViewController:mp3ContainerVc animated:YES];
#endif
        return;
    }

    _progressView = [[ProgressView alloc] init];
    [_progressView setText:NSLocalizedString(@"% 0.0", @"")];
    [_progressView show:YES];
    [self performSelector:@selector(convert) withObject:nil afterDelay:0.3];

}

- (void)onButtonInfoTapped:(id)sender {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"KIT-Build"];
    NSString *message = [NSString stringWithFormat:@"• converted files go to Documents folder which you can access via iTunes File Sharing\n• input file can be changed in TypeConverterViewController.m file\n• Build date: %@",version];

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Info", @"") message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] autorelease];
    [alert show];
}

#pragma mark - Audio Converter Engine actions

- (void)convert {
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_wav" ofType:@"wav"];    /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aac" ofType:@"m4a"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aif" ofType:@"aif"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_alac" ofType:@"m4a"]; /* tested - OK */
    NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_mp3" ofType:@"mp3"];  /* tested - OK */

    AudioConverter *audioConverter = [[AudioConverter alloc] init];
    audioConverter.delegate = self;
    audioConverter.conversionStartPoint = 0.0;
    audioConverter.conversionLength = 40.0;

    NSString *outputName = @"tokyo_out";
    if (_selectedIndex == 0) {
        outputName = [outputName stringByAppendingString:@".wav"];
    } else if (_selectedIndex == 1) {
        outputName = [outputName stringByAppendingString:@".m4a"];
    } else if (_selectedIndex == 2) {
        outputName = [outputName stringByAppendingString:@".aif"];
    } else if (_selectedIndex == 3) {
        outputName = [outputName stringByAppendingString:@"_alac.m4a"];
    }

    [audioConverter convertAudioWithFilePath:pathIn outputName:outputName ofType:_selectedIndex];
}

#pragma mark - Audio Converter Engine Callbacks

- (void)convertFailed:(AudioConverter *)converter {
    [_progressView show:NO];
    [_progressView release];

    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"See logs written to output for more info", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];

    [converter release];
}

- (void)convertDone:(AudioConverter *)converter {
    [_progressView show:NO];
    [_progressView release];

    NSString *str = [NSString stringWithFormat:@"Conversion done in :"
                     "%ld ms. compressed filesize : %ld kb",[converter elapsedTime], [converter fileSize]/1024];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done." message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];

    [converter release];
}

- (void)onConvertionProgress:(NSNumber *)percentage {
    /* NSLog(@"%% %.2f", [percentage doubleValue]); */
    [_progressView setText:[NSString stringWithFormat:@"%% %.2f", [percentage doubleValue]]];
    [_progressView updateProgressWithValue:(float)[percentage doubleValue]/100];
}


#pragma mark - Memory deallocation

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [_outputTitles release];
    [_tableView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [_tableView release];
    _tableView = nil;
    [super viewDidUnload];
}

@end
