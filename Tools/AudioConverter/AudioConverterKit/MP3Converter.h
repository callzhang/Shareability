//
//  Mp3Encoder.h
//  MP3EncoderBasic
//
//  Created by Refaz Nabak on 1/27/13.
//  Copyright (c) 2013 MobileTR. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lame.h"

/* Available bitrate values for output MP3 file */
typedef enum {
    BITRATE_16 = 16,
	BITRATE_32 = 32,
	BITRATE_64 = 64,
	BITRATE_96 = 96,
    BITRATE_112 = 112,
	BITRATE_128 = 128,
	BITRATE_160 = 160,
    BITRATE_192 = 192,
    BITRATE_256 = 256,
    BITRATE_320 = 320,
} Bitrate;

/* Available bitrate types for MP3 conversion process */
typedef enum {
    ABR,
    CBR,
    VBR
} BitrateType;

/* Available quality settings for VBR MP3 conversion; 0 best, 9 lowest output quality */
typedef enum {
    LOWEST_QUALITY = 9,
    LOW_QUALITY = 7,
    MODERATE_QUALITY = 5,
    FINE_QUALITY = 2,
    BEST_QUALITY = 0
} VBRQuality;

/* Available encoding engine quality settings for MP3 conversion; 0 highest quality but slowest speed, 9 fastest speed but lowest quality */
typedef enum {
    Standard = 5,
    Highest = 0,
    High = 2,
    Fast = 7,
    Fastest = 9
} EncodingEngineQuality;

/* Channel types for output audio */
typedef enum {
    Stereo = 0,
    JointStereo = 1,
    Mono = 3
} Channel;

//preset settings
extern int PRESET_FM[];
extern int PRESET_CD[];
extern int PRESET_STUDIO[];
extern int PRESET_VOICE[];
extern int PRESET_PHONE[];
extern int PRESET_TAPE[];
extern int PRESET_HIFI[];

@protocol MP3ConverterDelegate;

@interface MP3Converter : NSObject {
    int bitrate;
    BitrateType bitrateType; /* Type of bitrate; ABR, VBR or CBR*/
    int vbrQuality; /* quality setting for VBR  valid values are 0....9 whic means 0-best; 9-lowest*/
    EncodingEngineQuality encodingEngineQuality; /* Quality setting for internal LAME algorithms*/
    Channel channel;
    lame_t lame;

    long int _elapsedTime; /* encoding duration */
    long int _fileSize; /* encoded file size */
    NSObject<MP3ConverterDelegate> *_delegate;
}

@property (nonatomic, assign) int bitrate; /* bitrate property; i.e 128,192... See Bitrate enum above*/
@property (nonatomic, assign) BitrateType bitrateType; /* bitrateType property; ABR, VBR or CBR */

@property (nonatomic, assign) int vbrQuality; /* property for quality setting of VBR,  valid values are 0....9 whic means 0-best; 9-lowest*/
@property (nonatomic, assign) EncodingEngineQuality encodingEngineQuality; /* property for quality setting for internal LAME algorithms*/
@property (nonatomic, assign) Channel channel; /* property for channel types for output audio */

@property (nonatomic, assign) int conversionStartPoint; /* start point of conversion in sec. */
@property (nonatomic, assign) int conversionLength; /* conversion length in sec. */
@property (nonatomic, readonly) long int elapsedTime; /* elapsed time for conversion in sec. */
@property (nonatomic, readonly) long int fileSize; /* Output file size of conversion in sec. */
@property (nonatomic, assign) NSObject<MP3ConverterDelegate> *delegate; /* delegate */

- (id)initWithBitrateType:(BitrateType)_bitrateType; /* initializer with BitrateType attribute*/
- (id)initWithPreset:(int [])preset; /* initializer with preset */
- (void)initializeLame; /* initializes LAME MP3 conversion engine*/

/**
 * Converts input audio file at inputPath to MP3 file to outputName
 *
 * @param inputPath: Input files path.
 * @param outputName: Name of the output file.
 * @return void.
 */
- (void)convertMP3WithFilePath:(NSString*)inputPath outputName:(NSString*)outputName;

@end

@protocol MP3ConverterDelegate<NSObject>
@required
- (void)convertFailed:(MP3Converter *)converter; /* Delegate metod called when the conversion process fails */
- (void)convertDone:(MP3Converter *)converter; /* Delegate metod called when the conversion process finishes */

@optional
- (void)onConvertionProgress:(NSNumber *)percentage; /* Delegate method called during processing to indicate the current status of the conversion */
@end

