//
//  UseExtAF.h
//  ConvertFile
//
//  Created by Lei Zhang on 10/30/14.
//
//

#include <AudioToolbox/AudioToolbox.h>
#include "CAStreamBasicDescription.h"
#include "CAXException.h"
#ifndef ConvertFile_UseExtAF_h
#define ConvertFile_UseExtAF_h

int ConvertFileExt (CFURLRef					inputFileURL,
                 CAStreamBasicDescription	&inputFormat,
                 CFURLRef					outputFileURL,
                 AudioFileTypeID				outputFileType,
                 CAStreamBasicDescription	&outputFormat,
                 UInt32                      outputBitRate);
#endif
