//
//  SendMsgToWechatMgr.m
//  SDKSample
//
//  Created by Tencent on 6/23/13.
//
//

#import "SendMsgToWechatMgr.h"
#import "JGProgressHUD.h"
#import "JGProgressHUDSuccessIndicatorView.h"
#import "JGProgressHUDErrorIndicatorView.h"

@implementation SendMsgToWechatMgr


-(void) onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        
		//NSString *strTitle = [NSString stringWithFormat:@"WeChat request app contenct"];
        NSString *strMsg = @"WeChat requests content from App, and the App reponses WeChat by calling sendResp:GetMessageFromWXResp";
		

		//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		//alert.tag = 1000;
		//[alert show];
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        ShowMessageFromWXReq* temp = (ShowMessageFromWXReq*)req;
        WXMediaMessage *msg = temp.message;
        
        WXAppExtendObject *obj = msg.mediaObject;
        
		//NSString *strTitle = [NSString stringWithFormat:@"Message from WeChat"];
        NSString *strMsg = [NSString stringWithFormat:@"Title: %@ \nContent:%@ \nDescription: %@ \nThumb: %lu bytes\n\n",msg.title, msg.description, obj.extInfo, (unsigned long)msg.thumbData.length];
		JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
		hud.textLabel.text = strMsg;
		hud.indicatorView = nil;
		[hud showInView:[UIApplication sharedApplication].delegate.window.rootViewController.view];
		[hud dismissAfterDelay:4];
		//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		//[alert show];
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        
		//NSString *strTitle = [NSString stringWithFormat:@"Launched by WeChat"];
        NSString *strMsg = @"This message is from the App when started in WeChat";

		//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
		//[alert show];
    }
}

-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
		//NSString *strTitle = resp.errCode ? @"Error" : @"Success";
        NSString *strError = @"There was an issue sharing your message. Please try again.";
        NSString *strSuccess = @"Your message was successfully shared!";
        
		//UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle
		//                                                message:resp.errCode ? strError : strSuccess
		//                                               delegate:self
		//                                      cancelButtonTitle:@"OK"
		//                                      otherButtonTitles:nil, nil];
		//[alert show];
		JGProgressHUD *hud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
		hud.indicatorView = resp.errCode ? [JGProgressHUDErrorIndicatorView new] : [JGProgressHUDSuccessIndicatorView new];
		hud.textLabel.text = resp.errCode ? strError : strSuccess;
		[hud showInView:[UIApplication sharedApplication].delegate.window.rootViewController.view];
		[hud dismissAfterDelay:4];
    }
}


@end
