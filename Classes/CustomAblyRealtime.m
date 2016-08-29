//
//  CustomAblyRealtime.m
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CustomAblyRealtime.h"

#import "Log.h"
#import "Account.h"
#import "Message.h"
#import "Business.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "DatabaseManager.h"
//#import <Parse/Parse.h>

@interface CustomAblyRealtime () //<SINServiceDelegate>

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

#pragma mark - Connection Methods -

- (instancetype)init
{
    if (self = [super init]) {
        self.firstLoad = NO;
    }
    
    return self;
}

- (void)initAbly:(NSDictionary *)launchOptions {
    ARTClientOptions *options = [[ARTClientOptions alloc] initWithKey:@"zmxQkA.0hjFJg:-DRtJj8oaEifjs-_"];
    options.logLevel = ARTLogLevelError;
    options.clientId = [[NSUUID UUID] UUIDString];
    options.autoConnect = YES;
    self.ably = [[ARTRealtime alloc] initWithOptions:options];
    [self.ably.connection on:^(ARTConnectionStateChange * _Nullable status) {
        [self onConnectionStateChanged:status];
    }];
}

- (void)subscribeToChannels {
    NSString * channelname = [[Account currentUser] objectId];
    if ([channelname length] > 0) {
        for (int i = 0; i < 2; i++) {
            ARTRealtimeChannel * channel;
            NSString * channelname;

            if (i == 0) {
                channelname = [@"upbc:" stringByAppendingString:[[Account currentUser] objectId]];
                channel = [[self.ably channels] get:channelname];
            } else {
                channelname = [@"upvt:" stringByAppendingString:[[Account currentUser] objectId]];
                channel = [[self.ably channels] get:channelname];
            }

            [self reattach:channel];
        }
    }
}

- (void)reattach:(ARTRealtimeChannel *) channel {
    [channel subscribe:^(ARTMessage * _Nonnull message) {
        [self onMessage:message];
    }];

    [[channel getPresence] subscribe:^(ARTPresenceMessage * _Nonnull message) {
        [self onPresenceMessage:message];
    }];

    [[channel getPresence] enter:@"" callback:^(ARTErrorInfo * _Nullable error) {

    }];

    [channel on:^(ARTErrorInfo * _Nullable error) {
        [self onChannelStateChanged:channel.state error:error];
    }];
}

- (void)logout {
    if (self.ably == nil) {
        return;
    }
    
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
                NSString * channelname = [@"upbc:" stringByAppendingString:[[Account currentUser] objectId]];
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
            DDLogError(@"onConnectionStateChgd: Failed");
            break;
    }
}

- (void)onMessage:(ARTMessage *) messages {
    DDLogError(@"onMessage: message received --> %@", messages.description);


//    try {
//        additionalData = new JSONObject(messages.data.toString());
//    } catch (JSONException e) {
//        Logger.error(TAG, "onMessageReceived additionalData fail to parse-> " + e.getMessage());
//        return;
//    }
//
//    Log.e("NotifOpenedHandler", "Full additionalData:\n" + additionalData.toString());
//
//    switch (additionalData.optInt("appAction", 0)) {
//        case 1:
//            Intent msgIntent = new Intent(context, CustomMessageService.class);
//            msgIntent.putExtra("data", additionalData.toString());
//            context.startService(msgIntent);
//            break;
//    }
}

- (void)onPresenceMessage:(ARTPresenceMessage *)messages {
    DDLogError(@"onPresenceMessage: message received --> %@", messages.clientId);

    switch (messages.action) {
        case ARTPresenceEnter:
            break;
        case ARTPresenceLeave:
            break;
        case ARTPresenceUpdate:
            break;
        default:
            break;
    }
}

- (void)onChannelStateChanged:(ARTRealtimeChannelState)state error:(ARTErrorInfo *) reason {
    if (reason != nil) {
        DDLogError(@"fasdf --> %@", reason.message);
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

//public PresenceMessage[] getPresentUsers(String channel) {
//    return ablyRealtime.channels.get(channel).presence.get();
//}

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

#pragma mark - SINServiceDelegate

//- (void)service:(id<SINService>)service didFailWithError:(NSError *)error {
//    NSLog(@"%@", [error localizedDescription]);
//}
//
//- (void)service:(id<SINService>)service
//     logMessage:(NSString *)message
//           area:(NSString *)area
//       severity:(SINLogSeverity)severity
//      timestamp:(NSDate *)timestamp {
//    if (severity == SINLogSeverityCritical) {
//        NSLog(@"%@", message);
//    }
//}

#pragma mark - Process message Method -

- (void)processMessage:(NSDictionary *)additionalData {
    NSString* customKey = additionalData[@"customKey"];
    if (customKey)
        NSLog(@"customKey: %@", customKey);
    
    if(self.delegate && [self.delegate conformsToProtocol:@protocol(ConversationListener)] && [self.delegate respondsToSelector:@selector(messageReceived:)]) {
        [self.delegate messageReceived:additionalData];
    } else {
        DDLogInfo(@"ConversationListener protocol isn't set to receive message");
        // Process message here
    }
}

#pragma mark - ConversationListener Methods -

//        if(self.delegate && [self.delegate conformsToProtocol:@protocol(ConversationListener)] && [self.delegate respondsToSelector:@selector(fromUser:didGoOnline:)]) {
//            NSString *from = event.data.presence.uuid;
//            [self.delegate fromUser:from didGoOnline:YES];
//        } else {
//            DDLogInfo(@"ConversationListener protocol isn't set to receive join event");
//            // Process message here
//        }


//        if (self.delegate && [self.delegate conformsToProtocol:@protocol(ConversationListener)] && [self.delegate respondsToSelector:@selector(fromUser:userIsTyping:)]) {
//            switch (value.integerValue) {
//                case 0: {
//                    [self.delegate fromUser:from userIsTyping:NO];
//                    break;
//                }
//                case 1: {
//                    [self.delegate fromUser:from userIsTyping:YES];
//                    break;
//                }
//                default:
//                    break;
//            }
//        } else {
//            DDLogError(@"ConversationListener protocol isn't set to receive typing event");
//        }

#pragma mark - Class Methods -

- (void)sendTypingStateOnChannel:(NSString*)channel isTyping:(BOOL)value {
//    [self.pubnub setState: @{@"eventType": [NSNumber numberWithBool:value]} forUUID:self.pubnub.uuid onChannel:channel withCompletion:nil];
}

- (void) unsubscribeToChannels: (NSArray*)channels {
//    [self.pubnub unsubscribeFromChannels:channels withPresence:NO];
}

- (void) unsubscribeFromAllChannels {
//    [self.pubnub unsubscribeFromAll];
}

- (void) subscribeToChannels: (NSArray*)channels {
//    [self.pubnub subscribeToChannels:channels withPresence:YES];
}

@end
