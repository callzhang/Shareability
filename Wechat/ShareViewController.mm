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
#import "JGProgressHUD.h"
// standard includes
#include <AudioToolbox/AudioToolbox.h>

// helpers
#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include <pthread.h>


@interface ShareViewController ()
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *content;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *text;
@property (nonatomic) NSData *video;
@property (nonatomic) NSData *audio;
@property (nonatomic) NSData *file;
@property (nonatomic) SLComposeSheetConfigurationItem *selected;
@end

@implementation ShareViewController

- (BOOL)isContentValid {
	BOOL charValid = YES;
	BOOL sizeValid = YES;
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
		sizeValid = NO;
	}
	if (self.text){
		if (self.text.length / 1024 > 10) {
			sizeValid = NO;
		}
	}
	
	if (!sizeValid) {
		NSLog(@"Too large");
//		JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
//		hud.textLabel.text = @"Too large";
//		[hud showInView:self.view];
//		[hud dismissAfterDelay:3.0];
//		[self.view setNeedsDisplay];
	
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Not valid" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			//
		}];
		[alert addAction:action];
		[self presentViewController:alert animated:YES completion:nil];
	}
	
	
	
    BOOL valid = sizeValid && charValid;
	if (!valid) {
		NSLog(@"Not valid");
		
	}
	return valid;
}

- (void)presentationAnimationDidFinish{
	
	//get the context title first, as it will be changed by user
	self.title = self.contentText;
	
	for (NSExtensionItem *item in self.extensionContext.inputItems) {
		NSLog(@"checking for input item: %@", item);
		for (NSItemProvider *provider in item.attachments) {
			NSLog(@"checking for ItemProvidor: %@", provider);
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList
											options:nil
								  completionHandler:^(NSDictionary *item, NSError *error){
					 NSLog(@"get property list from the host app: %@", item);
				 }];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeURL]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *item, NSError *error) {
					self.url = item;
					NSLog(@"Get url: %@", item);
				}];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeImage]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *item, NSError *error) {
					self.image = item;
					if (item.duration > 0) {
						NSLog(@"Get GIF");
					}
					NSLog(@"Get image");
				}];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeText]) {
				[provider loadItemForTypeIdentifier:( NSString *)kUTTypeText options:nil completionHandler:^(NSString *item, NSError *error) {
					self.text = item;
					NSLog(@"Get text: %@", item);
				}];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeVideo]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeVideo options:nil completionHandler:^(NSData *item, NSError *error) {
					self.video = item;
					NSLog(@"Get video: %luMB", item.length/1048576);
				}];
			}else if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSData *item, NSError *error) {
					self.video = item;
					[self validateContent];
					NSLog(@"Get movie: %luMB", item.length/1048576);
					
					if (self.video.length/1048576 > 10) {
						JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
						hud.textLabel.text = @"Transcoding";
                        [hud showInView:self.view];
						//resize
						NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"videoTempFile.mov"];
						NSParameterAssert([item writeToFile:path atomically:NO]);
						AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
						AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:urlAsset presetName:AVAssetExportPreset640x480];
						
						//output
						NSURL *outputURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"videoOutTempFile"]];
						NSFileManager *fileManager = [NSFileManager defaultManager];
						[fileManager removeItemAtURL:outputURL error:NULL];
						session.outputURL = outputURL;
						session.outputFileType = AVFileTypeQuickTimeMovie;
						[session exportAsynchronouslyWithCompletionHandler:^(void){
							
							 switch ([session status]) {
								 case AVAssetExportSessionStatusFailed:
									 NSLog(@"Failed with error: %@", session.error.description);
									 hud.indicatorView = nil;
									 hud.textLabel.text = @"Failed";
									 [hud dismissAfterDelay:3];
									 break;
								 case AVAssetExportSessionStatusCancelled:
									 NSLog(@"User cancelled");
									 break;
								 default:{
									 NSData *data = [NSData dataWithContentsOfURL:outputURL];
									 if (data.length/1048576 > 10) {
										 NSLog(@"Too large");
										 //too large
										 hud.indicatorView = nil;
										 hud.textLabel.text = @"Too large!";
										 [hud dismissAfterDelay:3];
									 }else{
										 NSLog(@"Finished");
										 hud.indicatorView = nil;
										 hud.textLabel.text = @"Finished";
										 [hud dismissAfterDelay:1.5];
									 }
									 self.video = data;
								 }
									 break;
							 }
							
							//delete file
							NSFileManager *fileManager = [NSFileManager defaultManager];
							[fileManager removeItemAtPath:path error:NULL];
							[fileManager removeItemAtURL:outputURL error:NULL];
							
							//validate
							[self validateContent];
						 }];
					}
				}];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeAudio]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeAudio options:nil completionHandler:^(NSData *item, NSError *error) {
					if (self.url) {
						NSArray *arr = [self.url.absoluteString componentsSeparatedByString:@"."];
						self.textView.text = arr[arr.count - 2];
						NSLog(@"Audio type is: %@", arr.lastObject);
						NSLog(@"Start convert");
						NSString *destinationFilePath = [NSTemporaryDirectory() stringByAppendingString:@"/audio.wav"];
						CFURLRef destinationURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)destinationFilePath, kCFURLPOSIXPathStyle, false);
						OSStatus error = DoConvertFile(self.url, destinationURL, kAudioFormatLinearPCM, 0);
						if (error) {
							printf("DoConvertFile failed! %d\n", (int)error);
						} else {
							self.url = [NSURL URLWithString:destinationFilePath];
							self.audio = [NSData dataWithContentsOfFile:destinationFilePath];
						}
						// delete output file if it exists
						if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilePath]) {
							[[NSFileManager defaultManager] removeItemAtPath:destinationFilePath error:nil];
						}
					}
					self.audio = item;
					NSLog(@"Get audio: %ld bytes", item.length);

				}];
			}
			
			if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeFileURL]) {
				[provider loadItemForTypeIdentifier:(NSString *)kUTTypeFileURL options:nil completionHandler:^(NSURL *item, NSError *error) {
					self.file = [NSData dataWithContentsOfURL:item];
					NSLog(@"Get file: %@", item);
				}];
			}
			
			
		}
	}
	
	[self validateContent];
	
	// Register your app
	[WXApi registerApp:@"wx166b37c35f3f6d9a" withDescription:@"Shareability"];
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    // Perform the post operation.
    // When the operation is complete (probably asynchronously), the Share extension should notify the success or failure, as well as the items that were actually shared.
    NSExtensionContext *context = self.extensionContext;
    NSArray *items = context.inputItems;
    NSExtensionItem *inputItem = items.firstObject;
    //NSItemProvider *itemProvider = inputItem.attachments.firstObject;

	//get image
    if (!self.image) {
        self.image = [self getImageFromSubviews:self.view];
    }
	
	
    //send msg
	//conversation
	WXMediaMessage *message = [WXMediaMessage message];
	message.title = self.title;
	message.description = [self.contentText stringByAppendingString:@"\n(from Shareability)"];
	
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
	if (self.video){
		WXFileObject *ext = [WXFileObject object];
		ext.fileExtension = @"mov";
		ext.fileData = self.video;
		message.mediaObject = ext;
		
	}else if (self.audio){
		WXFileObject *ext = [WXFileObject object];
		if (self.url) {
			NSArray *arr = [self.url.absoluteString componentsSeparatedByString:@"."];
			ext.fileExtension = arr.lastObject;
			NSLog(@"Audio type is: %@", ext.fileExtension);
		}else{
			ext.fileExtension = @"m4a";
		}
		
		//thumb
		if (!self.image) {
			[message setThumbImage:[UIImage imageNamed:@"MusicNotes.png"]];
		}
		ext.fileData = self.audio;
		message.mediaObject = ext;
	}else if (self.file){
		WXFileObject *file = [WXFileObject object];
		file.fileExtension = nil;
		file.fileData = self.file;
		message.mediaObject = file;
	}else if (self.image){
		if (self.image.duration > 0) {
			//GIF
			WXEmoticonObject *emo = [WXEmoticonObject object];
			emo.emoticonData = [AnimatedGIFImageSerialization animatedGIFDataWithImage:self.image duration:self.image.duration loopCount:0 error:nil];
			message.mediaObject = emo;
		}else{
			WXImageObject *ext = [WXImageObject object];
			UIImage *img = [self imageWithImage:self.image scaledToSize:CGSizeMake(2000, 2000)];
			ext.imageData = UIImageJPEGRepresentation(img, 0.7);
			message.mediaObject = ext;
		}
		
	}else if (self.url) {
		WXWebpageObject *ext = [WXWebpageObject object];
		ext.webpageUrl = self.url.absoluteString;
		message.mediaObject = ext;
	}else if(self.text){
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
	}
	
        
	//complete
	NSExtensionItem *outputItem = [inputItem copy];
	outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
	// Complete this implementation by setting the appropriate value on the output item.
	
	NSArray *outputItems = @[outputItem];
	// Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
	[self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
	
}

- (UIImage *)getImageFromSubviews:(UIView *)view{
    UIImage *img;
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            if (subView.frame.size.height > 10 && subView.frame.size.width > 10) {
                img = [(UIImageView *)subView image];
            }
        }else if (subView.subviews){
            img = [self getImageFromSubviews:subView];
        }
        if (img) {
            return img;
        }
    }
    return nil;
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

@end
