//
//  ViewController.m
//  AudioConvert
//
//  Created by Lei Zhang on 10/30/14.
//
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#include "lame.h"
#import <AVFoundation/AVFoundation.h>
#include "UseExtAF.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)convert:(id)sender {
    //source format
    AudioStreamBasicDescription sourceFormat;
    ExtAudioFileRef sourceFile = NULL;
    UInt32 size = sizeof(sourceFormat);
    NSString *input = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"m4a"];
    ExtAudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:input], &sourceFile);
    ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &sourceFormat);
    
    //destination format
    AudioStreamBasicDescription destinationFormat;
    destinationFormat.mFormatID = kAudioFormatAC3;
    destinationFormat.mSampleRate = sourceFormat.mSampleRate;
    destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
    destinationFormat.mBitsPerChannel = 8 * 2;
    destinationFormat.mBytesPerPacket = destinationFormat.mBytesPerFrame = 2 * sourceFormat.mChannelsPerFrame;
    destinationFormat.mFramesPerPacket = 1;
    destinationFormat.mFormatFlags = kAudioFormatFlagsCanonical;
    
    //file
    CFURLRef inputFileURL;
    CFURLRef outputFileURL;
    inputFileURL = (__bridge CFURLRef)[NSURL URLWithString:input];
    //format
    ConvertFileExt (inputFileURL,
                 sourceFormat,
                 outputFileURL,
                 kAudioFormatLinearPCM,
                 destinationFormat,
                 128);
}
@end
