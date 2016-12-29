//
//  BaseTableViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/19/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "BaseTableViewController.h"

#import "Reachability.h"

@interface BaseTableViewController ()

@end

@implementation BaseTableViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [CustomAblyRealtime sharedInstance].delegate = self;

    if (self.navigationController != nil) {
        Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
        if (networkStatus == NotReachable) {
            [WhisperBridge showPermanentShout:NSLocalizedString(@"no_internet_connection_message", nil)
                                   titleColor:[UIColor whiteColor]
                              backgroundColor:[UIColor redColor]
                       toNavigationController:self.navigationController];
        } else {
            [WhisperBridge hidePermanentShout:self.navigationController];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ConversationListener Methods -

- (void)messageReceived:(YapMessage *)message from:(YapContact *)from text:(NSString *)text {
    [WhisperBridge shout:from.displayName
                subtitle:text
         backgroundColor:[UIColor clearColor]
  toNavigationController:self.navigationController
                   image:nil
            silenceAfter:1.8
                  action:nil];
}

#pragma mark - Controller Methods -

- (UIViewController *)topViewController {
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

@end
