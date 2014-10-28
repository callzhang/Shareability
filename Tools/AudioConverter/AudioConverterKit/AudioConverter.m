//
//  AudioConverter.m
//  MP3ConverterSample
//
//  Created by Refaz Nabak on 3/31/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "AudioConverter.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AudioConverter() {

    NSTimeInterval _encodingStartInterval;
    NSTimeInterval _encodingEndInterval;

    int _conversionStartPoint;
    int _conversionLength;
}

@end

@implementation AudioConverter

@synthesize conversionStartPoint = _conversionStartPoint;
@synthesize conversionLength = _conversionLength;
@synthesize elapsedTime = _elapsedTime;
@synthesize fileSize = _fileSize;
@synthesize delegate = _delegate;

- (void)convertAudioWithFilePath:(NSString*)inputPath outputName:(NSString*)outputName ofType:(int)type {

#ifdef DEMO
    NSLog(@"--====================--\n"
          "--=== DEMO version ===--\n"
          "--====================--");
#endif
    
    _encodingStartInterval = [[NSDate date] timeIntervalSince1970] * 1000;
    NSLog(@"Starting to convert file");

    AVURLAsset * songAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:inputPath] options:nil];

	NSError *assetError = nil;
	AVAssetReader *assetReader = [[AVAssetReader assetReaderWithAsset:songAsset error:&assetError] retain];
	if (assetError) {
		NSLog (@"error: %@", assetError);
        if (_delegate && [_delegate respondsToSelector:@selector(convertFailed:)]) {
            [_delegate performSelectorOnMainThread:@selector(convertFailed:) withObject:self waitUntilDone:NO];
        }
		return;
	}

	AVAssetReaderOutput *assetReaderOutput = [[AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:
                                               songAsset.tracks audioSettings: nil] retain];
	if (! [assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"can't add reader output... die!");
        if (_delegate && [_delegate respondsToSelector:@selector(convertFailed:)]) {
            [_delegate performSelectorOnMainThread:@selector(convertFailed:) withObject:self waitUntilDone:NO];
        }
		return;
	}
	[assetReader addOutput: assetReaderOutput];

    float start = (_conversionStartPoint <= 0.0) ? 0.0 : _conversionStartPoint;
    float length = (_conversionLength <= 0.0) ? CMTimeGetSeconds(songAsset.duration) : _conversionLength;

#ifdef DEMO
    start = 0.0;
    if (length > 10.0) length = 10.0;
#endif

    CMTime startTrimTime = CMTimeMakeWithSeconds(start, 1);
    CMTime endTrimTime = CMTimeMakeWithSeconds(start+length, 1);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTrimTime, endTrimTime);
    assetReader.timeRange = exportTimeRange;

    NSString *docDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];
    NSString *exportPath = [[docDir stringByAppendingPathComponent:outputName] retain];

	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}

    NSString* avFileType = AVFileTypeWAVE;
    int audioFormat = kAudioFormatLinearPCM;

    if(type == AUDIO_OUTPUT_TYPE_AAC){
        avFileType = AVFileTypeAppleM4A;
        audioFormat = kAudioFormatMPEG4AAC;
    } else if(type == AUDIO_OUTPUT_TYPE_ALAC){
        avFileType = AVFileTypeAppleM4A;
        audioFormat = kAudioFormatAppleLossless;
    } else if(type == AUDIO_OUTPUT_TYPE_AIF){
        avFileType = AVFileTypeAIFC;
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
            //running on iOS 6.0. or higher
            audioFormat = kAudioFormatAppleIMA4;
        } else {
            audioFormat = kAudioFormatLinearPCM;
        }
    }

	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
	AVAssetWriter *assetWriter = [[AVAssetWriter assetWriterWithURL:exportURL
                                                           fileType:avFileType error:&assetError] retain];
	if (assetError) {
		NSLog (@"error: %@", assetError);
        if (_delegate && [_delegate respondsToSelector:@selector(convertFailed:)]) {
            [_delegate performSelectorOnMainThread:@selector(convertFailed:) withObject:self waitUntilDone:NO];
        }
		return;
	}
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
	NSMutableDictionary *outputSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:audioFormat], AVFormatIDKey,
                                           [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                           [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                           [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                           nil];
    if (type == AUDIO_OUTPUT_TYPE_WAV) {
        [outputSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [outputSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
        [outputSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        [outputSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    } else if (type == AUDIO_OUTPUT_TYPE_ALAC) {
        [outputSettings setValue:[NSNumber numberWithInt:16] forKey:AVEncoderBitDepthHintKey];
    } else if (type == AUDIO_OUTPUT_TYPE_AAC) {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedDescending) {
            //running on 5.x
            [outputSettings setValue:[NSNumber numberWithInt:64000] forKey:AVEncoderBitRateKey];
        }
    } else if (type == AUDIO_OUTPUT_TYPE_AIF) {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
            //running on iOS 6.0. or higher
            audioFormat = kAudioFormatAppleIMA4;
        } else {
            [outputSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
            [outputSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];
            [outputSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
            [outputSettings setValue:[NSNumber numberWithBool:YES] forKey:AVLinearPCMIsBigEndianKey];
        }
    }
	AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                               outputSettings:outputSettings ]
											retain];
	if ([assetWriter canAddInput:assetWriterInput]) {
		[assetWriter addInput:assetWriterInput];
	} else {
		NSLog (@"can't add asset writer input... die!");
        if (_delegate && [_delegate respondsToSelector:@selector(convertFailed:)]) {
            [_delegate performSelectorOnMainThread:@selector(convertFailed:) withObject:self waitUntilDone:NO];
        }
		return;
	}

	assetWriterInput.expectsMediaDataInRealTime = NO;

	[assetWriter startWriting];
	[assetReader startReading];

	AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];

	__block UInt64 convertedByteCount = 0;

    int totalSecond = songAsset.duration.value/songAsset.duration.timescale;
    //NSLog (@"%d totalSecond", totalSecond);

	dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
	[assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
											usingBlock: ^
	 {
		 while (assetWriterInput.readyForMoreMediaData) {
             CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             if (nextBuffer) {
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 //NSLog (@"appended a buffer (%zd bytes)", CMSampleBufferGetTotalSampleSize (nextBuffer));
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 //NSLog (@"%lld bytes converted", convertedByteCount);
                 if (_delegate && [_delegate respondsToSelector:@selector(onConvertionProgress:)]) {
                     CMTime presTime = CMSampleBufferGetPresentationTimeStamp(nextBuffer);
                     int atSecond = presTime.value/presTime.timescale;
                     //NSLog (@"%d atSecond", atSecond);
                     float p = ((double)(atSecond)/(double)totalSecond)*100;
                     NSNumber *percentage = [NSNumber numberWithDouble:p];
                     [_delegate performSelectorOnMainThread:@selector(onConvertionProgress:) withObject:percentage waitUntilDone:NO];
                 }
             } else {
                 // done!
                 [assetWriterInput markAsFinished];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
                 if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
                     //running on iOS 6.0. or higher
                     [assetWriter finishWritingWithCompletionHandler:^{
                         [assetWriter release];
                         [assetWriterInput release];
                     }];
                 } else {
                     [assetWriter finishWriting];
                     [assetWriter release];
                     [assetWriterInput release];
                 }
#else
                 [assetWriter finishWriting];
                 [assetWriter release];
                 [assetWriterInput release];
#endif

                 [assetReader cancelReading];
                 NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                                                       attributesOfItemAtPath:exportPath
                                                       error:nil];
                 NSLog (@"Media is converted. File size is %lld",[outputFileAttributes fileSize]);
                 _fileSize = [outputFileAttributes fileSize];

                 if (!_fileSize) {
                     if (_delegate && [_delegate respondsToSelector:@selector(convertFailed:)]) {
                         [_delegate performSelectorOnMainThread:@selector(convertFailed:) withObject:self waitUntilDone:NO];
                     }
                 } else {
                     _encodingEndInterval = [[NSDate date] timeIntervalSince1970] * 1000;
                     _elapsedTime = (long int) (_encodingEndInterval -_encodingStartInterval);

                     if (_delegate && [_delegate respondsToSelector:@selector(convertDone:)]) {
                         [_delegate performSelectorOnMainThread:@selector(convertDone:) withObject:self waitUntilDone:NO];
                     }
                 }
                 // release a lot of stuff
                 [assetReader release];
                 [assetReaderOutput release];
                 [exportPath release];
                 
                 break;
             }
         }
         
	 }];
}

@end
