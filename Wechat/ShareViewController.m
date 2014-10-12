//
//  ShareViewController.m
//  Wechat
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    NSInteger messageLength = [[self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
    NSInteger charactersRemaining = 50 - messageLength;
    self.charactersRemaining = @(charactersRemaining);
    
    if (charactersRemaining >= 0 && charactersRemaining != 0) {
        return YES;
    }
    
    return NO;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    // Perform the post operation.
    // When the operation is complete (probably asynchronously), the Share extension should notify the success or failure, as well as the items that were actually shared.
    
    NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
    
    NSExtensionItem *outputItem = [inputItem copy];
    outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
    // Complete this implementation by setting the appropriate value on the output item.
    
    NSArray *outputItems = @[outputItem];
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
}


- (NSArray *)configurationItems{
    SLComposeSheetConfigurationItem *conversation = [[SLComposeSheetConfigurationItem alloc] init];
    conversation.title = @"Conversation";
    SLComposeSheetConfigurationItem *moments = [SLComposeSheetConfigurationItem new];
    moments.title = @"Moments";
    return @[conversation, moments];
}

@end
