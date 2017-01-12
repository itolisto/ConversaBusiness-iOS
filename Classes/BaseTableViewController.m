//
//  BaseTableViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/19/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "BaseTableViewController.h"

#import "Reachability.h"
#import <AudioToolbox/AudioToolbox.h>

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

- (void)messageReceived:(YapMessage *)message from:(YapContact *)from {
    YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
    [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
     {
         [message saveWithTransaction:transaction];
         from.lastMessageDate = message.date;
         [from saveWithTransaction:transaction];
     } completionBlock:^{
         if ([SettingsKeys getNotificationPreviewInApp:YES]) {
             NSString *text = nil;

             switch (message.messageType) {
                 case kMessageTypeText: {
                     text = message.text;
                     break;
                 }
                 case kMessageTypeLocation: {
                     text = NSLocalizedString(@"chats_cell_conversation_location", nil);
                     break;
                 }
                 case kMessageTypeVideo: {
                     text = NSLocalizedString(@"chats_cell_conversation_video", nil);
                     break;
                 }
                 case kMessageTypeAudio: {
                     text = NSLocalizedString(@"chats_cell_conversation_audio", nil);
                     break;
                 }
                 case kMessageTypeImage: {
                     text = NSLocalizedString(@"chats_cell_conversation_image", nil);
                     break;
                 }
                 default: {
                     text = NSLocalizedString(@"chats_cell_conversation_message", nil);
                     break;
                 }
             }

             if ([SettingsKeys getNotificationSoundInApp:YES]) {
                 NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound_notification_manager" ofType:@"mp3"];
                 CFURLRef cfString = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:soundPath]);
                 SystemSoundID soundID;
                 AudioServicesCreateSystemSoundID(cfString, &soundID);
                 AudioServicesPlaySystemSound (soundID);
                 CFRelease(cfString);
             }

             [WhisperBridge shout:from.displayName
                         subtitle:text
                  backgroundColor:[UIColor clearColor]
           toNavigationController:self.navigationController
                            image:nil
                     silenceAfter:1.8
                           action:nil];
         }
     }];
}

#pragma mark - Controller Methods -

- (UIViewController *)topViewController {
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

@end
