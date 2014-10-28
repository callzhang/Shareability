//
//  Mp3Encoder.m
//  MP3EncoderBasic
//
//  Created by Refaz Nabak on 1/27/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import "MP3Converter.h"
#import <AVFoundation/AVFoundation.h>

//preset settings
int PRESET_FM[] = {CBR,112,Standard,Stereo,0};
int PRESET_CD[] = {VBR,128,High,Stereo,FINE_QUALITY};
int PRESET_STUDIO[] = {CBR,256,Highest,Stereo,0};
int PRESET_VOICE[] = {CBR,64,Fastest,Mono,0};
int PRESET_PHONE[] = {CBR,16,Fastest,Mono,0};
int PRESET_TAPE[] = {CBR,128,Standard,Stereo,0};
int PRESET_HIFI[] = {VBR,320,Highest,Stereo,BEST_QUALITY};


@interface MP3Converter() {

    NSTimeInterval _encodingStartInterval;
    NSTimeInterval _encodingEndInterval;

    int _conversionStartPoint;
    int _conversionLength;
}

/* private methods */
- (int)encodeFileWithFilePath:(NSString*)inputPath outputName: (NSString*)outputName;

@end


@implementation MP3Converter

@synthesize bitrate;
@synthesize bitrateType;
@synthesize vbrQuality;
@synthesize encodingEngineQuality;
@synthesize channel;

@synthesize conversionStartPoint = _conversionStartPoint;
@synthesize conversionLength = _conversionLength;
@synthesize elapsedTime = _elapsedTime;
@synthesize fileSize = _fileSize;
@synthesize delegate = _delegate;

#define DEFAULT_BITRATE                             128
#define DEFAULT_ENCODING_ENGINE_QUALITY             5
#define DEFAULT_CHANNEL                             0
#define DEFAULT_VBR_QUALITY                         5

#define PERCENTAGE_UPDATE_FREQUENCY                 20


- (id)initWithBitrateType:(BitrateType)_bitrateType {
	if (self = [super init]) {
        _elapsedTime = 0;
        _fileSize = 0;
        _conversionStartPoint = -1;
        _conversionLength = -1;

		if (_bitrateType == CBR || _bitrateType == ABR) {
			self.bitrateType = _bitrateType;
            self.bitrate = DEFAULT_BITRATE;
            self.encodingEngineQuality = DEFAULT_ENCODING_ENGINE_QUALITY;
            self.channel = DEFAULT_CHANNEL;
		} else {
			self.bitrateType = _bitrateType;
            self.vbrQuality = DEFAULT_VBR_QUALITY;
            self.encodingEngineQuality = DEFAULT_ENCODING_ENGINE_QUALITY;
            self.channel = DEFAULT_CHANNEL;
		}
	}
	return self;
}

- (id)initWithPreset:(int [])preset {
	if (self = [super init]) {
        _elapsedTime = 0;
        _fileSize = 0;
        _conversionStartPoint = -1;
        _conversionLength = -1;

		if (preset[0] == CBR || preset[0] == ABR) {
			self.bitrateType = preset[0];
            self.bitrate = preset[1];
            self.encodingEngineQuality = preset[2];
            self.channel = preset[3];
		} else {
			self.bitrateType = VBR;
            self.vbrQuality = preset[4];
            self.encodingEngineQuality = preset[2];
            self.channel = preset[3];
		}
	}
	return self;
}

- (void) initializeLame {
    lame = lame_init();
    if(self.bitrateType == VBR) {
        lame_set_VBR_q(lame, self.vbrQuality);
        lame_set_VBR(lame, vbr_default);
    } else if(self.bitrateType == CBR) {
        lame_set_brate(lame, self.bitrate);
    } else { //ABR
        lame_set_brate(lame, self.bitrate);
        lame_set_VBR(lame, vbr_abr);
        lame_set_VBR_mean_bitrate_kbps(lame,self.bitrate);
    }

    lame_set_quality(lame, self.encodingEngineQuality);
    lame_set_mode(lame, (MPEG_mode)self.channel);
    lame_init_params(lame);
}

- (void)convertMP3WithFilePath:(NSString*)inputPath outputName:(NSString*)outputName {

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

    NSString *tmpDir = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/"];
    NSString *exportPath = [[tmpDir stringByAppendingPathComponent:@"temp.wav"] retain];

	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}

	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
	AVAssetWriter *assetWriter = [[AVAssetWriter assetWriterWithURL:exportURL
                                                           fileType:AVFileTypeWAVE error:&assetError] retain];
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
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
									[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
									[NSNumber numberWithInt:2], AVNumberOfChannelsKey,
									[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
									[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
									[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
									nil];
	AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                                               outputSettings:outputSettings]
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
                 NSLog (@"Media is converted to WAV. File size is %lld",[outputFileAttributes fileSize]);
                 _fileSize = [self encodeFileWithFilePath:exportPath outputName:outputName];

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

                 [assetReader release];
                 [assetReaderOutput release];
                 [exportPath release];

                 break;
             }
         }

	 }];
}


#pragma mark - Private methods

- (int)encodeFileWithFilePath:(NSString*)inputPath outputName: (NSString*)outputName {

    char *fileInCString = (char *)[inputPath UTF8String];
    NSString *pathOutVar = [NSString stringWithFormat:@"Documents/%@", outputName];
    NSString *pathOut = [NSHomeDirectory() stringByAppendingPathComponent:pathOutVar];
    char *fileOutCString = (char *)[pathOut cStringUsingEncoding:NSASCIIStringEncoding];

    int read, write, totalRead = 0;

    FILE *pcm = fopen(fileInCString, "rb");
    FILE *mp3 = fopen(fileOutCString, "wb");

    fseek(pcm, 0, SEEK_END);
    long pcmTotalSize = ftell(pcm);
    rewind(pcm);

    const int PCM_SIZE = 10000;
    const int MP3_SIZE = 10000;

    short int pcm_buffer[PCM_SIZE*2];
    unsigned char mp3_buffer[MP3_SIZE];

    int iterator = 0;

    do {
        iterator++;
        read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
        if (read == 0) {
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            if (_delegate && [_delegate respondsToSelector:@selector(onConvertionProgress:)]) {
                float p = ((double)(totalRead*2*sizeof(short int))/(double)pcmTotalSize)*100;
                NSNumber *percentage = [NSNumber numberWithDouble:p];
                [_delegate performSelectorOnMainThread:@selector(onConvertionProgress:) withObject:percentage waitUntilDone:NO];
            }
        } else {
            totalRead += read;
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            if (!(iterator % PERCENTAGE_UPDATE_FREQUENCY)) {
                if (_delegate && [_delegate respondsToSelector:@selector(onConvertionProgress:)]) {
                    float p = ((double)(totalRead*2*sizeof(short int))/(double)pcmTotalSize)*100;
                    NSNumber *percentage = [NSNumber numberWithDouble:p];
                    [_delegate performSelectorOnMainThread:@selector(onConvertionProgress:) withObject:percentage waitUntilDone:NO];
                }
            }
        }

        fwrite(mp3_buffer, write, 1, mp3);
    } while (read != 0);
    
    lame_close(lame);
    
    fseek(mp3, 0L, SEEK_END);
    int sizeOfMp3 = ftell(mp3);
    fseek(mp3, 0L, SEEK_SET);
    
    
    fclose(mp3);
    fclose(pcm);
    
    return sizeOfMp3;
}

@end