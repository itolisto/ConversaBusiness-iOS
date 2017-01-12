//
//  CustomAblyRealtime.m
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CustomAblyRealtime.h"

#import "Log.h"
#import "AppJobs.h"
#import "Business.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "SettingsKeys.h"
#import "DatabaseManager.h"
#import "ParseValidation.h"
#import <Parse/Parse.h>
#import <CommonCrypto/CommonDigest.h>

@interface CustomAblyRealtime ()

@property(nonatomic, assign)BOOL firstLoad;

@end

@implementation CustomAblyRealtime

+ (CustomAblyRealtime *)sharedInstance {
    __strong static CustomAblyRealtime *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CustomAblyRealtime alloc] init];
    });
    return sharedInstance;
}

// http://stackoverflow.com/a/23608321/5349296
- (NSString*)sha1:(NSString *)input
{
    const char *s=[input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData=[NSData dataWithBytes:s length:strlen(s)];

    uint8_t digest[CC_SHA1_DIGEST_LENGTH]={0};
    CC_SHA1(keyData.bytes, (CC_LONG)keyData.length, digest);
    NSData *out = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    NSString *hash = [out description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"-" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
    return hash;
}

#pragma mark - Connection Methods -

- (instancetype)init
{
    if (self = [super init]) {
        self.firstLoad = NO;
        self.clientId = [self sha1:[[NSUUID UUID] UUIDString]];
    }

    return self;
}

- (void)initAbly {
    ARTClientOptions *artoptions = [[ARTClientOptions alloc] init];
    artoptions.key = @"zmxQkA.HfI9Xg:0UC2UioXcnDarSak";
    artoptions.logLevel = ARTLogLevelError;
    artoptions.echoMessages = NO;
//    artoptions.clientId = self.clientId;
//    artoptions.defaultTokenParams.capability = @"{\"bpbc:*\":[\"presence\",\"subscribe\"],\"bpvt:*\":[\"presence\",\"subscribe\"],\"upbc:*\":[\"presence\",\"subscribe\"]}";
    self.ably = [[ARTRealtime alloc] initWithOptions:artoptions];
    [self.ably.connection on:^(ARTConnectionStateChange * _Nullable status) {
        [self onConnectionStateChanged:status];
    }];
}

- (void)subscribeToChannels {
    NSString * channelname = [SettingsKeys getBusinessId];
    if ([channelname length] > 0) {
        for (int i = 0; i < 2; i++) {
            ARTRealtimeChannel * channel;
            NSString * channelname;

            if (i == 0) {
                channelname = [@"bpbc:" stringByAppendingString:[SettingsKeys getBusinessId]];
                channel = [[self.ably channels] get:channelname];
            } else {
                channelname = [@"bpvt:" stringByAppendingString:[SettingsKeys getBusinessId]];
                channel = [[self.ably channels] get:channelname];
            }

            [self reattach:channel];
        }
    }
}

- (void)reattach:(ARTRealtimeChannel *)channel {
    if (channel == nil) {
        DDLogError(@"reattach ARTRealtimeChannel channel nil");
        return;
    }

    [channel subscribe:^(ARTMessage * _Nonnull message) {
        NSError *error;
        id object = [NSJSONSerialization JSONObjectWithData:[message.data dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0
                                                      error:&error];
        if (error) {
            DDLogError(@"onMessage ARTMessage error: %@", error);
        } else {
            if ([object isKindOfClass:[NSDictionary class]]) {
                [self onMessage:object];
            }
        }
    }];

    [[channel getPresence] subscribe:^(ARTPresenceMessage * _Nonnull message) {
        [self onPresenceMessage:message];
    }];

    [channel on:^(ARTErrorInfo * _Nullable error) {
        [self onChannelStateChanged:channel.state error:error];
    }];
}

- (void)logout {
    if (self.ably == nil) {
        return;
    }

    [self.ably close];
}

- (void)onConnectionStateChanged:(ARTConnectionStateChange *) status {
    if (status == nil) {
        return;
    }

    switch (status.current) {
        case ARTRealtimeInitialized:
            DDLogError(@"onConnectionStateChgd: Initialized");
            break;
        case ARTRealtimeConnecting:
            DDLogError(@"onConnectionStateChgd: Connecting");
            break;
        case ARTRealtimeConnected:
            DDLogError(@"onConnectionStateChgd: Connected");
            if (self.firstLoad) {
                // Subscribe to all Channels
                [self subscribeToChannels];
                // Change first load
                self.firstLoad = NO;
            } else {
                NSString * channelname = [@"bpbc:" stringByAppendingString:[SettingsKeys getBusinessId]];
                if (![self.ably.channels exists:channelname]) {
                    [self subscribeToChannels];
                } else {
                    for (ARTRealtimeChannel * channel in self.ably.channels) {
                        [self reattach:channel];
                    }
                }
            }
            break;
        case ARTRealtimeDisconnected:
            DDLogError(@"onConnectionStateChgd: Disconnected");
            break;
        case ARTRealtimeSuspended:
            DDLogError(@"onConnectionStateChgd: Suspended");
            break;
        case ARTRealtimeClosing:
            DDLogError(@"onConnectionStateChgd: Closing");
            for (ARTRealtimeChannel * channel in self.ably.channels) {
                [channel unsubscribe];
                [[channel getPresence] unsubscribe];
            }
            break;
        case ARTRealtimeClosed:
            DDLogError(@"onConnectionStateChgd: Closed");
            break;
        case ARTRealtimeFailed:
            DDLogError(@"onConnectionStateChgd: Failed --> %@", status);
            break;
    }
}

- (void)onMessage:(NSDictionary *)results {
    //DDLogError(@"onMessage: message received --> %@", [results allKeys]);
    if ([results valueForKey:@"appAction"]) {
        int action = [[results valueForKey:@"appAction"] intValue];
        switch (action) {
            case 1: {
                NSString *messageId = [results valueForKey:@"messageId"];
                NSString *contactId = [results valueForKey:@"contactId"];
                NSInteger messageType = [[results valueForKey:@"messageType"] integerValue];

                if (messageId == nil || contactId == nil) {
                    return;
                }

                YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
                __block YapContact *buddy = nil;

                [connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                    buddy = [YapContact fetchObjectWithUniqueID:contactId transaction:transaction];
                }];

                if (buddy == nil) {
                    PFQuery *query = [Customer query];
                    [query whereKey:kCustomerActiveKey equalTo:@(YES)];
                    [query selectKeys:@[kCustomerDisplayNameKey]];

                    [query getObjectInBackgroundWithId:contactId block:^(PFObject * _Nullable object, NSError * _Nullable error)
                     {
                         if (error) {
                             if ([ParseValidation validateError:error]) {
                                 [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                             }
                         } else {
                             Customer *business = (Customer*)object;

                             YapContact *newBuddy = [[YapContact alloc] initWithUniqueId:contactId];
                             newBuddy.accountUniqueId = [Account currentUser].objectId;
                             newBuddy.displayName = business.displayName;
                             newBuddy.composingMessageString = @"";
                             newBuddy.blocked = NO;
                             newBuddy.mute = NO;
                             newBuddy.lastMessageDate = [NSDate date];

                             [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                                 [newBuddy saveWithTransaction:transaction];
                             } completionBlock:^{
                                 [self messageId:messageId contactId:contactId messageType:messageType results:results connection:connection withContact:newBuddy];
                             }];
                         }
                     }];
                } else {
                    [self messageId:messageId contactId:contactId messageType:messageType results:results connection:connection withContact:buddy];
                }
                break;
            }
        }
    }
}

- (void)onPresenceMessage:(ARTPresenceMessage *)messages {
    if (messages == nil) {
        DDLogError(@"onPresenceMessage messages nil");
        return;
    }

    switch (messages.action) {
        case ARTPresenceEnter:
            break;
        case ARTPresenceLeave:
            break;
        case ARTPresenceUpdate: {
            if (messages.data) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(fromUser:userIsTyping:)]) {
                    NSDictionary *data = (NSDictionary*)messages.data;
                    NSString *from = [data valueForKey:@"from"];
                    bool isTyping = [[data valueForKey:@"isTyping"] boolValue];
                    [self.delegate fromUser:from userIsTyping:isTyping];
                }
            }
            break;
        }
        default:
            break;
    }
}

- (void)onChannelStateChanged:(ARTRealtimeChannelState)state error:(ARTErrorInfo *)reason {
    if (reason != nil) {
        DDLogError(@"onChannelStateChanged --> %@", reason.message);
        return;
    }

    switch (state) {
        case ARTRealtimeChannelInitialized:
            break;
        case ARTRealtimeChannelAttaching:
            break;
        case ARTRealtimeChannelAttached:
            break;
        case ARTRealtimeChannelDetaching:
            break;
        case ARTRealtimeChannelDetached:
            break;
        case ARTRealtimeChannelFailed:
            break;
    }
}

- (ARTRealtimeConnectionState)ablyConnectionStatus {
    if (self.ably == nil) {
        return ARTRealtimeDisconnected;
    }

    return self.ably.connection.state;
}

- (NSString *)getPublicConnectionId {
    if (self.ably != nil) {
        return self.ably.connection.key;
    }

    return nil;
}

#pragma mark - Process message Method -

- (void)messageId:(NSString*)messageId contactId:(NSString*)contactId messageType:(NSInteger)messageType results:(NSDictionary*)results connection:(YapDatabaseConnection*)connection withContact:(YapContact*)contact {
    // 2. Save to Local Database
    YapMessage *message = [[YapMessage alloc] initWithId:messageId];
    message.delivered = statusReceived;
    message.buddyUniqueId = contactId;
    message.messageType = messageType;

    if ([[SettingsKeys getBusinessId] isEqualToString:contactId]) {
        message.incoming = NO;
    } else {
        message.incoming = YES;
    }

    switch (messageType) {
        case kMessageTypeText: {
            message.text = [results objectForKey:@"message"];
            break;
        }
        case kMessageTypeLocation: {
            CLLocation *location = [[CLLocation alloc]
                                    initWithLatitude:[[results objectForKey:@"latitude"] doubleValue]
                                    longitude:[[results objectForKey:@"longitude"] doubleValue]];
            message.location = location;
            break;
        }
        case kMessageTypeVideo:
        case kMessageTypeAudio: {
            message.delivered = statusDownloading;
            message.bytes = [[results objectForKey:@"size"] floatValue];
            message.duration = [NSNumber numberWithInteger:[[results objectForKey:@"duration"] integerValue]];
            message.remoteUrl = [results objectForKey:@"file"];
            [AppJobs addDownloadFileJob:message.uniqueId url:message.remoteUrl messageType:messageType];
            break;
        }
        case kMessageTypeImage: {
            message.delivered = statusDownloading;
            message.bytes = [[results objectForKey:@"size"] floatValue];
            message.width = [[results objectForKey:@"width"] floatValue];
            message.height = [[results objectForKey:@"height"] floatValue];
            message.remoteUrl = [results objectForKey:@"file"];
            [AppJobs addDownloadFileJob:message.uniqueId url:message.remoteUrl messageType:messageType];
            break;
        }
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(messageReceived:from:)]) {
        [self.delegate messageReceived:message from:contact];
    } else {
        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
         {
             [message saveWithTransaction:transaction];
             contact.lastMessageDate = message.date;
             [contact saveWithTransaction:transaction];
         }];
    }
}

#pragma mark - Class Methods -

- (void)sendTypingStateOnChannel:(NSString*)channelName isTyping:(BOOL)value {
    ARTRealtimeChannel *channel = [self.ably.channels get:channelName];
    if (channel) {
        [channel.presence updateClient:self.clientId
                                  data:@{@"isTyping": @(value), @"from": [SettingsKeys getBusinessId]}
                              callback:^(ARTErrorInfo * _Nullable error)
        {
            if (error) {
                DDLogError(@"Error sending typing state: %@", error);
            } else {
                DDLogError(@"typing success \n success \n success");
            }
         }];
    }
}

#pragma mark - Help Methods -

- (UIViewController *)topViewController {
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }

    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }

    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end
