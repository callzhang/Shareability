//
//  AudioConverter.h
//  MP3ConverterSample
//
//  Created by Refaz Nabak on 3/31/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import <Foundation/Foundation.h>

// Output file definitions
#define AUDIO_OUTPUT_TYPE_AAC                       1 /* Ouput format definition for AAC*/
#define AUDIO_OUTPUT_TYPE_AIF                       2 /* Ouput format definition for AIF-C*/
#define AUDIO_OUTPUT_TYPE_ALAC                      3 /* Ouput format definition for ALAC*/
#define AUDIO_OUTPUT_TYPE_WAV                       0 /* Ouput format definition for WAV*/


@protocol AudioConverterDelegate;

@interface AudioConverter : NSObject {
    
    long int _elapsedTime; /* encoding duration */
    long int _fileSize; /* encoded file size */
    NSObject<AudioConverterDelegate> *_delegate;
}

// property definitions
@property (nonatomic, assign) int conversionStartPoint; /* start point of conversion in sec. */
@property (nonatomic, assign) int conversionLength; /* conversion length in sec. */
@property (nonatomic, readonly) long int elapsedTime; /* elapsed time for conversion in sec. */
@property (nonatomic, readonly) long int fileSize; /* Output file size of conversion in sec. */
@property (nonatomic, assign) NSObject<AudioConverterDelegate> *delegate;

/**
 * Converts input audio file at inputPath to output file to outputName with given type
 *
 * @param inputPath: Input files path.
 * @param outputName: Name of the output file.
 * @param type: Type of the output file, See Output file definitions at the top of the file.
 * @return void.
 */
- (void)convertAudioWithFilePath:(NSString*)inputPath outputName:(NSString*)outputName ofType:(int)type; 
@end

@protocol AudioConverterDelegate<NSObject>
@required
- (void)convertFailed:(AudioConverter *)converter; /* Delegate metod called when the conversion process fails */
- (void)convertDone:(AudioConverter *)converter; /* Delegate metod called when the conversion process finishes */

@optional
- (void)onConvertionProgress:(NSNumber *)percentage; /* Delegate method called during processing to indicate the current status of the conversion */
@end