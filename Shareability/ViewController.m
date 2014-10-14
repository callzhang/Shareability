//
//  ViewController.m
//  Shareability
//
//  Created by Lei Zhang on 10/11/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "ViewController.h"
#import "WXApi.h"
#import "WXApiObject.h"
#import "SendMsgToWechatMgr.h"

@interface ViewController ()
@property (nonatomic) SendMsgToWechatMgr *WXManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
//    WXMediaMessage *message = [WXMediaMessage message];
//    message.title = @"Acer Aspire P3 review: a nice enough tablet, but wait for the refresh";
//    message.description = @"Back when Windows 8 first launched, the Acer Iconia W700 quickly became one of our favorite laptop / tablet hybrids. There were two reasons for that, really: the price was right, and the battery lasted longer than pretty much any other Win 8 device we'd tested. ";
//    [message setThumbImage:[UIImage imageNamed:@"Engadget.png"]];
//    
//    WXWebpageObject *ext = [WXWebpageObject object];
//    ext.webpageUrl = @"http://www.engadget.com/2013/06/22/acer-aspire-p3-review/";
//    
//    message.mediaObject = ext;
//    
//    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
//    req.bText = NO;
//    req.message = message;
//    req.scene = WXSceneSession;
//    
//    [WXApi sendReq:req];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
