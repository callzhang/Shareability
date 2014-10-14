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

@interface ShareViewController ()
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *content;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *text;
@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    NSInteger messageLength = [[self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
    NSInteger charactersRemaining = 100 - messageLength;
    self.charactersRemaining = @(charactersRemaining);
    
    if (charactersRemaining >= 0 && charactersRemaining != 0) {
        return YES;
    }
    
    return NO;
}

- (void)presentationAnimationDidFinish{
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    for (NSItemProvider *provider in item.attachments) {
//        [provider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList
//                                    options:nil
//                          completionHandler:^(id<NSSecureCoding> item, NSError *error)
//        {
//            //
//        }];
        if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeURL]) {
            [provider loadItemForTypeIdentifier:( NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *item, NSError *error) {
                self.url = item;
            }];
        }
        
        if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeImage]) {
            [provider loadItemForTypeIdentifier:( NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *item, NSError *error) {
                self.image = item;
            }];
        }
        
        if ([provider hasItemConformingToTypeIdentifier:( NSString *)kUTTypeText]) {
            [provider loadItemForTypeIdentifier:( NSString *)kUTTypeText options:nil completionHandler:^(NSString *item, NSError *error) {
                self.text = item;
            }];
        }
        
        [self validateContent];
    }
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // Register your app
        [WXApi registerApp:@"wx166b37c35f3f6d9a" withDescription:@"Shareability"];
    });
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    // Perform the post operation.
    // When the operation is complete (probably asynchronously), the Share extension should notify the success or failure, as well as the items that were actually shared.
    NSExtensionContext *context = self.extensionContext;
    NSArray *items = context.inputItems;
    NSExtensionItem *inputItem = items.firstObject;
    NSItemProvider *itemProvider = inputItem.attachments.firstObject;
    [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil
                          completionHandler:^(NSDictionary *item, NSError *error)
    {
        NSLog(@"List of properties: %@", item);
    }];
    
    
    if (!self.image) {
        self.image = [self getImageFromSubviews:self.view];
    }
    //send msg
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = self.contentText;
    message.description = self.text;
    [message setThumbImage:self.image];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = self.url.absoluteString;
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;
    
    [WXApi sendReq:req];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //complete
        NSExtensionItem *outputItem = [inputItem copy];
        outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
        // Complete this implementation by setting the appropriate value on the output item.
        
        NSArray *outputItems = @[outputItem];
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
    });
    
}

- (UIImage *)getImageFromSubviews:(UIView *)view{
    UIImage *img;
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            img = [(UIImageView *)subView image];
            
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
    SLComposeSheetConfigurationItem *types = [[SLComposeSheetConfigurationItem alloc] init];
    types.title = @"Types";
    return @[types];
}



@end
