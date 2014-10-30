//
//  TPAACAudioConverter.m
//
//  Created by Michael Tyson on 02/04/2011.
//  Copyright 2011 A Tasty Pixel. All rights reserved.
//

#import "TPAACAudioConverter.h"
#import <AudioToolbox/AudioToolbox.h>
#include "lame.h"
#import <AVFoundation/AVFoundation.h>

NSString * TPAACAudioConverterWillSwitchAudioSessionCategoryNotification = @"TPAACAudioConverterWillSwitchAudioSessionCategoryNotification";
NSString * TPAACAudioConverterDidRestoreAudioSessionCategoryNotification = @"TPAACAudioConverterDidRestoreAudioSessionCategoryNotification";


NSString * TPAACAudioConverterErrorDomain = @"com.atastypixel.TPAACAudioConverterErrorDomain";


#define checkResult(result,operation) (_checkResultLite((result),(operation),__FILE__,__LINE__))

static inline BOOL _checkResultLite(OSStatus result, const char *operation, const char* file, int line) {
    if ( result != noErr ) {
        NSLog(@"[%d]: While executing function %s, got error %d %08X %4.4s\n",line, operation, (int)result, (int)result, (char*)&result);
        return NO;
    }
    return YES;
}

@interface TPAACAudioConverter() {
    BOOL            _processing;
    BOOL            _cancelled;
    BOOL            _interrupted;
    NSCondition    *_condition;
    UInt32          _priorMixOverrideValue;
}
@property (nonatomic, readwrite, retain) NSString *source;
@property (nonatomic, readwrite, retain) NSString *destination;
@property (nonatomic, assign) id<TPAACAudioConverterDelegate> delegate;
@property (nonatomic, retain) id<TPAACAudioConverterDataSource> dataSource;
@property (nonatomic) BOOL processMp3;
@property (nonatomic) NSString *tempPath;
@end

@implementation TPAACAudioConverter
@synthesize source = _source, destination = _destination, delegate = _delegate, dataSource = _dataSource, audioFormat = _audioFormat;

+ (BOOL)AACConverterAvailable:(UInt32)codec {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL available;
    static BOOL available_set = NO;

    if ( available_set ) return available;
    
    // get an array of AudioClassDescriptions for all installed encoders for the given format 
    // the specifier is the format that we are interested in
    UInt32 size;
    
    if ( !checkResult(AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(codec), &codec, &size),
                      "AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders") ) return NO;
    
    UInt32 numEncoders = size / sizeof(AudioClassDescription);
    AudioClassDescription encoderDescriptions[numEncoders];
    
    if ( !checkResult(AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(codec), &codec, &size, encoderDescriptions),
                      "AudioFormatGetProperty(kAudioFormatProperty_Encoders") ) {
        available_set = YES;
        available = NO;
        return NO;
    }
    
    for (UInt32 i=0; i < numEncoders; ++i) {
        if ( encoderDescriptions[i].mSubType == codec  ) {
            available_set = YES;
            available = YES;
            return YES;
        }
    }
    
    available_set = YES;
    available = NO;
    return NO;
#endif
}

#pragma mark - Start
- (void)convertWithDelegate:(id<TPAACAudioConverterDelegate>)delegate Input:(NSString *)input Output:(NSString *)output {
	NSArray *arr = [output componentsSeparatedByString:@"."];
	if ([arr.lastObject isEqualToString:@"mp3"]) {
		self.processMp3 = YES;
	}
	
	//audio session
	[[AVAudioSession sharedInstance] setDelegate:self];
	NSError *error = nil;
	
	//set category
	BOOL success = [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAudioProcessing
														  error: &error];
	if (!success) NSLog(@"AVAudioSession error setting category:%@",error);
	
	//set active
	success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
	if (!success){
		NSLog(@"Unable to activate ACTIVE audio session:%@", error);
	}else{
		NSLog(@"ACTIVE Audio session activated!");
	}
	
	self.delegate = delegate;
	self.source = input;
	self.destination = output;
	_condition = [[NSCondition alloc] init];

	[self start];
}

- (NSString *)tempPath{
	return [NSTemporaryDirectory() stringByAppendingString:@"temp.caf"];
}

//- (id)initWithDelegate:(id<TPAACAudioConverterDelegate>)delegate source:(NSString*)source destination:(NSString*)destination {
//    if ( !(self = [super init]) ) return nil;
//	
//    self.delegate = delegate;
//    self.source = source;
//    self.destination = destination;
//    _condition = [[NSCondition alloc] init];
//	
//    return self;
//}

- (id)initWithDelegate:(id<TPAACAudioConverterDelegate>)delegate dataSource:(id<TPAACAudioConverterDataSource>)dataSource
           audioFormat:(AudioStreamBasicDescription)audioFormat destination:(NSString*)destination {
    if ( !(self = [super init]) ) return nil;
    
    self.delegate = delegate;
    self.dataSource = dataSource;
    self.destination = destination;
    _audioFormat = audioFormat;
    _condition = [[NSCondition alloc] init];
    
    return self;
}

- (void)dealloc {
    self.source = nil;
    self.destination = nil;
    self.delegate = nil;
    self.dataSource = nil;
}

-(void)start {
    UInt32 size = sizeof(_priorMixOverrideValue);
    checkResult(AudioSessionGetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, &size, &_priorMixOverrideValue), 
                "AudioSessionGetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers)");
    
    if ( _priorMixOverrideValue != NO ) {
        UInt32 allowMixing = NO;
        checkResult(AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing),
                    "AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers)");
    }
    
    _cancelled = NO;
    _processing = YES;
    [self performSelectorInBackground:@selector(processing) withObject:nil];
}

-(void)cancel {
    _cancelled = YES;
    while ( _processing ) {
        [NSThread sleepForTimeInterval:0.01];
    }
    if ( _priorMixOverrideValue != NO ) {
        UInt32 allowMixing = _priorMixOverrideValue;
        checkResult(AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing),
                    "AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers)");
    }
}

- (void)interrupt {
    [_condition lock];
    _interrupted = YES;
    [_condition unlock];
}

- (void)resume {
    [_condition lock];
    _interrupted = NO;
    [_condition signal];
    [_condition unlock];
}

- (void)reportProgress:(NSNumber*)progress {
    if ( _cancelled ) return;
    [_delegate AACAudioConverter:self didMakeProgress:[progress floatValue]];
}

- (void)reportCompletion {
    if ( _cancelled ) return;
	
    if ( _priorMixOverrideValue != NO ) {
        UInt32 allowMixing = _priorMixOverrideValue;
        checkResult(AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing),
                    "AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers)");
    }
	
	if (self.processMp3) {
		[self convertToMp3From:self.tempPath To:self.destination];
	}else{
		[[NSFileManager defaultManager] copyItemAtPath:self.tempPath toPath:self.destination error:NULL];
		[[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:NULL];
		[_delegate AACAudioConverterDidFinishConversion:self];
	}
}

- (void)reportErrorAndCleanup:(NSError*)error {
    if ( _cancelled ) return;
    [[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:NULL];
    if ( _priorMixOverrideValue != NO ) {
        UInt32 allowMixing = _priorMixOverrideValue;
        checkResult(AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof (allowMixing), &allowMixing),
                    "AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers)");
    }
    [_delegate AACAudioConverter:self didFailWithError:error];
}

- (void)processing {
    
    [[NSThread currentThread] setThreadPriority:0.9];
    
    ExtAudioFileRef sourceFile = NULL;
    AudioStreamBasicDescription sourceFormat;
    if ( _source ) {
        if ( !checkResult(ExtAudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:_source], &sourceFile), "ExtAudioFileOpenURL") ) {
            [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                                   withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                                  code:TPAACAudioConverterFileError
                                                              userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't open the source file", @"Error message") forKey:NSLocalizedDescriptionKey]]
                                waitUntilDone:NO];
            _processing = NO;
            return;
        }
        
        
        UInt32 size = sizeof(sourceFormat);
        if ( !checkResult(ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &sourceFormat), 
                          "ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat)") ) {
            [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                                   withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                                  code:TPAACAudioConverterFormatError
                                                              userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't read the source file", @"Error message") forKey:NSLocalizedDescriptionKey]]
                                waitUntilDone:NO];
            _processing = NO;
            return;
        }
    } else {
        sourceFormat = _audioFormat;
    }
	
	//check
	if ( ![TPAACAudioConverter AACConverterAvailable:sourceFormat.mFormatID] ) {
		NSLog(@"Couldn't convert audio: Not supported on this device");
		return;
	}
    
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
	//============format============
    destinationFormat.mFormatID = kAudioFormatLinearPCM;
    UInt32 size = sizeof(destinationFormat);
	if (destinationFormat.mFormatID == kAudioFormatLinearPCM) {
		destinationFormat.mSampleRate = sourceFormat.mSampleRate;
		destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
		destinationFormat.mBitsPerChannel = 8 * 2;
		destinationFormat.mBytesPerPacket = destinationFormat.mBytesPerFrame = 2 * sourceFormat.mChannelsPerFrame;
		destinationFormat.mFramesPerPacket = 1;
		destinationFormat.mFormatFlags = kAudioFormatFlagsCanonical; //kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger; // little-endian
	}
	if (!checkResult(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &destinationFormat),
                      "AudioFormatGetProperty(kAudioFormatProperty_FormatInfo)")) {
        [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                               withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                              code:TPAACAudioConverterFormatError
                                                          userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't setup destination format", @"Error message") forKey:NSLocalizedDescriptionKey]]
                            waitUntilDone:NO];
        _processing = NO;
        return;
    }
    
    ExtAudioFileRef destinationFile;
    if (!checkResult(ExtAudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.tempPath], kAudioFileCAFType
											   , &destinationFormat, NULL, kAudioFileFlags_EraseFile, &destinationFile), "ExtAudioFileCreateWithURL")) {
        [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                               withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                              code:TPAACAudioConverterFileError
                                                          userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't create the destination file", @"Error message") forKey:NSLocalizedDescriptionKey]]
                            waitUntilDone:NO];
        _processing = NO;
        return;
    }
    
    AudioStreamBasicDescription clientFormat;
	memset(&clientFormat, 0, sizeof(clientFormat));
    if ( sourceFormat.mFormatID == kAudioFormatLinearPCM ) {
        clientFormat = sourceFormat;
	}else if (destinationFormat.mFormatID == kAudioFormatLinearPCM){
		clientFormat = destinationFormat;
	} else {
        clientFormat.mFormatID = kAudioFormatLinearPCM;
        clientFormat.mFormatFlags = kAudioFormatFlagsCanonical;
        clientFormat.mBitsPerChannel = 8 * 2;
        clientFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
        clientFormat.mFramesPerPacket = 1;
        clientFormat.mBytesPerPacket = clientFormat.mBytesPerFrame = sourceFormat.mChannelsPerFrame * 2;
        clientFormat.mSampleRate = sourceFormat.mSampleRate;
    }
	
    size = sizeof(clientFormat);
    if ( (sourceFile && !checkResult(ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat), 
                      "ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat"))) {
        if ( sourceFile ) ExtAudioFileDispose(sourceFile);
		
        [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                               withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                              code:TPAACAudioConverterFormatError
                                                          userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't setup source conversion format", @"Error message") forKey:NSLocalizedDescriptionKey]]
                            waitUntilDone:NO];
        _processing = NO;
        return;
    }
	
	if (!checkResult(ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat),
					 "ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat")) {
		ExtAudioFileDispose(destinationFile);
		[self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
							   withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
															  code:TPAACAudioConverterFormatError
														  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Couldn't setup dest file conversion format", @"Error message") forKey:NSLocalizedDescriptionKey]]
							waitUntilDone:NO];
		_processing = NO;
		return;
	}
	
    BOOL canResumeFromInterruption = YES;
    AudioConverterRef converter;
    size = sizeof(converter);
    if ( checkResult(ExtAudioFileGetProperty(destinationFile, kExtAudioFileProperty_AudioConverter, &size, &converter),
                      "ExtAudioFileGetProperty(kExtAudioFileProperty_AudioConverter;)") ) {
        UInt32 canResume = 0;
        size = sizeof(canResume);
        if ( checkResult(AudioConverterGetProperty(converter, kAudioConverterPropertyCanResumeFromInterruption, &size, &canResume), 
                         "AudioConverterGetProperty(kAudioConverterPropertyCanResumeFromInterruption") ) {
            canResumeFromInterruption = (BOOL)canResume;
        }
    }
    
    SInt64 lengthInFrames = 0;
    if ( sourceFile ) {
        size = sizeof(lengthInFrames);
        ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileLengthFrames, &size, &lengthInFrames);
    }
    
    UInt32 bufferByteSize = 32768;
    char srcBuffer[bufferByteSize];
    SInt64 sourceFrameOffset = 0;
    BOOL reportProgress = lengthInFrames > 0 && [_delegate respondsToSelector:@selector(AACAudioConverter:didMakeProgress:)];
    NSTimeInterval lastProgressReport = [NSDate timeIntervalSinceReferenceDate];
    
    while ( !_cancelled ) {
        AudioBufferList fillBufList;
        fillBufList.mNumberBuffers = 1;
        fillBufList.mBuffers[0].mNumberChannels = clientFormat.mChannelsPerFrame;
        fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
        fillBufList.mBuffers[0].mData = srcBuffer;
        
        UInt32 numFrames = bufferByteSize / clientFormat.mBytesPerFrame;
        
        if ( sourceFile ) {
            if ( !checkResult(ExtAudioFileRead(sourceFile, &numFrames, &fillBufList), "ExtAudioFileRead") ) {
                ExtAudioFileDispose(sourceFile);
                ExtAudioFileDispose(destinationFile);
                [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                                       withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                                      code:TPAACAudioConverterFormatError
                                                                  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Error reading the source file", @"Error message") forKey:NSLocalizedDescriptionKey]]
                                    waitUntilDone:NO];
                _processing = NO;
                return;
            }
        } else {
            NSUInteger length = bufferByteSize;
            [_dataSource AACAudioConverter:self nextBytes:srcBuffer length:&length];
            numFrames = length / clientFormat.mBytesPerFrame;
            fillBufList.mBuffers[0].mDataByteSize = length;
        }
        
        if ( !numFrames ) {
            break;
        }
        
        sourceFrameOffset += numFrames;
        
        [_condition lock];
        BOOL wasInterrupted = _interrupted;
        while ( _interrupted ) {
            [_condition wait];
        }
        [_condition unlock];
        
        if ( wasInterrupted && !canResumeFromInterruption ) {
            if ( sourceFile ) ExtAudioFileDispose(sourceFile);
            ExtAudioFileDispose(destinationFile);
            [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                                   withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                                  code:TPAACAudioConverterUnrecoverableInterruptionError
                                                              userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Interrupted", @"Error message") forKey:NSLocalizedDescriptionKey]]
                                waitUntilDone:NO];
            _processing = NO;
            return;
        }
        
        OSStatus status = ExtAudioFileWrite(destinationFile, numFrames, &fillBufList);
        
        if ( status == kExtAudioFileError_CodecUnavailableInputConsumed) {
            /*
             Returned when ExtAudioFileWrite was interrupted. You must stop calling
             ExtAudioFileWrite. If the underlying audio converter can resume after an
             interruption (see kAudioConverterPropertyCanResumeFromInterruption), you must
             wait for an EndInterruption notification from AudioSession, and call AudioSessionSetActive(true)
             before resuming. In this situation, the buffer you provided to ExtAudioFileWrite was successfully
             consumed and you may proceed to the next buffer
             */
        } else if ( status == kExtAudioFileError_CodecUnavailableInputNotConsumed ) {
            /*
             Returned when ExtAudioFileWrite was interrupted. You must stop calling
             ExtAudioFileWrite. If the underlying audio converter can resume after an
             interruption (see kAudioConverterPropertyCanResumeFromInterruption), you must
             wait for an EndInterruption notification from AudioSession, and call AudioSessionSetActive(true)
             before resuming. In this situation, the buffer you provided to ExtAudioFileWrite was not
             successfully consumed and you must try to write it again
             */
                
            // seek back to last offset before last read so we can try again after the interruption
            sourceFrameOffset -= numFrames;
            if ( sourceFile ) {
                checkResult(ExtAudioFileSeek(sourceFile, sourceFrameOffset), "ExtAudioFileSeek");
            } else if ( [_dataSource respondsToSelector:@selector(AACAudioConverter:seekToPosition:)] ) {
                [_dataSource AACAudioConverter:self seekToPosition:sourceFrameOffset * clientFormat.mBytesPerFrame];
            }
        } else if ( !checkResult(status, "ExtAudioFileWrite") ) {
            if ( sourceFile ) ExtAudioFileDispose(sourceFile);
            ExtAudioFileDispose(destinationFile);
            [self performSelectorOnMainThread:@selector(reportErrorAndCleanup:)
                                   withObject:[NSError errorWithDomain:TPAACAudioConverterErrorDomain
                                                                  code:TPAACAudioConverterFormatError
                                                              userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Error writing the destination file", @"Error message") forKey:NSLocalizedDescriptionKey]]
                                waitUntilDone:NO];
            _processing = NO;
            return;
        }
        
        if ( reportProgress && [NSDate timeIntervalSinceReferenceDate]-lastProgressReport > 0.1 ) {
            lastProgressReport = [NSDate timeIntervalSinceReferenceDate];
            [self performSelectorOnMainThread:@selector(reportProgress:) withObject:[NSNumber numberWithFloat:(double)sourceFrameOffset/lengthInFrames] waitUntilDone:NO];
        }
    }

    if ( sourceFile ) ExtAudioFileDispose(sourceFile);
    ExtAudioFileDispose(destinationFile);
    
    if ( _cancelled ) {
        [[NSFileManager defaultManager] removeItemAtPath:self.tempPath error:NULL];
    } else {
        [self performSelectorOnMainThread:@selector(reportCompletion) withObject:nil waitUntilDone:NO];
    }
    
    _processing = NO;
}

#pragma mark - AudioSessionDelegate
- (void)beginInterruption{
	NSLog(@"Begin interruption");
	[self interrupt];
}

- (void)endInterruption{
	NSLog(@"End interruption");
	[self resume];
}


#pragma mark - convert to MP3
- (void) convertToMp3From:(NSString *)input To:(NSString *)output
{
	
	@try {
		int read, write;
		//source
		FILE *pcm = fopen([input cStringUsingEncoding:1], "rb");
		fseek(pcm, 4*1024, SEEK_CUR); //skip file header
		//output
		FILE *mp3 = fopen([output cStringUsingEncoding:1], "wb");
		
		const int PCM_SIZE = 8192;
		const int MP3_SIZE = 8192;
		short int pcm_buffer[PCM_SIZE*2];
		unsigned char mp3_buffer[MP3_SIZE];
		
		lame_t lame = lame_init();
		lame_set_in_samplerate(lame, 44100.0f);
		lame_set_VBR(lame, vbr_default);
		lame_init_params(lame);
		
		do {
			read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
			if (read == 0)
				write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
			else
				write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
			
			fwrite(mp3_buffer, write, 1, mp3);
			
		} while (read != 0);
		
		lame_close(lame);
		fclose(mp3);
		fclose(pcm);
	}
	@catch (NSException *exception) {
		NSLog(@"%@",[exception description]);
	}
	@finally {
		//[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		NSFileManager * filemanager = [[NSFileManager alloc] init];
		NSDictionary * attributes = [filemanager attributesOfItemAtPath:output error:nil];
		float fileSize =  [[attributes objectForKey:NSFileSize] intValue];
		NSLog(@"File size: %.1f MB", fileSize/1024/1024);
		[_delegate AACAudioConverterDidFinishConversion:self];
	}
}

@end
