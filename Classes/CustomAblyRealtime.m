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
    artoptions.key = @"T6z9Ew.9a7FmQ:NYh49uPgi78dbMYH";
    artoptions.logLevel = ARTLogLevelError;
    artoptions.echoMessages = NO;
    artoptions.clientId = self.clientId;
    self.ably = [[ARTRealtime alloc] initWithOptions:artoptions];
    [self.ably.connection on:^(ARTConnectionStateChange * _Nullable status) {
        [self onConnectionStateChanged:status];
    }];
    [self.ably.push activate];
}

- (ARTRealtime*)getAblyRealtime {
    return self.ably;
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

- (void)logout {
    if (self.ably == nil) {
        return;
    }

    [self.ably.push deactivate];
    [self.ably close];
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

- (void)subscribeToPushNotifications {
    NSString * channelname = [SettingsKeys getBusinessId];
    if (channelname && [channelname length] > 0) {
        [[self.ably.channels get:[@"bpbc:" stringByAppendingString:channelname]].push subscribeDevice:^(ARTErrorInfo *_Nullable error)
         {
             if (error) {
                 NSLog(@"Public channel subscribe error");
             }
         }];
        [[self.ably.channels get:[@"bpvt:" stringByAppendingString:channelname]].push subscribeDevice:^(ARTErrorInfo *_Nullable error)
         {
             if (error) {
                 NSLog(@"Private channel subscribe error");
             }
         }];
    }
}

- (void)unsubscribeToPushNotification {

}

-(void)reattach:(ARTRealtimeChannel *)channel {
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

    [[channel presence] subscribe:^(ARTPresenceMessage * _Nonnull message) {
        [self onPresenceMessage:message];
    }];

    [channel on:^(ARTErrorInfo * _Nullable error) {
        [self onChannelStateChanged:channel.state error:error];
    }];
}

- (NSArray<NSString*>*)getChannels {
    NSString * channelname = [SettingsKeys getBusinessId];
    return @[
             [@"bpbc:" stringByAppendingString:channelname],
             [@"bpvt:" stringByAppendingString:channelname]
             ];
}

#pragma mark - ARTConnection Methods -

-(void)onConnectionStateChanged:(ARTConnectionStateChange *) status {
    if (status == nil) {
        return;
    }

    switch (status.current) {
        case ARTRealtimeInitialized:
        break;
        case ARTRealtimeConnecting:
        break;
        case ARTRealtimeConnected:
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
        break;
        case ARTRealtimeSuspended:
        break;
        case ARTRealtimeClosing:
        for (ARTRealtimeChannel * channel in self.ably.channels) {
            [channel unsubscribe];
            [[channel presence] unsubscribe];
        }
        break;
        case ARTRealtimeClosed:
        break;
        case ARTRealtimeFailed:
        DDLogError(@"onConnectionStateChgd: Failed --> %@", status);
        break;
    }
}

-(void)onPresenceMessage:(ARTPresenceMessage *)messages {
    if (messages == nil) {
        DDLogError(@"onPresenceMessage messages nil");
        return;
    }

    if (messages.data) {
        NSDictionary *data = (NSDictionary*)messages.data;
        NSString *from = [data valueForKey:@"from"];
        bool isTyping = [[data valueForKey:@"isTyping"] boolValue];
        if (from) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(fromUser:userIsTyping:)]) {
                [self.delegate fromUser:from userIsTyping:isTyping];
            }
        }
    }
}

- (void)onChannelStateChanged:(ARTRealtimeChannelState)state error:(ARTErrorInfo *)reason {
    if (reason != nil) {
        DDLogError(@"onChannelStateChanged --> %@", reason.message);
    }
}

#pragma mark - ARTPushRegistererDelegate Methods -

-(void)didActivateAblyPush:(nullable ARTErrorInfo *)error {
    if (error) {
        DDLogError(@"didActivateAblyPush: --> %@", error);
    } else {
        DDLogError(@"didActivateAblyPush succeded");

        [self subscribeToPushNotifications];
    }
}

-(void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error {
    if (error) {
        DDLogError(@"didDeactivateAblyPush: --> %@", error);
    } else {
        DDLogError(@"didDeactivateAblyPush succeded");
    }
}

-(void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error {
    if (error) {
        DDLogError(@"didAblyPushRegistrationFail: --> %@", error);
    } else {
        DDLogError(@"didAblyPushRegistrationFail");
    }
}


#pragma mark - Process message Method -

- (void)onMessage:(NSDictionary *)results {
    if ([results valueForKey:@"appAction"]) {
        int action = [[results valueForKey:@"appAction"] intValue];
        switch (action) {
            case 1: {
                NSString *connectionId = [results valueForKey:@"connectionId"];
                NSString *selfConnectionId = self.getPublicConnectionId;

                if (connectionId!= nil && selfConnectionId!= nil && [connectionId isEqualToString:selfConnectionId]) {
                    return;
                }

                NSString *messageId = [results valueForKey:@"messageId"];
                NSString *contactId = [results valueForKey:@"contactId"];
                NSInteger messageType = [[results valueForKey:@"messageType"] integerValue];

                if (messageId == nil || contactId == nil) {
                    return;
                }

                NSString *customerId = [results valueForKey:@"customerId"];

                YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
                __block YapContact *buddy = nil;

                [connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                    buddy = [YapContact fetchObjectWithUniqueID:(customerId)?customerId:contactId transaction:transaction];
                }];

                if (buddy == nil) {
                    [Customer queryForCustomer:(customerId)?customerId:contactId
                                         block:^(Customer * _Nullable customer, NSError * _Nullable error) {
                        if (error) {
                            if ([ParseValidation validateError:error]) {
                                [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                            }
                        } else {
                            [YapContact saveContactWithBusiness:customer block:^(YapContact *contact) {
                                [self messageId:messageId contactId:contactId messageType:messageType results:results connection:connection withContact:contact];
                            }];
                        }
                    }];
                } else {
                    [self messageId:messageId contactId:(customerId)?customerId:contactId messageType:messageType results:results connection:connection withContact:buddy];
                }
                break;
            }
            case 2: {
                NSString *from = [results valueForKey:@"from"];
                bool isTyping = [[results valueForKey:@"isTyping"] boolValue];
                if (from) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(fromUser:userIsTyping:)]) {
                        [self.delegate fromUser:from userIsTyping:isTyping];
                    }
                }
                break;
            }
        }
    }
}

- (void)messageId:(NSString*)messageId contactId:(NSString*)contactId messageType:(NSInteger)messageType results:(NSDictionary*)results connection:(YapDatabaseConnection*)connection withContact:(YapContact*)contact
{
    __block YapMessage *message = nil;

    // Check if message exists
    [connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        message = [YapMessage fetchObjectWithUniqueID:messageId transaction:transaction];
    }];

    if (message != nil) {
        return;
    }

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:5];

    // Save to Local Database
    [dictionary setObject:messageId forKey:@"messageId"];
    [dictionary setObject:[NSNumber numberWithInteger:messageType] forKey:@"messageType"];

    if ([[SettingsKeys getBusinessId] isEqualToString:contactId]) {
        [dictionary setObject:contact.uniqueId forKey:@"contactId"];
        message.delivered = statusAllDelivered;
        [dictionary setObject:@NO forKey:@"incoming"];
    } else {
        [dictionary setObject:contactId forKey:@"contactId"];
        message.delivered = statusReceived;
        [dictionary setObject:@YES forKey:@"incoming"];
    }

    switch (messageType) {
        case kMessageTypeText: {
            [dictionary setObject:[results objectForKey:@"message"] forKey:@"text"];
            break;
        }
        case kMessageTypeLocation: {
            [dictionary setObject:[results objectForKey:@"latitude"] forKey:@"latitude"];
            [dictionary setObject:[results objectForKey:@"longitude"] forKey:@"longitude"];
            break;
        }
        case kMessageTypeVideo:
        case kMessageTypeAudio: {
            [dictionary setObject:[results objectForKey:@"size"] forKey:@"bytes"];
            [dictionary setObject:[results objectForKey:@"duration"] forKey:@"duration"];
            [dictionary setObject:[results objectForKey:@"file"] forKey:@"file"];
            break;
        }
        case kMessageTypeImage: {
            [dictionary setObject:[results objectForKey:@"size"] forKey:@"bytes"];
            [dictionary setObject:[results objectForKey:@"width"] forKey:@"width"];
            [dictionary setObject:[results objectForKey:@"height"] forKey:@"height"];
            [dictionary setObject:[results objectForKey:@"file"] forKey:@"file"];
            break;
        }
    }

    [YapMessage saveMessageWithDictionary:dictionary block:^(YapMessage *message) {
        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            contact.lastMessageDate = message.date;
            [contact saveWithTransaction:transaction];
        } completionBlock:^{
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                if(self.delegate && [self.delegate respondsToSelector:@selector(messageReceived:from:)])
                {
                    [self.delegate messageReceived:message from:contact];
                    return;
                }
            } else {
                // We are not active, so use a local notification instead
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertAction = @"Ver";
                localNotification.soundName = UILocalNotificationDefaultSoundName;
                localNotification.applicationIconBadgeNumber = localNotification.applicationIconBadgeNumber + 1;
                localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",contact.displayName,message.text];
                localNotification.userInfo = @{@"contact":contact.uniqueId};
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }];
    }];
}

#pragma mark - Class Methods -

- (void)sendTypingStateOnChannel:(NSString*)channelName isTyping:(BOOL)value {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (value) {
        [parameters setValue:[SettingsKeys getBusinessId] forKey:@"userId"];
        [parameters setValue:channelName forKey:@"channelName"];
        [parameters setValue:@(YES) forKey:@"isTyping"];
    } else {
        [parameters setValue:[SettingsKeys getBusinessId] forKey:@"userId"];
        [parameters setValue:channelName forKey:@"channelName"];
    }

    [PFCloud callFunctionInBackground:@"sendPresenceMessage"
                       withParameters:parameters
                                block:^(id  _Nullable object, NSError * _Nullable error)
    {
        if (error) {
            if ([ParseValidation validateError:error]) {
                //[ParseValidation _handleInvalidSessionTokenError:nil];
            }
        }
    }];

    //    ARTRealtimeChannel *channel = [self.ably.channels get:channelName];
    //    if (channel) {
    //        [channel.presence updateClient:self.clientId
    //                                  data:@{@"isTyping": @(value), @"from": [SettingsKeys getBusinessId]}
    //                              callback:^(ARTErrorInfo * _Nullable error)
    //        {
    //            if (error) {
    //                DDLogError(@"Error sending typing state: %@", error);
    //            }
    //        }];
    //    }
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
