//
//  UnlockViewController.m
//  Wechat Share
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "UnlockViewController.h"
NSString *const unlockID = @"com.leizh.wechatshare.unlock";

@interface UnlockViewController()

@end

@implementation UnlockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([[NSUserDefaults standardUserDefaults] objectForKey:unlockID]) {
        [self transactionDidFinishWithSuccess:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)productIdentifiers{
    NSArray *SKUs = @[unlockID];
    return SKUs;
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    // Implement the result of a successful IAP
    // on the according productIdentifier.
    // YOUR CODE GOES HERE
    if ([productIdentifier isEqualToString:unlockID]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:unlockID];
    }
    
    // Save user data to disk.
    // YOUR CODE GOES HERE
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)transactionDidFinishWithSuccess:(BOOL)success{
    if (success) {
        self.detail.text = @"Thank you for your purchase!";
        self.buy.hidden = YES;
        self.restore.hidden = YES;
    }else{
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Transaction failed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}



- (IBAction)buy:(id)sender {
}

- (IBAction)restore:(id)sender {
}

- (IBAction)close:(id)sender {
	self.presentingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}
@end
