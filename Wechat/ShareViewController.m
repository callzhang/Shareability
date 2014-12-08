//
//  ShareViewController.m
//  Wechat
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "ShareViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "WXApi.h"
#import "WXApiObject.h"
#import "AnimatedGIFImageSerialization.h"
#import <AVFoundation/AVFoundation.h>
// standard includes
#import <AudioToolbox/AudioToolbox.h>
#import "TPAACAudioConverter.h"

NSString *const unlockID = @"com.wokealarm.Shareability.unlock";
NSString *const trialLeft = @"trail_left";
NSString *const groupID = @"group.Shareability";

enum{
	audio,
	video,
	file,
	image,
	emotion,
	text,
	website
};


@interface ShareViewController ()
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *content;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSData *emotion;
@property (nonatomic) NSString *text;
@property (nonatomic) NSData *video;
@property (nonatomic) NSData *audio;
@property (nonatomic) NSData *file;
@property (nonatomic) SLComposeSheetConfigurationItem *selected;
@property (nonatomic) NSInteger type;
@property (nonatomic) UIAlertController *alert;
@property (nonatomic) NSString *fileType;
@property (nonatomic) NSString *fileName;
@property (nonatomic) NSString *messageTitle;

@property (nonatomic) NSUserDefaults *sharedDefaults;
@end

@implementation ShareViewController

- (NSUserDefaults *)sharedDefaults{
	if (!_sharedDefaults) {
		_sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupID];
	}
	return _sharedDefaults;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    
    // Register your app
    [WXApi registerApp:@"wx166b37c35f3f6d9a" withDescription:@"Shareability"];
}

- (BOOL)isContentValid {
	BOOL charValid = YES;
	BOOL sizeValid = YES;
	BOOL trailValid = YES;
    if (![WXApi isWXAppSupportApi]) {
        [self showAlert:@"Please register a WeChat account first." withButton:YES];
        return NO;
    }
    
    // Do validation of contentText and/or NSExtensionContext attachments here
    NSInteger messageLength = [[self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
    NSInteger charactersRemaining = 1000 - messageLength;
    self.charactersRemaining = @(charactersRemaining);
    
    if (charactersRemaining >= 0) {
        charValid = YES;
	}else{
		charValid = NO;
	}
	
	float dataSize = 0;
	if (self.image) {
		NSData *imgData = UIImageJPEGRepresentation(self.image, 0.8);
		dataSize = imgData.length;
	}else if(self.audio){
		dataSize = self.audio.length;
	}else if (self.video){
		dataSize = self.video.length;
	}else if (self.file){
		dataSize = self.file.length;
	}
	if (dataSize/1024/1024 > 10) {
        NSLog(@"Data size: %.1fMB", dataSize/1024/1024);
		sizeValid = NO;
	}
	if (self.text){
		if (self.text.length / 1024 > 10) {
			sizeValid = NO;
		}
	}
	
	if (!sizeValid) {
		[self showAlert:@"File is too large" withButton:YES];
	}
	
	//trial
	if (![self.sharedDefaults boolForKey:unlockID]) {
		//not purchased
		if ([self.sharedDefaults objectForKey:trialLeft]) {
			NSInteger trails = [self.sharedDefaults integerForKey:trialLeft];
			if (trails > 0) {
				NSLog(@"Trail left: %ld", (long)trails);
			}else{
				trailValid = NO;
				
				[self showAlert:@"Thank you for using WeChat Share. You can now unlock all features in the main app now." withButton:YES];
			}
		}else{
			NSLog(@"First time trail");
			[self.sharedDefaults setInteger:10 forKey:trialLeft];
			[self.sharedDefaults synchronize];
			[self showAlert:@"Thank you for using WeChat Share. You have 10 shares now." withButton:YES];
		}
	}
	
	
	
    BOOL valid = sizeValid && charValid && trailValid;
	return valid;
}

- (void)presentationAnimationDidFinish{
	
	//get the context title first, as it will be changed by user
	self.title = @"WeChat Share";
	
	for (NSExtensionItem *item in self.extensionContext.inputItems) {
		NSLog(@"checking for input item: %@", item);
		for (NSItemProvider *provider in item.attachments) {
			NSLog(@"checking for ItemProvidor: %@", provider);
			
			//website
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeURL]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    self.messageTitle = self.contentText;
					self.url = url;
					if (item.attachments.count == 1) {
						self.type = website;
					}else{
						NSLog(@"Got multiple attachments, meaning it is not website");
					}
					
					NSLog(@"Get url: %@", item);
				}];
			}
			
			//image
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeImage]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *item, NSError *error) {
					self.image = item;
					if (item.duration > 0) {
						NSLog(@"Get GIF emotion");
						self.type = emotion;
						[provider loadItemForTypeIdentifier:( NSString *)kUTTypeImage options:nil completionHandler:^(NSData *data, NSError *error) {
							self.emotion = data;
						}];
                    }else{
                        NSLog(@"Get image");
                        self.type = image;
                    }
                    
				}];
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(NSURL *url, NSError *error) {
                    [self getFileNameAndTypeFromURL:url];
                }];
			}
			
			//text
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeText]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeText options:nil completionHandler:^(NSString *item, NSError *error) {
					self.text = item;
					self.type = text;
					NSLog(@"Get text: %@", item);
				}];
			}
			
			//movie
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVideo] || [provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSData *item, NSError *error) {
					self.video = item;
					self.type = video;
					NSLog(@"Get movie: %luMB", item.length/1048576);
					
					if (self.video.length/1048576 > 10) {
                        [self showAlert:@"Processing video" withButton:NO];
                        NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"videoTempFile.mov"];
                        NSParameterAssert([item writeToFile:path atomically:NO]);
						AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
						AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPresetMediumQuality];
						
						//output
						NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"videoOutTempFile"]];
						NSFileManager *fileManager = [NSFileManager defaultManager];
						[fileManager removeItemAtURL:outputURL error:NULL];
						session.outputURL = outputURL;
						session.outputFileType = AVFileTypeQuickTimeMovie;
                        [session exportAsynchronouslyWithCompletionHandler:^(void){
                            [self dismissAlert];
                            self.fileType = @"mov";//change file type to quicktime movie
                            switch ([session status]) {
                                case AVAssetExportSessionStatusFailed:
                                    NSLog(@"Failed with error: %@", session.error.description);
                                    [self showAlert:@"Failed processing video" withButton:YES];
                                    break;
                                case AVAssetExportSessionStatusCancelled:
                                    NSLog(@"User cancelled");
                                    break;
                                default:{
                                    NSData *data = [NSData dataWithContentsOfURL:outputURL];
                                    if (data.length/1024.0/1024.0 > 10) {
                                        NSLog(@"Too large");
                                        //too large
                                        [self showAlert:@"File is too large" withButton:YES];
                                    }else{
                                        NSLog(@"Finished");
                                    }
                                    self.video = data;
                                }
                                    break;
                            }
                            
                            //delete file
                            NSFileManager *fileManager = [NSFileManager defaultManager];
                            [fileManager removeItemAtURL:outputURL error:NULL];
                            
						 }];
					}
				}];
			}//video
            else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVideo] || [provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSData *item, NSError *error) {
                    self.video = item;
                    self.type = video;
                    NSLog(@"Get video: %luMB", item.length/1048576);
                }];
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *url, NSError *error) {
                    [self getFileNameAndTypeFromURL:url];
                }];
            }
			
			//audio
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeAudio]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeAudio options:nil completionHandler:^(NSData *item, NSError *error) {
					self.audio = item;
					self.type = audio;
					NSString *tempPath = [NSTemporaryDirectory() stringByAppendingString:@"tempAudio"];
					[[NSFileManager defaultManager] createFileAtPath:tempPath contents:item attributes:nil];
					
					//convert
					if (self.isContentValid) {
						[self showAlert:@"Processing audio. Large audio file will cause longer processing time." withButton:NO];
						TPAACAudioConverter *converter = [[TPAACAudioConverter alloc] init];
						[converter convertWithDelegate:self
												 Input:tempPath
												Output:[NSTemporaryDirectory() stringByAppendingString:@"output.mp3"]];
                        self.fileType = @"mp3";
						NSLog(@"Get audio: %ld bytes", item.length);
					}
					

				}];
                
                //file type and name
                [provider loadItemForTypeIdentifier:(NSString *)kUTTypeVideo options:nil completionHandler:^(NSURL *url, NSError *error) {
                    [self getFileNameAndTypeFromURL:url];
                }];
			}
			
			//file
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    if (_audio || _video || _text || _emotion || _url || _text) {
                        NSLog(@"More than one attachment found, skip assign type to file");
                    }else{
                        self.type = file;
                    }
                    
                    self.file = [NSData dataWithContentsOfURL:url];
                    
                    //file type and name
                    [self getFileNameAndTypeFromURL:url];
					
                    NSLog(@"Get file: %@", item);
				}];
			}
		}
	}
	
	[self validateContent];
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    // Perform the post operation.
    // When the operation is complete (probably asynchronously), the Share extension should notify the success or failure, as well as the items that were actually shared.
	
	NSLog(@"Sending message type: %ld", (long)self.type);
	
    //send msg
	//conversation
	WXMediaMessage *message = [WXMediaMessage message];
	message.title = self.messageTitle;
	message.description = [self.contentText stringByAppendingString:@"\n (WeChat Share)"];
	
	//get image
	if (!self.image) {
		self.image = [self getImageFromView:self.view];
	}
	//thumbnail
	if (self.image) {
		NSInteger thumbSize = 100;
		
		while (message.thumbData.length > 32*1024 || message.thumbData == nil) {
			UIImage *thumb = [self imageWithImage:self.image scaledToSize:CGSizeMake(thumbSize, thumbSize)];
			[message setThumbImage:thumb];
			thumbSize *= 0.9;
		}
	}
	
	//request
	SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
	req.bText = NO;
	req.message = message;
	req.text = self.contentText;
	
	//media
	if (self.type == video){
		WXFileObject *ext = [WXFileObject object];
		ext.fileExtension = self.fileType;
		ext.fileData = self.video;
        message.title = nil;
		message.mediaObject = ext;
		
	}else if (self.type == audio){
		WXFileObject *ext = [WXFileObject object];
		ext.fileExtension = self.fileType;
		ext.fileData = self.audio;
		//thumb
		if (!message.thumbData) {
			[message setThumbImage:[UIImage imageNamed:@"MusicNotes"]];
		}
        message.title = nil;
		message.mediaObject = ext;
	}else if (self.type == file){
		WXFileObject *file = [WXFileObject object];
		file.fileExtension = nil;
		file.fileData = self.file;
        message.title = self.fileName;
		message.mediaObject = file;
	}else if (self.type == emotion){
		//GIF
		WXEmoticonObject *emo = [WXEmoticonObject object];
		emo.emoticonData = [AnimatedGIFImageSerialization animatedGIFDataWithImage:self.image duration:self.image.duration loopCount:0 error:nil];
		message.mediaObject = emo;
	
	}else if(self.type == image){
		WXImageObject *ext = [WXImageObject object];
		UIImage *img = [self imageWithImage:self.image scaledToSize:CGSizeMake(2000, 2000)];
		ext.imageData = UIImageJPEGRepresentation(img, 0.7);
        message.title = self.fileName;
		message.mediaObject = ext;
		
	}else if (self.type == website) {
		WXWebpageObject *ext = [WXWebpageObject object];
		ext.webpageUrl = self.url.absoluteString;
        message.title = self.messageTitle;
		message.mediaObject = ext;
	}else if(self.type == text){
		req.message = nil;
		req.text = self.text;
		req.bText = YES;
	}
	else{
		//message.description = self.contentText;
		req.bText = YES;
	}
	
	
	
	
	if ([self.selected.value isEqualToString:@"Send to conversation"]) {
		req.scene = WXSceneSession;
	}
	else if ([self.selected.value isEqualToString:@"Post to moments"]) {
		req.scene = WXSceneTimeline;
	}
	else if ([self.selected.value isEqualToString:@"Add to favorite"]) {
		req.scene = WXSceneFavorite;
	}
	else{
		req.scene = WXSceneSession;
		NSLog(@"Unexpected selection");
	}
	
	
	if (![WXApi sendReq:req]){
		NSLog(@"Failed to send request");
	}else{
		NSInteger trails = [self.sharedDefaults integerForKey:trialLeft];
		[self.sharedDefaults setInteger:--trails forKey:trialLeft];
		[self.sharedDefaults synchronize];
	}
	
	
	
	//complete
	NSExtensionContext *context = self.extensionContext;
	NSArray *items = context.inputItems;
	NSExtensionItem *inputItem = items.firstObject;
	NSExtensionItem *outputItem = [inputItem copy];
	outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
	// Complete this implementation by setting the appropriate value on the output item.
	
	NSArray *outputItems = @[outputItem];
	// Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
	[self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
	
}


- (NSArray *)configurationItems{

	if (!self.selected) {
		self.selected = [SLComposeSheetConfigurationItem new];
		NSString *selection = selections[0];
		NSArray *array = [selection componentsSeparatedByString:@" - "];
		self.selected.title = array[0];
		self.selected.value = array[1];
		__block ShareViewController *blockSelf = self;
		self.selected.tapHandler = ^{
			[blockSelf pushConfigurationViewController:[blockSelf selectionViewController]];
		};
	}
    return @[_selected];
}


- (UIViewController *)selectionViewController{
	ConfigTableViewController *vc = [[ConfigTableViewController alloc] init];
	vc.OptionNames = selections;
	vc.delegate = self;
	return vc;
}

//Config View Delegate Method
-(void)didSelectOptionAtIndexPath:(NSIndexPath *)indexPath {
	NSString *selection = selections[indexPath.row];
	NSArray *array = [selection componentsSeparatedByString:@" - "];
	self.selected.title = array[0];
	self.selected.value = array[1];
	[self popConfigurationViewController];

}

#pragma mark - Helper
- (void)getFileNameAndTypeFromURL:(NSURL *)url{
    if (url) {
        
        NSArray *arr = [url.absoluteString componentsSeparatedByString:@"/"];
        arr = [arr.lastObject componentsSeparatedByString:@"."];
        self.placeholder = [arr.firstObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.fileName = self.placeholder;
        if (arr.count > 1) {
            self.fileType = arr.lastObject;
        }
    }
}



- (UIImage *)getImageFromView:(UIView *)view{
	
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            if (subView.frame.size.height > 50 && subView.frame.size.width > 50) {
                return [(UIImageView *)subView image];
            }
        }else if (subView.subviews){
            UIImage *image = [self getImageFromView:subView];
			if (image) {
				return image;
			}
        }
    }
    return nil;
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size
{
	if (!image) {
		return nil;
	}
	if (image.size.width < size.width && image.size.height < size.height) {
		return image;
	}
	CGFloat ratioW = size.width / image.size.width;
	CGFloat ratioH = size.height / image.size.height;
	CGFloat h;
	CGFloat	w;
	//aspect fit
	if (ratioH < ratioW) {
		//use h
		h = size.height;
		w = image.size.width * ratioH;
	}else{
		w = size.width;
		h = image.size.height * ratioW;
	}
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0);
	[image drawInRect:CGRectMake(0, 0, w, h)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}


#pragma mark - Helpter
- (void)showAlert:(NSString *)alert withButton:(BOOL)show{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (_alert) {
            if([_alert.message isEqualToString:alert]){
                //do nothing
                return;
            }else{
                [self dismissAlert];
            }
			
		}
		NSLog(@"Alert: %@", alert);
		_alert = [UIAlertController alertControllerWithTitle:@"Wechat Share" message:alert preferredStyle:UIAlertControllerStyleAlert];
		if (show) {
			UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
			[_alert addAction:action];
		}
        [self presentViewController:_alert animated:YES completion:^{
            if (!show) {
                //if not showing button, dismiss it after 60s
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (_alert) {
                        [self dismissAlert];
                        [self showAlert:@"Error occurred" withButton:YES];
                    }
                });
            }
        }];
	});
}

- (void)dismissAlert{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentedViewController) {
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	});
	
}

#pragma mark - Converter delegate
- (void)AACAudioConverterDidFinishConversion:(TPAACAudioConverter *)converter{
	NSData *mp3 = [NSData dataWithContentsOfFile:converter.destination];
	self.audio = mp3;
	[self dismissAlert];
	NSLog(@"processing succeed");
}

- (void)AACAudioConverter:(TPAACAudioConverter *)converter didMakeProgress:(CGFloat)progress{
	NSLog(@"processing %.1f%%", progress);
}

- (void)AACAudioConverter:(TPAACAudioConverter *)converter didFailWithError:(NSError *)error{
	[self dismissAlert];
	[self showAlert:[NSString stringWithFormat:@"Processing audio failed with error:%@", error] withButton:YES];
}


@end
