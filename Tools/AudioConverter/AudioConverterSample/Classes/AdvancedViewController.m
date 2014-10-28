//
//  AdvancedViewController.m
//  MP3ConverterSample
//
//  Created by Sudanx on 08.03.2013.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "AdvancedViewController.h"
#import "ProgressView.h"
#import "MP3Converter.h"
#import <QuartzCore/QuartzCore.h>

@interface AdvancedViewController () {
    
    IBOutlet UISegmentedControl *_segmentBar;

    /* top view & subviews */
    IBOutlet UIView *_viewTop;
    IBOutlet UILabel *_labelSliderTitle;
    IBOutlet UILabel *_labelSliderValue;
    IBOutlet UISlider *_slider;

    /* bitrate options view & subviews */
    IBOutlet UIView *_viewBitrateOptions;
    IBOutlet UILabel *_labelCBR;
    IBOutlet UISwitch *_switchCBR;
    IBOutlet UILabel *_labelABR;
    IBOutlet UISwitch *_switchABR;

    /* bottom view & subviews */
    IBOutlet UIView *_viewBottom;
    IBOutlet UILabel *_labelEncQuality;
    IBOutlet UIButton *_buttonEncQuality;
    IBOutlet UILabel *_labelChannel;
    IBOutlet UIButton *_buttonChannel;
    
    ProgressView *_progressView;

    /*  */
    BOOL _bitrateSelection;
    BOOL _cbr;
    NSInteger _bitrateSliderChoice;
    NSInteger _qualitySliderChoice;
    NSInteger _engineQualitySelection;
    NSInteger _channelSelection;

}


- (IBAction)onButtonsEncOptionsTapped:(id)sender;
- (IBAction)onButtonConvertTapped:(id)sender;
- (IBAction)onButtonCancelTapped:(id)sender;
- (IBAction)onSliderValueChanged:(id)sender;
- (IBAction)onSegmentValueChanged:(id)sender;
- (IBAction)onSwitchesValueChanged:(id)sender;

@end

@implementation AdvancedViewController

@synthesize containerVc = _containerVc;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    /* stylize views & subviews */
    _viewTop.layer.borderWidth = 0.5;
    _viewTop.layer.borderColor = [[UIColor grayColor] CGColor];
    _viewTop.layer.cornerRadius = 5.0;
    _viewTop.layer.bounds = CGRectInset(_viewTop.layer.bounds, -6.0, -6.0);

    _viewBitrateOptions.layer.borderWidth = 0.5;
    _viewBitrateOptions.layer.borderColor = [[UIColor grayColor] CGColor];
    _viewBitrateOptions.layer.cornerRadius = 5.0;
    _viewBitrateOptions.layer.bounds = CGRectInset(_viewBitrateOptions.layer.bounds, -6.0, -6.0);

    _viewBottom.layer.borderWidth = 0.5;
    _viewBottom.layer.borderColor = [[UIColor grayColor] CGColor];
    _viewBottom.layer.cornerRadius = 5.0;
    _viewBottom.layer.bounds = CGRectInset(_viewBottom.layer.bounds, -6.0, -6.0);

    _buttonEncQuality.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    _buttonEncQuality.layer.borderWidth = 0.5;
    _buttonEncQuality.layer.cornerRadius = 9.0;
    _buttonChannel.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    _buttonChannel.layer.borderWidth = 0.5;
    _buttonChannel.layer.cornerRadius = 9.0;

    /* setting default values */
    _bitrateSelection = YES;
    _cbr = YES;
    _bitrateSliderChoice = 5;
    _qualitySliderChoice = 5;
    _engineQualitySelection = 0;
    _channelSelection  = 0;
    _labelSliderTitle.text = NSLocalizedString(@"Select bitrate", @"");
    [_buttonEncQuality setTitle:NSLocalizedString(@"Standart", @"") forState:UIControlStateNormal];
    [_buttonChannel setTitle:NSLocalizedString(@"Stereo", @"") forState:UIControlStateNormal];
    [self onSliderValueChanged:_slider];
}

#pragma mark - Subviews & actions

- (IBAction)onButtonsEncOptionsTapped:(id)sender {

    int tag = [(UIButton *)sender tag];

    if (tag == 1000) {
        _engineQualitySelection++;
        int eqs = _engineQualitySelection%3;
        if (eqs == 0) {
            [_buttonEncQuality setTitle:NSLocalizedString(@"Standart", @"") forState:UIControlStateNormal];
        } else if (eqs == 1){
            [_buttonEncQuality setTitle:NSLocalizedString(@"Fast", @"") forState:UIControlStateNormal];
        } else {
            [_buttonEncQuality setTitle:NSLocalizedString(@"High Quality", @"") forState:UIControlStateNormal];
        }
    } else if (tag == 1001) {
        _channelSelection++;
        int eqs = _channelSelection%3;
        if (eqs == 0) {
            [_buttonChannel setTitle:NSLocalizedString(@"Stereo", @"") forState:UIControlStateNormal];
        } else if (eqs == 1){
            [_buttonChannel setTitle:NSLocalizedString(@"Joint Stereo", @"") forState:UIControlStateNormal];
        } else {
            [_buttonChannel setTitle:NSLocalizedString(@"Mono", @"") forState:UIControlStateNormal];
        }
    }
}

- (IBAction)onSliderValueChanged:(id)sender {
    int sliderValue = _slider.value;
    int actualValue = 0;
    if(_bitrateSelection) {
        if(sliderValue == 0) {
            actualValue = 16;
        } else if(sliderValue == 1) {
            actualValue = 32;
        } else if(sliderValue == 2) {
            actualValue = 64;
        } else if(sliderValue == 3) {
            actualValue = 96;
        } else if(sliderValue == 4) {
            actualValue = 112;
        } else if(sliderValue == 5) {
            actualValue = 128;
        } else if(sliderValue == 6) {
            actualValue = 160;
        } else if(sliderValue == 7) {
            actualValue = 192;
        } else if(sliderValue == 8) {
            actualValue = 256;
        } else if(sliderValue == 9) {
            actualValue = 320;
        }
        _bitrateSliderChoice = sliderValue;
    } else {
        actualValue = sliderValue;
        _qualitySliderChoice = sliderValue;
    }
    _labelSliderValue.text = [NSString stringWithFormat:@"%d",actualValue];
}

- (IBAction)onSegmentValueChanged:(id)sender {
    UISegmentedControl *sgc = (UISegmentedControl*) sender;
    if(sgc.selectedSegmentIndex == 0) {
        _labelSliderTitle.text = NSLocalizedString(@"Select bitrate", @"");
        _bitrateSelection = YES;
        _slider.value = _bitrateSliderChoice;
        [UIView animateWithDuration:0.25 animations:^{
            _viewBottom.frame = CGRectMake(_viewBottom.frame.origin.x, _viewBottom.frame.origin.y + _viewBitrateOptions.frame.size.height, _viewBottom.frame.size.width, _viewBottom.frame.size.height);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 animations:^{
                _viewBitrateOptions.alpha = 1.0;
            }];
        }];

    } else {
        _labelSliderTitle.text = NSLocalizedString(@"Select Quality", @"");
        _bitrateSelection = NO;
        _slider.value = _qualitySliderChoice;
        [UIView animateWithDuration:0.25 animations:^{
            _viewBitrateOptions.alpha = 0.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.4 animations:^{
                _viewBottom.frame = CGRectMake(_viewBottom.frame.origin.x, _viewBottom.frame.origin.y - _viewBitrateOptions.frame.size.height, _viewBottom.frame.size.width, _viewBottom.frame.size.height);
            }];
        }];
    }
    [self onSliderValueChanged:_slider];
}

- (IBAction)onSwitchesValueChanged:(id)sender {
    UISwitch *sw = (UISwitch*) sender;
    if(sw.on && sw.tag == 2000) {
        _switchABR.on = NO;
        _cbr = YES;
    } else if (sw.on && sw.tag == 2001){
        _switchCBR.on = NO;
        _cbr = NO;
    }
}

- (void) showAlert : (int) fileSize time: (int) time {
    NSString *str = [NSString stringWithFormat:@"Conversion done in : %d seconds compressed filesize : %d",time,fileSize];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done." message:str delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
}

- (IBAction)onButtonConvertTapped:(id)sender {
    _progressView = [[ProgressView alloc] init];
    [_progressView setText:NSLocalizedString(@"% 0.0", @"")];
    [_progressView show:YES];
    [self performSelector:@selector(convert) withObject:nil afterDelay:0.3];
}

- (IBAction)onButtonCancelTapped:(id)sender {
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
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aac" ofType:@"m4a"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_aif" ofType:@"aif"];  /* tested - OK */
    //NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_alac" ofType:@"m4a"]; /* tested - OK */
    NSString *pathIn = [[NSBundle mainBundle] pathForResource:@"tokyo_mp3" ofType:@"mp3"];  /* tested - OK */

    MP3Converter *mp3Converter = nil;
    NSString *outputPath = @"tokyo";
    
    int theChannelSelection = [self getChannelSelection];
    int theEngineSelection = [self getEngineQualitySelection];
    if (theEngineSelection == 0) {
        theEngineSelection = Standard;
    } else if (theEngineSelection == 1){
        theEngineSelection = Fast;
    } else {
        theEngineSelection = High;
    }
    if(theChannelSelection == 2) {
        theChannelSelection = Mono;
    }
    
    if(_bitrateSelection){
        int bitrateSelected = [_labelSliderValue.text intValue];
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_%d",bitrateSelected]];
        BitrateType selectedBitrateType = CBR;
        if(_switchABR.isOn) {
            selectedBitrateType = ABR;
            outputPath = [outputPath stringByAppendingString:@"_abr"];
        } else {
            outputPath = [outputPath stringByAppendingString:@"_cbr"];
        }
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_engine%d",theEngineSelection]];
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_channel%d",theChannelSelection]];
        
        mp3Converter = [[MP3Converter alloc] initWithBitrateType:selectedBitrateType];
        mp3Converter.bitrateType = selectedBitrateType;
        mp3Converter.bitrate = bitrateSelected;
        
    } else {
        int selectedVbrQuality = abs(9-[_labelSliderValue.text intValue]);
        EncodingEngineQuality selectedEncodingEngineQuality = theEngineSelection;
        Channel selectedChannel = theChannelSelection;
        
        outputPath = [outputPath stringByAppendingString:@"_vbr"];
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_q%d",selectedVbrQuality]];
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_engine%d",selectedEncodingEngineQuality]];
        outputPath = [outputPath stringByAppendingString:[NSString stringWithFormat:@"_channel%d",selectedChannel]];
        
        mp3Converter = [[MP3Converter alloc] initWithBitrateType:VBR];        
        mp3Converter.vbrQuality = selectedVbrQuality;
        
    }
    outputPath = [outputPath stringByAppendingString:@".mp3"];
    
    mp3Converter.encodingEngineQuality = theEngineSelection;
    mp3Converter.channel = _channelSelection;
    mp3Converter.delegate = self;
    [mp3Converter initializeLame];
    mp3Converter.conversionStartPoint = 2.0;
    mp3Converter.conversionLength = 35.0;
    [mp3Converter convertMP3WithFilePath:pathIn outputName:outputPath];
    

}

- (int) getEngineQualitySelection {
    return _engineQualitySelection%3;
}

- (int) getChannelSelection {
    return _channelSelection%3;
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

- (void)viewDidUnload {
    [_segmentBar release];
    _segmentBar = nil;
    [_labelSliderTitle release];
    _labelSliderTitle = nil;
    [_labelSliderValue release];
    _labelSliderValue = nil;
    [_slider release];
    _slider = nil;
    [_labelCBR release];
    _labelCBR = nil;
    [_labelABR release];
    _labelABR = nil;
    [_switchCBR release];
    _switchCBR = nil;
    [_switchABR release];
    _switchABR = nil;
    [_labelEncQuality release];
    _labelEncQuality = nil;
    [_buttonEncQuality release];
    _buttonEncQuality = nil;
    [_labelChannel release];
    _labelChannel = nil;
    [_buttonChannel release];
    _buttonChannel = nil;
    [_viewBitrateOptions release];
    _viewBitrateOptions = nil;
    [_viewBottom release];
    _viewBottom = nil;
    [_viewTop release];
    _viewTop = nil;
    [_progressView release];
    _progressView = nil;
    [super viewDidUnload];
}

- (void)dealloc {
    [_segmentBar release];
    [_labelSliderTitle release];
    [_labelSliderValue release];
    [_slider release];
    [_labelCBR release];
    [_labelABR release];
    [_switchCBR release];
    [_switchABR release];
    [_labelEncQuality release];
    [_buttonEncQuality release];
    [_labelChannel release];
    [_buttonChannel release];
    [_viewBitrateOptions release];
    [_viewBottom release];
    [_viewTop release];
    [_progressView release];
    [super dealloc];
}
@end
