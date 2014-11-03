//
//  UnlockViewController.m
//  Wechat Share
//
//  Created by Lei Zhang on 10/26/14.
//  Copyright (c) 2014 Black Frog. All rights reserved.
//

#import "UnlockViewController.h"
NSString *const unlockID = @"com.wokealarm.Shareability.unlock";
NSString *const sharedSecret = @"f99be586cac5465185100229aabdba71";

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

#pragma mark - contentDelegate
- (NSArray *)productIdentifiers{
    NSArray *SKUs = @[unlockID];
    return SKUs;
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    // Implement the result of a successful IAP
    // on the according productIdentifier.
    // YOUR CODE GOES HERE
    NSLog(@"Provide content for %@", productIdentifier);
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}






#pragma mark - UIDelegate
//optional
- (void)transactionDidFinishWithSuccess:(BOOL)success{
    if (success) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:unlockID]) {
            self.detail.text = @"Thank you for your purchase!";
            self.buy.hidden = YES;
            self.restore.hidden = YES;
            [self.view setNeedsDisplay];//???
        }
    }else{
        [[[UIAlertView alloc] initWithTitle:@"In App Purchase failed" message:@"The purchase failed due to an error. Please, try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)restoredTransactionsDidFinishWithSuccess:(BOOL)success{
    [self transactionDidFinishWithSuccess:success];
}


#pragma mark - UI

- (IBAction)buy:(id)sender {
    SKProduct *unlock = [[CargoManager sharedManager] productForIdentifier:unlockID];
    if (unlock) {
        [[CargoManager sharedManager] buyProduct:unlock];
    }else{
        //wait until the product ready
        [[CargoManager sharedManager] retryLoadingProducts];
        [[NSNotificationCenter defaultCenter] addObserverForName:CMProductRequestDidReceiveResponseNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            if (note.userInfo[@"error"]) {
                //something wrong, restate the UI
            }else{
                SKProduct *unlock = [[CargoManager sharedManager] productForIdentifier:unlockID];
                if (!unlock) {
                    return;
                }
                [[CargoManager sharedManager] buyProduct:unlock];
            }
            [[NSNotificationCenter defaultCenter] removeObserver:self name:CMProductRequestDidReceiveResponseNotification object:nil];
        }];
    }
}

- (IBAction)restore:(id)sender {
    [[CargoManager sharedManager] restorePurchasedProducts];
}

- (IBAction)close:(id)sender {
	self.presentingViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
